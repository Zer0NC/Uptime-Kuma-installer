# Uptime Kuma Secure Installer

A **secure and automated installer** for Uptime Kuma with **Nginx reverse proxy, Let's Encrypt SSL, UFW Firewall, and Fail2Ban security**.

## 🚀 Features
- **Automated installation** of Uptime Kuma (Docker)
- **Secure Nginx reverse proxy** with hardened security settings
- **Automatic SSL certificate (Let's Encrypt) + renewal**
- **UFW Firewall configuration** (ports 22, 80, 443)
- **Fail2Ban protection** (SSH & Nginx brute-force prevention)

## 📥 Installation

### 1️⃣ Download & Prepare Script
```bash
wget https://github.com/Zer0NC/Uptime-Kuma-installer/blob/main/installer.sh
chmod +x installer.sh
```

### 2️⃣ Run Installer
```bash
sudo ./install_uptime_kuma.sh
```

### 3️⃣ Enter Required Information
You will be asked for:
- **Domain** (e.g., `status.example.com`)
- **Email** (for SSL certificate)
- **Port** (default: `3001`)

## 🔐 Security Features
- **Nginx Security Hardening**
  - Prevents Clickjacking (`X-Frame-Options DENY`)
  - Blocks MIME-type sniffing (`X-Content-Type-Options nosniff`)
  - Enables XSS protection (`X-XSS-Protection`)
  - Enforces **rate limiting** (30 requests per minute per IP)
- **Fail2Ban Protection**
  - Blocks brute-force attacks on SSH & Nginx
- **UFW Firewall**
  - Allows only **SSH (22), HTTP (80), and HTTPS (443)**

## 🔄 SSL Auto-Renewal
SSL certificates are automatically renewed via cron job.
```bash
0 3 * * * root certbot renew --quiet
```

## 📌 Access Your Dashboard
After installation, visit:
```
https://your-domain.com
```

---

### ❓ Troubleshooting
- **Check Docker logs**
  ```bash
  docker logs uptime-kuma
  ```
- **Restart Services**
  ```bash
  systemctl restart nginx
  systemctl restart fail2ban
  ```

### 📜 License
This project is licensed under the MIT License. Feel free to contribute! 😊

