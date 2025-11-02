# SaaS Infrastructure Automation Script

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-Debian-red.svg)](https://www.debian.org/)
[![DevOps](https://img.shields.io/badge/DevOps-Automation-blue.svg)](https://github.com)

A production-ready infrastructure-as-code solution that transforms a fresh Debian installation into a fully functional SaaS platform with automated deployment, user management, subscription billing, and disaster recovery capabilities.

## 🚀 Overview

This project demonstrates modern DevOps practices by automating the complete provisioning of a subscription-based software delivery platform. The script orchestrates the deployment of a multi-tier web application with integrated payment, license validation, and automated maintenance workflows.

**Perfect for demonstrating:**
- Infrastructure as Code (IaC) principles
- Full-stack deployment automation
- CI/CD readiness
- Cloud-native architecture patterns
- Database lifecycle management
- API-driven software licensing

## 🏗️ Architecture

The provisioned system implements a complete SaaS business model:
```
┌─────────────────────────────────────────────────┐
│                Web Application Layer            │
│  ┌──────────────┐         ┌──────────────┐      │
│  │ register.php │         │  login.php   │      │
│  │ User Signup  │────────▶│ Auth + Store │      │
│  └──────────────┘         └──────────────┘      │
└─────────────────┬───────────────┬───────────────┘
                  │               │
        ┌─────────▼───────────────▼─────────┐
        │      MySQL Database Layer         │
        │  • User accounts                  │
        │  • Subscription management        │
        │  • License expiration tracking    │
        └─────────────┬─────────────────────┘
                      │
        ┌─────────────▼──────────────────────┐
        │     Flask REST API Layer           │
        │  • Real-time license validation    │
        │  • Software authentication         │
        └────────────────────────────────────┘
                      │
        ┌─────────────▼───────────────────────┐
        │    Automated Operations Layer       │
        │  • Daily subscription reconciliation│
        │  • Automated database backups       │
        │  • Cron-based maintenance jobs      │
        └─────────────────────────────────────┘
```

## ✨ Features

### User Management & Authentication
- **Self-service registration** with MySQL persistence
- **Secure authentication** via PHP session management
- **Database-backed user storage** with proper schema design

### Subscription & Monetization
- **Integrated payment flow** within the application
- **Automated subscription lifecycle management**
- **Expiration date tracking** for recurring billing
- **Grace period handling** and subscription renewal logic

### Software Distribution & Licensing
- **Authenticated software downloads** (post-purchase)
- **Flask-powered REST API** for license validation
- **Client-side license checks** enforcing subscription status
- **Real-time access control** based on database state

### DevOps Automation
- **One-command provisioning** of the entire stack
- **Automated daily reconciliation** via cron jobs
- **Subscription status synchronization** (active/inactive)
- **Scheduled database backups** for disaster recovery
- **Idempotent deployment** suitable for CI/CD pipelines

## 🛠️ Technology Stack

| Layer | Technology |
|-------|-----------|
| **Web Server** | Apache|
| **Backend** | PHP |
| **API** | Python Flask |
| **Database** | MySQL |
| **Automation** | Bash, Python, Cron |
| **OS** | Debian Linux |

## 📋 Prerequisites

- Fresh Debian installation (Debian 13)
- Root or sudo access
- Internet connectivity for package installation

## ⚡ Quick Start
```bash
# Clone the repository
git clone https://github.com/denisnikov/saas-auth-platform.git
cd saas-auth-platform

# Make the script executable
chmod +x provision.sh

# Run the provisioning script
./provision.sh
```

The script will automatically:
1. Install and configure the web server stack
2. Set up MySQL with the required schema
3. Deploy the PHP web application
4. Configure the Flask API service
5. Install cron jobs for automated maintenance
6. Initialize backup routines

## 🔧 Post-Installation

After successful provisioning:

1. **Access the application**: `http://localhost/register.php`
2. **Register a new account** 
3. **Purchase subscription**: Log in and complete the payment flow
4. **Download software** 
5. **Monitor operations**: Check cron logs for scheduled tasks

## 🎯 Use Cases

- **DevOps Portfolio Projects**: Showcase automation and IaC skills
- **SaaS MVP Deployment**: Rapid prototyping of subscription businesses
- **License Server Implementation**: Software distribution with access control
- **Learning Platform**: Study modern web application architecture
- **Interview Preparation**: Demonstrate full-stack DevOps capabilities

## 🔐 Security Considerations

- Update all default passwords before production use
- Implement HTTPS with SSL/TLS certificates
- Configure firewall rules (UFW/iptables)
- Enable MySQL root password and remote access restrictions
- Review PHP security settings (disable dangerous functions)
- Implement rate limiting on API endpoints

## 📈 DevOps Skills Demonstrated

✅ **Infrastructure Automation** - Fully scripted server provisioning  
✅ **Database Administration** - MySQL setup, schema management, backups  
✅ **Web Application Deployment** - Multi-language stack orchestration  
✅ **API Development** - RESTful service implementation  
✅ **Cron Job Management** - Scheduled task automation  
✅ **System Administration** - Service configuration and monitoring  
✅ **Scripting** - Bash, Python, PHP integration  
✅ **Version Control** - Git-based infrastructure management  

## 🚀 Future Enhancements

- [ ] Docker containerization for portability
- [ ] Ansible playbook conversion for enterprise deployment
- [ ] Terraform integration for cloud provisioning (AWS/GCP/Azure)
- [ ] Prometheus/Grafana monitoring stack
- [ ] CI/CD pipeline with GitHub Actions
- [ ] Email notifications for subscription expiration
- [ ] Admin dashboard for user management
- [ ] Payment gateway integration (Stripe/PayPal)
