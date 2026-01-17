#!/bin/bash
# ===========================================
# CLOUD SENTINEL - Setup Script
# ===========================================
# Run this script on your EC2 control node to
# install all required dependencies
# 
# Usage: chmod +x setup.sh && ./setup.sh
# ===========================================

set -e  # Exit on error

echo "=========================================="
echo "CLOUD SENTINEL - Setup Script"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# -------------------------------------------
# Update System
# -------------------------------------------
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y
print_status "System updated"

# -------------------------------------------
# Install Basic Tools
# -------------------------------------------
echo ""
echo "Installing basic tools..."
sudo apt install -y \
    git \
    curl \
    wget \
    unzip \
    jq \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

print_status "Basic tools installed"

# -------------------------------------------
# Install Python 3 and pip
# -------------------------------------------
echo ""
echo "Installing Python 3..."
sudo apt install -y python3 python3-pip python3-venv
print_status "Python 3 installed"

# -------------------------------------------
# Install AWS CLI
# -------------------------------------------
echo ""
echo "Installing AWS CLI..."
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
    print_status "AWS CLI installed"
else
    print_warning "AWS CLI already installed"
fi

# -------------------------------------------
# Install Terraform
# -------------------------------------------
echo ""
echo "Installing Terraform..."
if ! command -v terraform &> /dev/null; then
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install -y terraform
    print_status "Terraform installed"
else
    print_warning "Terraform already installed"
fi

# -------------------------------------------
# Install Docker
# -------------------------------------------
echo ""
echo "Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    print_status "Docker installed"
    print_warning "You may need to log out and back in for Docker permissions"
else
    print_warning "Docker already installed"
fi

# -------------------------------------------
# Install Checkov
# -------------------------------------------
echo ""
echo "Installing Checkov..."
pip3 install --user checkov
print_status "Checkov installed"

# -------------------------------------------
# Install Python Dependencies
# -------------------------------------------
echo ""
echo "Installing Python dependencies..."
if [ -f "scanner/requirements.txt" ]; then
    pip3 install --user -r scanner/requirements.txt
    print_status "Python dependencies installed"
else
    print_warning "requirements.txt not found, skipping"
fi

# -------------------------------------------
# Create Required Directories
# -------------------------------------------
echo ""
echo "Creating directories..."
mkdir -p data logs checkov_results reports
print_status "Directories created"

# -------------------------------------------
# Setup Environment File
# -------------------------------------------
echo ""
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        cp .env.example .env
        print_status "Created .env from .env.example"
        print_warning "Please edit .env with your actual values!"
    fi
else
    print_warning ".env already exists"
fi

# -------------------------------------------
# Verify Installations
# -------------------------------------------
echo ""
echo "=========================================="
echo "Verifying installations..."
echo "=========================================="

echo -n "Git: "
git --version

echo -n "Python: "
python3 --version

echo -n "AWS CLI: "
aws --version

echo -n "Terraform: "
terraform --version | head -n 1

echo -n "Docker: "
docker --version 2>/dev/null || echo "Not available (may need re-login)"

echo -n "Checkov: "
checkov --version 2>/dev/null || ~/.local/bin/checkov --version

# -------------------------------------------
# Final Instructions
# -------------------------------------------
echo ""
echo "=========================================="
echo "SETUP COMPLETE!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Edit .env file with your AWS credentials and settings"
echo "2. Configure AWS CLI: aws configure"
echo "3. Create SSH key pair in AWS Console"
echo "4. Run a test scan: ./scripts/run_scan.sh"
echo ""
echo "If Docker commands fail, log out and back in, then try again."
echo ""
