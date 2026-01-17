# ===========================================
# CLOUD SENTINEL - S3 Buckets
# ===========================================
# Demonstrates secure vs insecure S3 configurations

# Random suffix for unique bucket names
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# -------------------------------------------
# SECURE: Terraform State Bucket
# -------------------------------------------
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-tfstate-${random_id.bucket_suffix.hex}"

  tags = {
    Name         = "${var.project_name}-tfstate"
    Purpose      = "Terraform State"
    SecurityType = "secure"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -------------------------------------------
# SECURE: Logs Bucket
# -------------------------------------------
resource "aws_s3_bucket" "logs" {
  bucket = "${var.project_name}-logs-${random_id.bucket_suffix.hex}"

  tags = {
    Name         = "${var.project_name}-logs"
    Purpose      = "Application Logs"
    SecurityType = "secure"
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -------------------------------------------
# INSECURE: Data Bucket (For Demo)
# CHECKOV WILL FLAG MULTIPLE ISSUES!
# -------------------------------------------
resource "aws_s3_bucket" "data_insecure" {
  bucket = "${var.project_name}-data-insecure-${random_id.bucket_suffix.hex}"

  tags = {
    Name         = "${var.project_name}-data-insecure"
    Purpose      = "Demo Insecure Bucket"
    SecurityType = "insecure"
    Warning      = "INTENTIONALLY_INSECURE_FOR_DEMO"
  }
}

# VULNERABILITY: No versioning enabled!
resource "aws_s3_bucket_versioning" "data_insecure" {
  bucket = aws_s3_bucket.data_insecure.id
  versioning_configuration {
    status = "Disabled" # INSECURE!
  }
}

# VULNERABILITY: No encryption!
# (Intentionally not adding encryption configuration)

# VULNERABILITY: Public access not blocked!
resource "aws_s3_bucket_public_access_block" "data_insecure" {
  bucket = aws_s3_bucket.data_insecure.id

  block_public_acls       = false # INSECURE!
  block_public_policy     = false # INSECURE!
  ignore_public_acls      = false # INSECURE!
  restrict_public_buckets = false # INSECURE!
}

# -------------------------------------------
# INSECURE: Backup Bucket (For Demo)
# CHECKOV WILL FLAG: No logging, no encryption
# -------------------------------------------
resource "aws_s3_bucket" "backup_insecure" {
  bucket = "${var.project_name}-backup-insecure-${random_id.bucket_suffix.hex}"

  tags = {
    Name         = "${var.project_name}-backup-insecure"
    Purpose      = "Demo Insecure Backup"
    SecurityType = "insecure"
    Warning      = "INTENTIONALLY_INSECURE_FOR_DEMO"
  }
}

# No versioning, no encryption, no public access block
# All of these missing configurations will be flagged by Checkov
