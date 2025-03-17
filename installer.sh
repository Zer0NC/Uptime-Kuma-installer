#!/bin/bash

echo "🚀 Starting Uptime Kuma Secure Installer..."

# Function to enforce non-empty user input
get_input() {
    local prompt="$1"
    local input=""
    while [[ -z "$input" ]]; do
        read -p "$prompt" input
    done
    echo "$input"
}

# Get user inputs
DOMAIN=$(get_input "🔹 Enter your domain (e.g., status.example.com): ")
EMAIL=$(get_input "📧 Enter your email for Let's Encrypt SSL: ")
PORT=$(get_input "🔢 Enter the port for Uptime Kuma (default: 3001): ")

# Set default port if empty
PORT=${PORT:-3001}

echo "⚙️ Starting installation with the following settings:"
echo "🌍 Domain: $DOMAIN"
echo "📧 Email: $EMAIL"
echo "🚪 Port: $PORT"

# Update system and install required packages
echo "🔄 Updating system and installing dependencies..."
apt update && apt upgrade -y
apt install -y curl nano ufw fail2ban docker.io docker-compose nginx certbot python3-certbot-nginx

# Configure UFW Firewall
echo "🛡️ Configuring UFW Firewall..."
ufw allow 22/tcp    # SSH
ufw allow 80,443/tcp  # HTTP & HTTPS
ufw enable

# Install and start Uptime Kuma (Docker)
echo "🐳 Setting up Uptime Kuma in Docker..."
docker run -d --name uptime-kuma \
  -p $PORT:3001 \
  --restart=always \
  louislam/uptime-kuma

# Wait a few seconds for the container to start
sleep 5

# Secure Nginx configuration
echo "⚙️ Configuring Nginx as a secure reverse proxy..."
cat > /etc/nginx/sites-available/uptime-kuma <<EOL
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:$PORT/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # Prevent clickjacking
        add_header X-Frame-Options DENY;
        
        # Prevent content sniffing
        add_header X-Content-Type-Options nosniff;
        
        # Enable XSS protection
        add_header X-XSS-Protection "1; mode=block";

        # Enable Referrer Policy
        add_header Referrer-Policy "no-referrer-when-downgrade";
    }
}
EOL

ln -s /etc/nginx/sites-available/uptime-kuma /etc/nginx/sites-enabled/

# Fix: Move limit_req_zone to nginx.conf
echo "🔧 Updating Nginx global configuration..."
sed -i '/http {/a \ \ \ \ limit_req_zone $binary_remote_addr zone=one:10m rate=30r/m;' /etc/nginx/nginx.conf

# Test and restart Nginx
echo "🔄 Testing Nginx configuration..."
nginx -t && systemctl restart nginx || { echo "❌ Nginx configuration error!"; exit 1; }

# Secure SSL with Let's Encrypt
echo "🔒 Requesting SSL certificate with Let's Encrypt..."
certbot --nginx -d $DOMAIN --email $EMAIL --agree-tos --non-interactive

# Enable automatic SSL renewal
echo "🔄 Configuring automatic SSL renewal..."
echo "0 3 * * * root certbot renew --quiet" | tee -a /etc/crontab > /dev/null

# Configure Fail2Ban for extra security
echo "🚨 Setting up Fail2Ban..."
cat > /etc/fail2ban/jail.local <<EOL
[nginx-http-auth]
enabled = true
filter  = nginx-http-auth
action  = iptables[name=HTTPAuth, port=http, protocol=tcp]
logpath = /var/log/nginx/error.log
maxretry = 3
bantime = 3600

[sshd]
enabled = true
EOL

systemctl restart fail2ban

echo "✅ Installation complete!"
echo "🔗 Access your Uptime Kuma dashboard at: https://$DOMAIN"
