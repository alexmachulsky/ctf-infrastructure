# CTFd Docker Deployment

This directory contains Docker Compose configuration for deploying CTFd platform.

## Quick Start

### Deploy CTFd

```bash
# Make script executable
chmod +x deploy-ctfd.sh

# Run deployment script
./deploy-ctfd.sh
```

The script will:
1. Pull latest CTFd images
2. Start CTFd with MariaDB and Redis
3. Expose CTFd on port 8000

### Access CTFd

After deployment, access CTFd at:
- **Local**: http://localhost:8000
- **Public**: http://YOUR_SERVER_IP:8000

## Initial Admin Setup

1. **Open CTFd URL** in your browser
2. **Setup Wizard** will appear (first-time only):
   - **Admin Details**: Set username, email, password
   - **CTF Settings**: 
     - Name: "CTF Infrastructure Challenge"
     - Description: "Sudo Privilege Escalation CTF"
     - User Mode: Public or Private
   - **CTF Mode**: Select "Jeopardy" (individual challenges)
   - **Time**: Start immediately or set schedule
3. **Login** with your admin credentials

## Architecture

The deployment includes three containers:

### 1. CTFd (Main Application)
- **Image**: `ctfd/ctfd:latest`
- **Port**: 8000
- **Purpose**: Web interface and challenge management

### 2. MariaDB (Database)
- **Image**: `mariadb:10.11`
- **Purpose**: Store challenges, users, submissions
- **Credentials**:
  - User: `ctfd`
  - Password: `ctfd`
  - Database: `ctfd`

### 3. Redis (Cache)
- **Image**: `redis:7-alpine`
- **Purpose**: Session management and caching

## Plugin Integration

The docker-compose file is configured to mount the CTFd plugin:
```yaml
volumes:
  - ./ctfd-plugin:/opt/CTFd/CTFd/plugins/ctfd_environment_validator:ro
```

This allows the environment validation plugin (Task 4) to be loaded automatically.

## Management Commands

### View Logs
```bash
# All services
docker-compose logs -f

# CTFd only
docker-compose logs -f ctfd

# Database
docker-compose logs -f db
```

### Control Services
```bash
# Stop (keeps data)
docker-compose stop

# Start
docker-compose start

# Restart
docker-compose restart

# Stop and remove (keeps volumes)
docker-compose down

# Remove everything including data
docker-compose down -v
```

### Check Status
```bash
docker-compose ps
```

### Access CTFd Container Shell
```bash
docker exec -it ctfd /bin/sh
```

### Access Database
```bash
docker exec -it ctfd_db mysql -u ctfd -pctfd ctfd
```

## Configuration

### Environment Variables

Edit `docker-compose.yml` to customize:

```yaml
environment:
  - DATABASE_URL=mysql+pymysql://ctfd:ctfd@db/ctfd
  - REDIS_URL=redis://cache:6379
  - WORKERS=1  # Increase for production
  - LOG_FOLDER=/var/log/CTFd
  - REVERSE_PROXY=true  # If behind nginx/apache
```

### Ports

To change the port CTFd runs on:
```yaml
ports:
  - "8080:8000"  # Access on port 8080 instead
```

### Persistent Data

Data is stored in Docker volumes:
- `ctfd_db`: Database data
- `ctfd_logs`: Application logs
- `ctfd_uploads`: User uploads

To backup:
```bash
docker-compose exec db mysqldump -u ctfd -pctfd ctfd > backup.sql
```

## Troubleshooting

### Services Not Starting
```bash
# Check logs
docker-compose logs

# Check if ports are in use
sudo netstat -tlnp | grep 8000

# Restart services
docker-compose restart
```

### Cannot Access CTFd
1. Check firewall allows port 8000
2. For AWS: Ensure security group allows port 8000
3. Check CTFd container is running: `docker-compose ps`

### Database Connection Issues
```bash
# Check database is healthy
docker exec ctfd_db mysqladmin -u ctfd -pctfd ping

# Restart database
docker-compose restart db
```

### Reset CTFd (Fresh Start)
```bash
# Stop and remove everything
docker-compose down -v

# Redeploy
./deploy-ctfd.sh
```

## Security Notes

⚠️ **For Production Use:**
1. Change database passwords in docker-compose.yml
2. Set up HTTPS with reverse proxy (nginx/traefik)
3. Configure firewall properly
4. Use stronger credentials
5. Regular backups
6. Update images regularly

## Updating CTFd

```bash
# Pull latest images
docker-compose pull

# Restart with new images
docker-compose up -d
```

## Integration with Infrastructure

This CTFd deployment integrates with:
- **Vulnerable Instance**: Target for CTF challenges (SSH access)
- **CTFd Plugin**: Validates connectivity to vulnerable instance
- **Jenkins**: Automated deployment pipeline

## Creating Challenges

After setup:
1. Login as admin
2. Go to **Admin Panel** → **Challenges**
3. Click **Create Challenge**
4. Configure challenge:
   - **Name**: "Sudo Find Privilege Escalation"
   - **Category**: "Privilege Escalation"
   - **Description**: Instructions to access vulnerable instance
   - **Value**: Points
   - **Flag**: `CTF{sud0_f1nd_pr1v3sc_c0mpl3t3}`

## Resources

- [CTFd Documentation](https://docs.ctfd.io/)
- [CTFd GitHub](https://github.com/CTFd/CTFd)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
