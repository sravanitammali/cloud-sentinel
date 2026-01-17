#!/bin/bash
# ===========================================
# CLOUD SENTINEL - Deploy Infrastructure
# ===========================================
# Deploy Terraform infrastructure after security scan
#
# Usage: ./scripts/deploy.sh [plan|apply|destroy]
# ===========================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ACTION="${1:-plan}"
TERRAFORM_DIR="./terraform"

echo -e "${BLUE}"
echo "=========================================="
echo "   CLOUD SENTINEL - Infrastructure Deploy"
echo "=========================================="
echo -e "${NC}"

# Check if terraform directory exists
if [ ! -d "$TERRAFORM_DIR" ]; then
    echo -e "${RED}Error: Terraform directory not found: $TERRAFORM_DIR${NC}"
    exit 1
fi

# Load environment variables
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Check AWS credentials
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ "$AWS_ACCESS_KEY_ID" == "your_aws_access_key_here" ]; then
    echo -e "${RED}Error: AWS credentials not configured in .env${NC}"
    exit 1
fi

cd "$TERRAFORM_DIR"

case "$ACTION" in
    init)
        echo -e "${YELLOW}Initializing Terraform...${NC}"
        terraform init
        ;;
    
    plan)
        echo -e "${YELLOW}Running security scan first...${NC}"
        cd ..
        ./scripts/run_scan.sh || {
            echo -e "${RED}Security scan found issues. Fix them before deploying.${NC}"
            exit 1
        }
        cd "$TERRAFORM_DIR"
        
        echo ""
        echo -e "${YELLOW}Creating Terraform plan...${NC}"
        terraform plan -out=tfplan
        echo ""
        echo -e "${GREEN}Plan created. Review above and run './scripts/deploy.sh apply' to deploy.${NC}"
        ;;
    
    apply)
        echo -e "${YELLOW}Running security scan first...${NC}"
        cd ..
        ./scripts/run_scan.sh || {
            echo -e "${RED}Security scan found issues. Fix them before deploying.${NC}"
            echo -e "${YELLOW}To deploy anyway (not recommended), use: terraform apply${NC}"
            exit 1
        }
        cd "$TERRAFORM_DIR"
        
        echo ""
        echo -e "${YELLOW}Applying Terraform configuration...${NC}"
        
        if [ -f "tfplan" ]; then
            terraform apply tfplan
        else
            terraform apply
        fi
        
        echo ""
        echo -e "${GREEN}Deployment complete!${NC}"
        ;;
    
    destroy)
        echo -e "${RED}WARNING: This will destroy all infrastructure!${NC}"
        read -p "Are you sure? (yes/no): " confirm
        
        if [ "$confirm" == "yes" ]; then
            terraform destroy
            echo -e "${GREEN}Infrastructure destroyed.${NC}"
        else
            echo "Cancelled."
        fi
        ;;
    
    output)
        terraform output
        ;;
    
    *)
        echo "Usage: $0 [init|plan|apply|destroy|output]"
        echo ""
        echo "Commands:"
        echo "  init    - Initialize Terraform"
        echo "  plan    - Run security scan and create plan"
        echo "  apply   - Run security scan and apply changes"
        echo "  destroy - Destroy all infrastructure"
        echo "  output  - Show Terraform outputs"
        exit 1
        ;;
esac
