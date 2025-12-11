# Apache HTTP Server Role

![Ahab Logo](../docs/images/ahab-logo.png)

Installs and configures Apache HTTP Server on Fedora, Debian, and Ubuntu systems.

## Features

- ✅ Multi-platform support (Fedora, Debian, Ubuntu)
- ✅ Automatic OS detection and configuration
- ✅ Firewall configuration (firewalld/ufw)
- ✅ Security hardening
- ✅ Service management
- ✅ Health checks
- ✅ Default welcome page

## Requirements

- Ansible 2.9 or higher
- Supported OS: Fedora 38+, Debian 11+, Ubuntu 20.04+
- Root or sudo access

## Role Variables

### Required Variables

None - all variables have sensible defaults.

### Optional Variables

```yaml
# Server configuration
apache_server_name: "{{ ansible_fqdn }}"  # Server name
apache_port: 80                            # HTTP port
apache_ssl_port: 443                       # HTTPS port

# Document root
apache_document_root: /var/www/html

# Logging
apache_log_level: warn

# Performance
apache_max_clients: 150
apache_max_requests_per_child: 3000

# Security
apache_server_tokens: Prod
apache_server_signature: "Off"
```

## Dependencies

None

## Example Playbook

### Basic Installation

```yaml
---
- hosts: webservers
  become: yes
  roles:
    - apache
```

### Custom Configuration

```yaml
---
- hosts: webservers
  become: yes
  roles:
    - apache
  vars:
    apache_server_name: "www.example.com"
    apache_document_root: /var/www/mysite
```

## Usage

### Install Apache

```bash
# Test in development
ansible-playbook -i inventory/dev/hosts.yml playbooks/webserver.yml

# Deploy to production
ansible-playbook -i inventory/prod/hosts.yml playbooks/webserver.yml
```

### Run Specific Tasks

```bash
# Only install packages
ansible-playbook playbooks/webserver.yml --tags packages

# Only configure
ansible-playbook playbooks/webserver.yml --tags config

# Only security settings
ansible-playbook playbooks/webserver.yml --tags security
```

## Testing

### Test with Vagrant

```bash
cd ahab
make install
make ssh

# Inside VM
curl http://localhost
```

### Test with Docker

```bash
cd roles/apache
docker build -t ahab/apache:1.0.0 .
docker run -d -p 80:80 --name apache ahab/apache:1.0.0
curl http://localhost
```

## Verification

After installation, verify Apache is working:

```bash
# Check service status
systemctl status httpd  # Fedora
systemctl status apache2  # Debian/Ubuntu

# Test HTTP response
curl -I http://localhost

# View logs
tail -f /var/log/httpd/error_log  # Fedora
tail -f /var/log/apache2/error.log  # Debian/Ubuntu
```

## Platform-Specific Notes

### Fedora/RHEL

- Package: `httpd`
- Service: `httpd`
- Config: `/etc/httpd/conf/httpd.conf`
- Document root: `/var/www/html`
- Logs: `/var/log/httpd/`

### Debian/Ubuntu

- Package: `apache2`
- Service: `apache2`
- Config: `/etc/apache2/apache2.conf`
- Document root: `/var/www/html`
- Logs: `/var/log/apache2/`

## Security

This role implements several security best practices:

- ✅ Disables directory listing
- ✅ Sets ServerTokens to Prod
- ✅ Disables ServerSignature
- ✅ Configures firewall rules
- ✅ Runs as non-root user

## Troubleshooting

### Apache won't start

```bash
# Check configuration
httpd -t  # Fedora
apache2ctl -t  # Debian/Ubuntu

# Check logs
journalctl -u httpd -n 50  # Fedora
journalctl -u apache2 -n 50  # Debian/Ubuntu
```

### Port 80 already in use

```bash
# Find what's using port 80
sudo lsof -i :80
sudo netstat -tulpn | grep :80
```

### Firewall blocking access

```bash
# Fedora
sudo firewall-cmd --list-all
sudo firewall-cmd --add-service=http --permanent
sudo firewall-cmd --reload

# Debian/Ubuntu
sudo ufw status
sudo ufw allow 80/tcp
```

## License

MIT

## Author

Ahab Project

## See Also

- [PHP Role](../php/README.md) - PHP integration
- [MODULE.yml](MODULE.yml) - Module metadata
- [Dockerfile](Dockerfile) - Docker image
