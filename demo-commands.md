# 🖥️ Cloud Sentinel - Demo Commands

**Step-by-Step Commands for Live Demonstration**

---

## 🚀 Pre-Demo Setup

### Check Prerequisites

```powershell
# Verify AWS CLI is working
aws sts get-caller-identity

# Verify Terraform is installed
terraform version

# Navigate to project directory
cd H:\CICD\cloud-sentinel
```

---

## 📋 Demo Execution Steps

### **Step 1: Start Infrastructure (Windows Terminal)**

```powershell
# Start all EC2 instances
.\scripts\start_instances.ps1

# Wait for instances to start, then check status
.\scripts\status.ps1
```

**Expected Output:**

```
==========================================
CLOUD SENTINEL - Starting All Instances
==========================================

Found 10 stopped instances:
  - i-xxxxx (control)
  - i-xxxxx (web-01)
  - ... (8 more)

Starting instances...
All instances started!

Instance Details:
Name                    | Instance ID      | Public IP      | Private IP    | State
cloud-sentinel-control  | i-xxxxx         | 43.205.x.x     | 10.0.1.x     | running
cloud-sentinel-web-01   | i-xxxxx         | 13.201.x.x     | 10.0.1.x     | running
...
```

---

### **Step 2: Connect to Control Node**

```powershell
# SSH into the control node (replace IP with actual)
ssh -i "cloud-sentinel-key.pem" ubuntu@43.205.229.116
```

**Expected Output:**

```
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 6.2.0-1009-aws x86_64)
ubuntu@ip-10-0-1-xxx:~$
```

---

### **Step 3: Install Security Scanner (Ubuntu Terminal)**

```bash
# Update package list
sudo apt update

# Install Python pip if not available
sudo apt install python3-pip -y

# Install Checkov security scanner
pip3 install checkov

# Verify installation
checkov --version
```

**Expected Output:**

```
2.5.x
```

---

### **Step 4: Clone and Scan Infrastructure Code**

```bash
# Clone the repository
git clone https://github.com/sravanitammali/cloud-sentinel.git

# Navigate to project directory
cd cloud-sentinel

# List Terraform files to show what we're scanning
ls -la terraform/

# Optional: Test the configuration first
python3 test-scan.py

# Run security scan on Terraform code
checkov -d terraform/
```

**Expected Output (Sample):**

```
🛡️  Cloud Sentinel - Configuration Test
==================================================
📋 Checking configuration files...
==================================================
✅ .checkov.yaml: soft-fail enabled for demo
✅ .checkov.yaml: no checks skipped
✅ GitHub Actions workflow found
==================================================
🔍 Testing Checkov configuration...
==================================================
✅ Passed checks: 45
❌ Failed checks: 28
==================================================
🎯 SUCCESS: Checkov detected security violations!
   Expected violations in:
   - Security groups (SSH open to 0.0.0.0/0)
   - EC2 instances (unencrypted EBS)
   - S3 buckets (no encryption/public access)
   - IAM policies (wildcard permissions)

🎉 Configuration test PASSED!
   Your GitHub Actions pipeline should now detect violations.
```

**Then the full Checkov scan:**

```
       _               _
   ___| |__   ___  ___| | _______   __
  / __| '_ \ / _ \/ __| |/ / _ \ \ / /
 | (__| | | |  __/ (__|   < (_) \ V /
  \___|_| |_|\___|\___|_|\_\___/ \_/

By bridgecrew.io | version: 2.5.x

terraform scan results:

Passed checks: 45, Failed checks: 28, Skipped checks: 0

Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0/0 to port 22"
	FAILED for resource: aws_security_group.web_insecure
	File: /terraform/security_groups.tf:67-85
	Guide: https://docs.bridgecrew.io/docs/networking_1

Check: CKV_AWS_8: "Ensure EBS volume encryption is enabled"
	FAILED for resource: aws_instance.web_02
	File: /terraform/ec2_instances.tf:55-75
	Guide: https://docs.bridgecrew.io/docs/general_13

... (more violations)
```

---

### **Step 5: Detailed Analysis Commands**

```bash
# Run scan with JSON output for detailed analysis
checkov -d terraform/ -o json > scan_results.json

# Show summary of violations by severity
checkov -d terraform/ --compact

# Scan specific file types
checkov -f terraform/security_groups.tf

# Show only failed checks
checkov -d terraform/ --check CKV_AWS_24,CKV_AWS_8,CKV_AWS_19
```

