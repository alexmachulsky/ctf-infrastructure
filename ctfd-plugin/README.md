# CTFd Environment Validator Plugin

A CTFd plugin that validates connectivity between CTFd and vulnerable EC2 instances using ICMP ping.

## Features

- 🔍 **ICMP Connectivity Testing**: Validates reachability to vulnerable instances
- 📊 **Infrastructure Info Display**: Shows Terraform output details
- 🎯 **Admin Interface**: Simple web UI for validation
- 📡 **API Endpoint**: Programmatic validation via REST API
- 📋 **Detailed Results**: Shows ping statistics and RTT data

## Installation

### Method 1: Docker Compose (Recommended)

The plugin is automatically mounted when using the provided docker-compose.yml:

```yaml
volumes:
  - ./ctfd-plugin:/opt/CTFd/CTFd/plugins/ctfd_environment_validator:ro
```

### Method 2: Manual Installation

1. Copy plugin directory to CTFd plugins folder:
```bash
cp -r ctfd-plugin /path/to/CTFd/CTFd/plugins/ctfd_environment_validator
```

2. Restart CTFd:
```bash
cd /path/to/CTFd
docker-compose restart ctfd
```

## Configuration

### Infrastructure Information

The plugin reads Terraform outputs from `infrastructure.json`. Generate this file:

```bash
cd terraform
terraform output -raw infrastructure_info > ../ctfd-plugin/infrastructure.json
```

**Example infrastructure.json:**
```json
{
  "vulnerable_instance": {
    "id": "i-0123456789abcdef",
    "public_ip": "13.235.27.225",
    "public_dns": "ec2-13-235-27-225.ap-south-1.compute.amazonaws.com",
    "private_ip": "10.0.1.100"
  },
  "vpc_id": "vpc-12345678",
  "subnet_id": "subnet-12345678",
  "region": "ap-south-1",
  "generated_at": "2026-02-02T10:00:00Z"
}
```

## Usage

### Admin Web Interface

1. Login to CTFd as admin
2. Navigate to: `http://your-ctfd-url/env-validator/admin`
3. View infrastructure information
4. Click "Validate Connectivity" button
5. View results with ping statistics

### API Endpoints

#### Validate Environment
```bash
POST /env-validator/validate
Content-Type: application/json
Authorization: Admin session required

{
  "target_ip": "13.235.27.225"  # Optional - uses infrastructure.json if not provided
}
```

**Response (Success):**
```json
{
  "success": true,
  "target_ip": "13.235.27.225",
  "message": "Successfully reached 13.235.27.225",
  "details": {
    "target": "13.235.27.225",
    "statistics": "3 packets transmitted, 3 received, 0% packet loss",
    "rtt": "rtt min/avg/max/mdev = 162.790/163.065/163.204/0.194 ms",
    "raw_output": "..."
  }
}
```

**Response (Failure):**
```json
{
  "success": false,
  "target_ip": "13.235.27.225",
  "message": "Failed to reach 13.235.27.225",
  "details": {
    "target": "13.235.27.225",
    "error": "Destination Host Unreachable",
    "return_code": 1
  }
}
```

#### Get Infrastructure Info
```bash
GET /env-validator/info
Authorization: Admin session required
```

**Response:**
```json
{
  "infrastructure": {
    "vulnerable_instance": {...},
    "vpc_id": "vpc-12345678",
    "region": "ap-south-1"
  },
  "plugin_version": "1.0.0"
}
```

## How It Works

1. **Terraform Outputs**: Infrastructure details are exported from Terraform as JSON
2. **Plugin Loading**: CTFd loads the plugin and reads infrastructure.json
3. **Validation Request**: Admin triggers validation via web UI or API
4. **ICMP Ping**: Plugin executes `ping -c 3 -W 5 <target_ip>`
5. **Results Parsing**: Extracts statistics and RTT data from ping output
6. **Response**: Returns success/failure with detailed information

## Security Considerations

- ⚠️ **Admin Only**: All endpoints require admin authentication
- 🔒 **Read-Only Mount**: Plugin is mounted as read-only in Docker
- 🎯 **ICMP Only**: Uses ICMP ping, no SSH or dangerous commands
- 📝 **Validation**: Input validation on target IP addresses
- 🔐 **Subprocess Safety**: Uses subprocess.run with timeout protection

## Troubleshooting

### Plugin Not Loading

Check CTFd logs:
```bash
docker-compose logs -f ctfd | grep -i "environment\|validator"
```

Common issues:
- `infrastructure.json` missing or invalid JSON
- Incorrect plugin directory path in docker-compose.yml
- Missing `__init__.py` or `load()` function

### Validation Fails

1. **Check Security Groups**: Ensure ICMP is allowed
   ```bash
   aws ec2 describe-security-groups --group-ids sg-xxx
   ```

2. **Test Manually**:
   ```bash
   ping -c 3 13.235.27.225
   ```

3. **Check CTFd Container Network**:
   ```bash
   docker exec -it ctfd ping -c 3 13.235.27.225
   ```

### Infrastructure Info Not Showing

1. Verify infrastructure.json exists:
   ```bash
   ls -la ctfd-plugin/infrastructure.json
   ```

2. Validate JSON:
   ```bash
   cat ctfd-plugin/infrastructure.json | jq .
   ```

3. Check file permissions (should be readable)

## Development

### File Structure
```
ctfd-plugin/
├── __init__.py              # Main plugin code
├── config.json              # Plugin metadata
├── templates/
│   └── env_validator_admin.html  # Admin UI
├── infrastructure.json      # Terraform outputs (generated)
└── README.md               # This file
```

### Testing Locally

```python
# Test ping function
from ctfd_plugin import ping_test

result = ping_test("13.235.27.225", count=3, timeout=5)
print(result)
```

### Adding New Features

1. Add route in `__init__.py`:
```python
@plugin_blueprint.route("/my-route", methods=["GET"])
@admins_only
def my_function():
    return jsonify({"status": "ok"})
```

2. Update template if needed
3. Restart CTFd

## Integration with Jenkins

The plugin can be used in Jenkins pipelines to validate infrastructure:

```groovy
stage('Validate Environment') {
    steps {
        sh '''
            curl -X POST http://ctfd:8000/env-validator/validate \
              -H "Content-Type: application/json" \
              -H "Cookie: session=admin-session"
        '''
    }
}
```

## Version History

- **1.0.0** (2026-02-02): Initial release
  - ICMP ping validation
  - Admin web interface
  - API endpoints
  - Infrastructure info display

## License

MIT License

## Author

CTF Infrastructure Team
