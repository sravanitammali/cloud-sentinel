# ===========================================
# TEST FILE - Trigger GitHub Actions Demo
# ===========================================
# This file is created to demonstrate that 
# GitHub Actions automatically triggers when
# files are added to the terraform/ folder

# Simple test resource
resource "random_string" "test_trigger" {
  length  = 8
  special = false
  upper   = false
  
  # This will be flagged by Checkov as it's not following
  # some best practices, adding to our violation count
}

# Test comment - created at $(Get-Date)
# This file can be safely deleted after demo