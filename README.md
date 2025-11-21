# Automated SaaS Provisioning & Management Engine

> A full-stack Infrastructure-as-Code (IaC) solution that automates the deployment, management, and monetization lifecycle of a subscription-based software platform.

![Debian](https://img.shields.io/badge/Debian-13-A81D33?style=flat-square&logo=debian)
![Bash](https://img.shields.io/badge/Scripting-Bash-4EAA25?style=flat-square&logo=gnu-bash)
![Python](https://img.shields.io/badge/Automation-Python-3776AB?style=flat-square&logo=python)
![PHP](https://img.shields.io/badge/Backend-PHP-777BB4?style=flat-square&logo=php)
![MySQL](https://img.shields.io/badge/Database-MySQL-4479A1?style=flat-square&logo=mysql)

## 📖 Overview

This project represents a complete SaaS ecosystem designed for a fictional software vendor. It addresses three core business challenges:
1.  **Operational Efficiency:** Reducing server setup time from hours to minutes via automation.
2.  **Revenue Assurance:** Automating user expiry and access revocation to prevent revenue leakage.
3.  **Business Continuity:** Providing one-touch disaster recovery capabilities.

The core component is `provision.sh`, a Bash script that transforms a fresh **Debian 13** installation into a production-ready server with a secured LAMP stack, scheduled cron jobs, and a REST API for software authentication.

## 🏗 Architecture

The system is composed of three distinct layers:

1.  **Infrastructure Layer (Bash):** Handles OS configuration, package installation, and database initialization.
2.  **Application Layer (PHP/MySQL):** A transactional web frontend (`register.php`, `login.php`) and a REST API for software license verification.
3.  **Automation Layer (Python):** Background services that manage subscription validity and administrative CLI tools.

## 🚀 Key Features & Business Outcomes

### 1. Automated Provisioning (`provision.sh`)
*   **Function:** Installs Apache, PHP, MySQL, Python dependencies, and configures system security.
*   **Metric:** Reduces deployment time by **~98%**.
*   **Disaster Recovery:** Includes the equivalent to a `--restore` flag to rebuild the server state from a MySQL backup dump during provisioning.

### 2. Subscription Lifecycle Controller (`subscription_monitor.py`)
*   **Function:** A cron-triggered Python script that audits the user database daily.
*   **Revenue Protection:** Automatically calculates expiry dates. If a subscription is expired, the user's status is instantly set to `inactive`, preventing unauthorized access to the software.

### 3. Secure Transactional Frontend
*   **Security:** All user inputs (registration/login) are strictly sanitized to prevent **SQL Injection (SQLi)**.
*   **API Authentication:** The client software (sold by the fictional company) authenticates against the server's REST API to verify active subscription status before launching.

### 4. Admin Management Tool
*   **Function:** A Python-based CLI tool allowing system administrators to manually extend subscriptions without interacting directly with SQL queries.

## 🛠️ Installation & Usage

### Prerequisites
*   A fresh installation of **Debian 13 (Bookworm)**.
*   Root access.

### Deployment
1.  Clone the repository to the server:
    ```bash
    git clone https://github.com/denisnikov/saas-auth-platform.git
    cd saas-auth-platform
    ```

2.  Make the provision script executable:
    ```bash
    chmod +x provision.sh
    ```

3.  Run the provisioner:
    ```bash
    # Standard installation
    ./provision.sh
    ```
