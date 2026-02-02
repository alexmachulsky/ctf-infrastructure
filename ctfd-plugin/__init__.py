import json
import os
import subprocess
from flask import Blueprint, render_template, request, jsonify
from CTFd.plugins import register_plugin_assets_directory
from CTFd.utils.decorators import admins_only

# Plugin metadata
__plugin_name__ = "Environment Validator"
__version__ = "1.0.0"
__description__ = "Validates connectivity to CTF vulnerable instances"
__author__ = "CTF Infrastructure Team"


def load(app):
    """
    Called when the plugin is loaded. Registers the plugin blueprint.
    """
    plugin_blueprint = Blueprint(
        "env_validator",
        __name__,
        template_folder="templates",
        static_folder="assets",
        url_prefix="/env-validator"
    )

    # Register assets directory for serving static files
    register_plugin_assets_directory(
        app, base_path="/plugins/ctfd_environment_validator/assets/"
    )

    # Load infrastructure information from Terraform outputs
    infrastructure_file = "/opt/CTFd/CTFd/plugins/ctfd_environment_validator/infrastructure.json"
    infrastructure_info = {}
    
    if os.path.exists(infrastructure_file):
        try:
            with open(infrastructure_file, 'r') as f:
                infrastructure_info = json.load(f)
            app.logger.info(f"Loaded infrastructure info: {infrastructure_info}")
        except Exception as e:
            app.logger.error(f"Failed to load infrastructure.json: {e}")

    @plugin_blueprint.route("/admin", methods=["GET"])
    @admins_only
    def admin_page():
        """Admin page for the environment validator plugin"""
        return render_template(
            "env_validator_admin.html",
            infrastructure=infrastructure_info
        )

    @plugin_blueprint.route("/validate", methods=["POST"])
    @admins_only
    def validate_environment():
        """
        Validates connectivity to the vulnerable instance using ICMP ping
        """
        data = request.get_json()
        target_ip = data.get("target_ip")
        
        if not target_ip:
            # Try to get from infrastructure info
            if infrastructure_info and "vulnerable_instance" in infrastructure_info:
                target_ip = infrastructure_info["vulnerable_instance"].get("public_ip")
        
        if not target_ip:
            return jsonify({
                "success": False,
                "error": "No target IP provided and no infrastructure info available"
            }), 400

        try:
            # Perform ICMP ping test
            result = ping_test(target_ip)
            
            return jsonify({
                "success": result["success"],
                "target_ip": target_ip,
                "message": result["message"],
                "details": result["details"]
            })
            
        except Exception as e:
            app.logger.error(f"Validation error: {e}")
            return jsonify({
                "success": False,
                "error": str(e)
            }), 500

    @plugin_blueprint.route("/info", methods=["GET"])
    @admins_only
    def get_info():
        """
        Returns infrastructure information
        """
        return jsonify({
            "infrastructure": infrastructure_info,
            "plugin_version": __version__
        })

    def ping_test(target_ip, count=3, timeout=5):
        """
        Performs ICMP ping test to validate connectivity
        
        Args:
            target_ip: IP address to ping
            count: Number of ping packets to send
            timeout: Timeout in seconds
            
        Returns:
            dict with success status, message, and details
        """
        try:
            # Run ping command
            cmd = ["ping", "-c", str(count), "-W", str(timeout), target_ip]
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=timeout + 2
            )
            
            if result.returncode == 0:
                # Parse ping output for statistics
                output = result.stdout
                lines = output.split('\n')
                
                # Extract statistics
                stats_line = [l for l in lines if 'packets transmitted' in l]
                rtt_line = [l for l in lines if 'rtt min/avg/max' in l or 'round-trip' in l]
                
                stats = stats_line[0] if stats_line else "No statistics available"
                rtt = rtt_line[0] if rtt_line else "No RTT data"
                
                return {
                    "success": True,
                    "message": f"Successfully reached {target_ip}",
                    "details": {
                        "target": target_ip,
                        "statistics": stats.strip(),
                        "rtt": rtt.strip(),
                        "raw_output": output
                    }
                }
            else:
                return {
                    "success": False,
                    "message": f"Failed to reach {target_ip}",
                    "details": {
                        "target": target_ip,
                        "error": result.stderr,
                        "return_code": result.returncode
                    }
                }
                
        except subprocess.TimeoutExpired:
            return {
                "success": False,
                "message": f"Timeout reaching {target_ip}",
                "details": {
                    "target": target_ip,
                    "error": "Ping request timed out"
                }
            }
        except Exception as e:
            return {
                "success": False,
                "message": f"Error testing {target_ip}",
                "details": {
                    "target": target_ip,
                    "error": str(e)
                }
            }

    # Register the blueprint
    app.register_blueprint(plugin_blueprint)

    app.logger.info(f"Loaded {__plugin_name__} v{__version__}")
