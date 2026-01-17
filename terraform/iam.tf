# ===========================================
# CLOUD SENTINEL - IAM Roles & Policies
# ===========================================
# Demonstrates secure vs insecure IAM configurations

# -------------------------------------------
# SECURE: EC2 Instance Role (Least Privilege)
# -------------------------------------------
resource "aws_iam_role" "ec2_secure_role" {
  name = "${var.project_name}-ec2-secure-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name         = "${var.project_name}-ec2-secure-role"
    SecurityType = "secure"
  }
}

resource "aws_iam_role_policy" "ec2_secure_policy" {
  name = "${var.project_name}-ec2-secure-policy"
  role = aws_iam_role.ec2_secure_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3LogsAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.logs.arn}/*"
        ]
      },
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/aws/ec2/${var.project_name}/*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_secure_profile" {
  name = "${var.project_name}-ec2-secure-profile"
  role = aws_iam_role.ec2_secure_role.name
}

# -------------------------------------------
# INSECURE: Overly Permissive Role (For Demo)
# CHECKOV WILL FLAG: Wildcard permissions!
# -------------------------------------------
resource "aws_iam_role" "ec2_insecure_role" {
  name = "${var.project_name}-ec2-insecure-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name         = "${var.project_name}-ec2-insecure-role"
    SecurityType = "insecure"
    Warning      = "INTENTIONALLY_INSECURE_FOR_DEMO"
  }
}

# VULNERABILITY: Wildcard (*) permissions - way too permissive!
resource "aws_iam_role_policy" "ec2_insecure_policy" {
  name = "${var.project_name}-ec2-insecure-policy"
  role = aws_iam_role.ec2_insecure_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "InsecureFullS3Access"
        Effect   = "Allow"
        Action   = "s3:*" # INSECURE: Full S3 access!
        Resource = "*"    # INSECURE: All resources!
      },
      {
        Sid      = "InsecureFullEC2Access"
        Effect   = "Allow"
        Action   = "ec2:*" # INSECURE: Full EC2 access!
        Resource = "*"     # INSECURE: All resources!
      },
      {
        Sid      = "InsecureIAMAccess"
        Effect   = "Allow"
        Action   = "iam:*" # INSECURE: Full IAM access!
        Resource = "*"     # INSECURE: All resources!
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_insecure_profile" {
  name = "${var.project_name}-ec2-insecure-profile"
  role = aws_iam_role.ec2_insecure_role.name
}

# -------------------------------------------
# INSECURE: Admin Policy (For Demo)
# CHECKOV WILL FLAG: Admin access!
# -------------------------------------------
resource "aws_iam_role" "admin_insecure_role" {
  name = "${var.project_name}-admin-insecure-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        # VULNERABILITY: No conditions!
      }
    ]
  })

  tags = {
    Name         = "${var.project_name}-admin-insecure-role"
    SecurityType = "insecure"
    Warning      = "INTENTIONALLY_INSECURE_FOR_DEMO"
  }
}

# VULNERABILITY: Full admin access - extremely dangerous!
resource "aws_iam_role_policy" "admin_insecure_policy" {
  name = "${var.project_name}-admin-insecure-policy"
  role = aws_iam_role.admin_insecure_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "FullAdminAccess"
        Effect   = "Allow"
        Action   = "*"  # INSECURE: ALL actions!
        Resource = "*"  # INSECURE: ALL resources!
      }
    ]
  })
}
