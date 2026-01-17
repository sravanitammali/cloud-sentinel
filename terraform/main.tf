# ===========================================
# CLOUD SENTINEL - Main Terraform Configuration
# ===========================================
# DevSecOps Infrastructure Security Scanner
# 
# This project demonstrates:
# - Infrastructure as Code with Terraform
# - Security scanning with Checkov
# - CI/CD pipeline with GitHub Actions
# - Centralized logging with SQLite
#
# IMPORTANT: This infrastructure contains INTENTIONALLY
# INSECURE configurations for demonstration purposes.
# DO NOT deploy this to production!
# ===========================================

# Note: Random provider is declared here for S3 bucket naming
# AWS provider is declared in providers.tf

# -------------------------------------------
# Data Sources
# -------------------------------------------

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Get current region
data "aws_region" "current" {}

# -------------------------------------------
# Local Values
# -------------------------------------------
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  # Count of secure vs insecure resources
  secure_instances   = 6
  insecure_instances = 4
}