---

### **Step 6: Database Logging Demo (Optional)**

```bash
# Run our custom scanner with database logging
python3 scanner/scan.py -d terraform/

# Check if database was created
ls -la data/

# Query the database (if SQLite is installed)
sqlite3 data/scan_results.db "SELECT check_id, severity, resource_name FROM violations LIMIT 10;"
```

---

### **Step 7: Show GitHub Actions Integration**

**In Browser:**

1. Navigate to: `https://github.com/sravanitammali/cloud-sentinel`
2. Click on "Actions" tab
3. Show latest workflow run
4. Click on "Security Scan" job
5. Show Checkov results in the pipeline

**Commands to trigger new scan:**

```bash
# Make a small change to trigger pipeline
echo "# Updated $(date)" >> terraform/main.tf

# Commit and push
git add .
git commit -m "Trigger security scan demo"
git push
```

---

## 🔍 Key Commands for Different Scenarios

### **Show Specific Violation Types:**

```bash
# Security Group violations
checkov -f terraform/security_groups.tf --framework terraform

# S3 bucket violations
checkov -f terraform/s3.tf --framework terraform

# IAM policy violations
checkov -f terraform/iam.tf --framework terraform

# EC2 instance violations
checkov -f terraform/ec2_instances.tf --framework terraform
```

### **Filter by Severity:**

```bash
# Show only critical/high severity (custom script needed)
checkov -d terraform/ | grep -E "(CRITICAL|HIGH)"

# Count violations by type
checkov -d terraform/ --compact | grep -c "FAILED"
```

### **Generate Reports:**

```bash
# Generate HTML report
checkov -d terraform/ -o cli -o html --output-file-path ./reports/

# Generate SARIF format for security tools
checkov -d terraform/ -o sarif --output-file-path ./reports/
```

---

## 🛠️ Troubleshooting Commands

### **If Checkov Installation Fails:**

```bash
# Alternative installation method
sudo apt install python3-checkov

# Or use Docker
docker run --rm -v $(pwd):/tf bridgecrew/checkov -d /tf/terraform/
```

### **If Git Clone Fails:**

```bash
# Check internet connectivity
ping github.com

# Use HTTPS instead of SSH
git clone https://github.com/sravanitammali/cloud-sentinel.git
```

### **If SSH Connection Fails:**

```powershell
# Check instance status
aws ec2 describe-instances --filters "Name=tag:Name,Values=cloud-sentinel-control" --query "Reservations[*].Instances[*].[State.Name,PublicIpAddress]"

# Get current public IP
aws ec2 describe-instances --filters "Name=tag:Name,Values=cloud-sentinel-control" --query "Reservations[*].Instances[*].PublicIpAddress" --output text
```

---

## 📊 Expected Results Summary

### **Violation Counts:**

- **Total Checks**: ~80-90
- **Passed**: ~45-55
- **Failed**: ~25-35
- **Skipped**: 0 (all violations now detected)

### **Key Violations to Highlight:**

1. `CKV_AWS_24` - SSH open to 0.0.0.0/0
2. `CKV_AWS_8` - Unencrypted EBS volumes
3. `CKV_AWS_19` - S3 bucket without encryption
4. `CKV_AWS_1` - Wildcard IAM permissions
5. `CKV_AWS_53` - S3 public access not blocked

---

## 🧹 Post-Demo Cleanup

### **Stop Instances to Save Costs:**

```powershell
# Back on Windows terminal
.\scripts\stop_instances.ps1
```

### **Verify All Stopped:**

```powershell
.\scripts\status.ps1
```

**Expected Output:**

```
Summary:
  Running: 0
  Stopped: 10

All instances stopped - only storage charges apply (~Rs.5/day)
```

---

## 📝 Demo Notes

### **Timing Guidelines:**

- Step 1-2: 3 minutes
- Step 3: 2 minutes
- Step 4: 5 minutes
- Step 5: 5 minutes
- Step 6-7: 10 minutes

### **Key Points to Emphasize:**

- Real AWS infrastructure (not simulation)
- Automatic detection of security issues
- Integration with CI/CD pipeline
- Comprehensive violation reporting
- Cost management capabilities

### **Backup Plans:**

- If live demo fails, show pre-recorded results
- Have screenshots of GitHub Actions ready
- Keep sample scan output in a text file

---

_Commands prepared by: Tammali Saisravani_  
_Project: Cloud Sentinel DevSecOps Security Scanner_
