# 🛡️ Cloud Sentinel

**DevSecOps Infrastructure Security Scanner**

Automated security scanning and policy enforcement for Infrastructure-as-Code (Terraform) deployments on AWS.

---

## 📋 Overview

Cloud Sentinel is a DevSecOps solution that:

- Scans Terraform code for security misconfigurations using Checkov
- Enforces security policies in CI/CD pipelines
- Logs all violations to a SQLite database for auditing
- Blocks insecure infrastructure from being deployed
- Generates compliance reports (Phase 2)

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    CLOUD SENTINEL                            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   Developer → GitHub → GitHub Actions → Checkov Scan        │
│                              ↓                               │
│                    ┌─────────────────┐                      │
│                    │  Security Gate  │                      │
│                    └────────┬────────┘                      │
│                             │                                │
│              ┌──────────────┼──────────────┐                │
│              ↓              ↓              ↓                │
│         [PASS]         [WARN]         [BLOCK]              │
│         Deploy      Log & Alert    Stop Deploy             │
│                                                              │
│   All results → SQLite Database → Reports & Audit          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚀 Quick Start

### Prerequisites

- AWS Account with credentials
- GitHub Account
- Ubuntu 22.04 EC2 instance (or local machine)

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/cloud-sentinel.git
cd cloud-sentinel
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env with your values
nano .env
```

### 3. Run Setup (on EC2)

```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

### 4. Run Security Scan

```bash
chmod +x scripts/run_scan.sh
./scripts/run_scan.sh
```

---

## 📁 Project Structure

```
cloud-sentinel/
├── .env.example              # Environment template
├── .env                      # Your configuration (gitignored)
├── .gitignore
├── .checkov.yaml             # Checkov configuration
├── README.md
│
├── terraform/                # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── vpc.tf               # VPC configuration
│   ├── security_groups.tf   # Security groups (secure & insecure)
│   ├── ec2_instances.tf     # 10 EC2 instances
│   ├── s3.tf                # S3 buckets
│   └── iam.tf               # IAM roles & policies
│
├── scanner/                  # Python scanner
│   ├── config.py            # Configuration loader
│   ├── database.py          # SQLite operations
│   ├── scan.py              # Main scanner
│   ├── logger.py            # Colored logging
│   └── requirements.txt
│
├── scripts/                  # Utility scripts
│   ├── setup.sh             # Install dependencies
│   ├── run_scan.sh          # Manual scan trigger
│   ├── deploy.sh            # Deploy infrastructure
│   └── view_results.py      # View scan results
│
└── .github/workflows/
    └── security-scan.yml    # CI/CD pipeline
```

---

## 🖥️ Infrastructure (10 EC2 Instances)

| Instance                  | Role                | Security    |
| ------------------------- | ------------------- | ----------- |
| cloud-sentinel-control    | DevOps Control Node | ✅ Secure   |
| cloud-sentinel-web-01     | Web Server          | ✅ Secure   |
| cloud-sentinel-web-02     | Web Server          | ❌ Insecure |
| cloud-sentinel-app-01     | App Server          | ✅ Secure   |
| cloud-sentinel-app-02     | App Server          | ❌ Insecure |
| cloud-sentinel-db-01      | Database            | ✅ Secure   |
| cloud-sentinel-db-02      | Database            | ❌ Insecure |
| cloud-sentinel-cache-01   | Cache               | ✅ Secure   |
| cloud-sentinel-monitor-01 | Monitoring          | ❌ Insecure |
| cloud-sentinel-backup-01  | Backup              | ✅ Secure   |

**Note:** Insecure instances are intentionally misconfigured for demonstration purposes.

---

## 🔍 Security Checks

Checkov scans for issues including:

| Category       | Examples                                         |
| -------------- | ------------------------------------------------ |
| **Network**    | Open SSH (0.0.0.0/0), unrestricted ports         |
| **Encryption** | Unencrypted EBS volumes, S3 without SSE          |
| **IAM**        | Wildcard permissions, overly permissive policies |
| **S3**         | Public access, no versioning                     |
| **EC2**        | IMDSv1 enabled, public IPs on private resources  |

---

## 📊 Usage

### Run Manual Scan

```bash
./scripts/run_scan.sh
```

### Deploy Infrastructure

```bash
# Initialize Terraform
./scripts/deploy.sh init

# Plan (includes security scan)
./scripts/deploy.sh plan

# Apply (includes security scan)
./scripts/deploy.sh apply

# Destroy
./scripts/deploy.sh destroy
```

### View Results

```bash
# View recent scans
python3 scripts/view_results.py scans

# View violations
python3 scripts/view_results.py violations

# View statistics
python3 scripts/view_results.py stats
```

---

## 🔧 Configuration

Edit `.env` file:

```env
# AWS
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
AWS_REGION=ap-south-1

# EC2
EC2_KEY_PAIR_NAME=cloud-sentinel-key
EC2_INSTANCE_TYPE=t2.micro

# GitHub
GITHUB_REPO_URL=https://github.com/you/cloud-sentinel
GITHUB_TOKEN=ghp_xxxxx
```

---

## 🚦 CI/CD Pipeline

The GitHub Actions workflow:

1. **Triggers on:** Push to main/develop, PRs, manual dispatch
2. **Runs Checkov** scan on terraform/ directory
3. **Validates** Terraform syntax
4. **Security Gate** checks for critical/high issues
5. **Blocks deployment** if violations found (configurable)

---

## 📈 Phase 2 Features (Coming Soon)

- [ ] Email/SNS Alerts
- [ ] Auto-remediation
- [ ] HTML/PDF Compliance Reports
- [ ] AWS Lambda integration
- [ ] Dashboard UI

---

## 🛠️ Troubleshooting

### Checkov not found

```bash
pip3 install --user checkov
export PATH=$PATH:~/.local/bin
```

### AWS credentials error

```bash
aws configure
# Enter your Access Key, Secret Key, Region
```

### Permission denied on scripts

```bash
chmod +x scripts/*.sh
```

---

## 📝 License

MIT License - See LICENSE file

---

## 👤 Author

Cloud Sentinel DevSecOps Project

---

## 🙏 Acknowledgments

- [Checkov](https://www.checkov.io/) - IaC Security Scanner
- [Terraform](https://www.terraform.io/) - Infrastructure as Code
- [AWS](https://aws.amazon.com/) - Cloud Provider
