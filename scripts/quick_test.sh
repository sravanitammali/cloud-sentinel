#!/bin/bash
# ===========================================
# CLOUD SENTINEL - Quick Test Script
# ===========================================
# Test that everything is installed correctly
# ===========================================

echo "=========================================="
echo "CLOUD SENTINEL - Quick Test"
echo "=========================================="
echo ""

PASS=0
FAIL=0

# Function to check command
check_cmd() {
    if command -v $1 &> /dev/null; then
        echo "✓ $1 is installed"
        ((PASS++))
    else
        echo "✗ $1 is NOT installed"
        ((FAIL++))
    fi
}

# Function to check file
check_file() {
    if [ -f "$1" ]; then
        echo "✓ $1 exists"
        ((PASS++))
    else
        echo "✗ $1 NOT found"
        ((FAIL++))
    fi
}

# Function to check directory
check_dir() {
    if [ -d "$1" ]; then
        echo "✓ $1 exists"
        ((PASS++))
    else
        echo "✗ $1 NOT found"
        ((FAIL++))
    fi
}

echo "Checking installed tools..."
echo "----------------------------"
check_cmd git
check_cmd python3
check_cmd pip3
check_cmd terraform
check_cmd aws

# Check checkov (might be in .local/bin)
if command -v checkov &> /dev/null || [ -f ~/.local/bin/checkov ]; then
    echo "✓ checkov is installed"
    ((PASS++))
else
    echo "✗ checkov is NOT installed"
    ((FAIL++))
fi

echo ""
echo "Checking project files..."
echo "----------------------------"
check_file ".env"
check_file ".env.example"
check_file ".gitignore"
check_file ".checkov.yaml"
check_file "README.md"

echo ""
echo "Checking directories..."
echo "----------------------------"
check_dir "terraform"
check_dir "scanner"
check_dir "scripts"
check_dir ".github/workflows"

echo ""
echo "Checking Terraform files..."
echo "----------------------------"
check_file "terraform/main.tf"
check_file "terraform/variables.tf"
check_file "terraform/providers.tf"
check_file "terraform/vpc.tf"
check_file "terraform/security_groups.tf"
check_file "terraform/ec2_instances.tf"
check_file "terraform/s3.tf"
check_file "terraform/iam.tf"
check_file "terraform/outputs.tf"

echo ""
echo "Checking scanner files..."
echo "----------------------------"
check_file "scanner/config.py"
check_file "scanner/database.py"
check_file "scanner/scan.py"
check_file "scanner/logger.py"
check_file "scanner/requirements.txt"

echo ""
echo "Checking scripts..."
echo "----------------------------"
check_file "scripts/setup.sh"
check_file "scripts/run_scan.sh"
check_file "scripts/deploy.sh"

echo ""
echo "=========================================="
echo "RESULTS: $PASS passed, $FAIL failed"
echo "=========================================="

if [ $FAIL -eq 0 ]; then
    echo "✓ All checks passed! Ready to go."
    exit 0
else
    echo "✗ Some checks failed. Run setup.sh to fix."
    exit 1
fi
