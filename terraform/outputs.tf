# ===========================================
# CLOUD SENTINEL - Terraform Outputs
# ===========================================

# -------------------------------------------
# VPC Outputs
# -------------------------------------------
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

# -------------------------------------------
# EC2 Instance Outputs
# -------------------------------------------
output "control_node_public_ip" {
  description = "Public IP of the control node"
  value       = aws_instance.control.public_ip
}

output "control_node_id" {
  description = "Instance ID of the control node"
  value       = aws_instance.control.id
}

output "instance_details" {
  description = "Details of all EC2 instances"
  value = {
    control = {
      id         = aws_instance.control.id
      public_ip  = aws_instance.control.public_ip
      private_ip = aws_instance.control.private_ip
      security   = "secure"
    }
    web_01 = {
      id         = aws_instance.web_01.id
      public_ip  = aws_instance.web_01.public_ip
      private_ip = aws_instance.web_01.private_ip
      security   = "secure"
    }
    web_02 = {
      id         = aws_instance.web_02.id
      public_ip  = aws_instance.web_02.public_ip
      private_ip = aws_instance.web_02.private_ip
      security   = "INSECURE"
    }
    app_01 = {
      id         = aws_instance.app_01.id
      private_ip = aws_instance.app_01.private_ip
      security   = "secure"
    }
    app_02 = {
      id         = aws_instance.app_02.id
      private_ip = aws_instance.app_02.private_ip
      security   = "INSECURE"
    }
    db_01 = {
      id         = aws_instance.db_01.id
      private_ip = aws_instance.db_01.private_ip
      security   = "secure"
    }
    db_02 = {
      id         = aws_instance.db_02.id
      public_ip  = aws_instance.db_02.public_ip
      private_ip = aws_instance.db_02.private_ip
      security   = "INSECURE"
    }
    cache_01 = {
      id         = aws_instance.cache_01.id
      private_ip = aws_instance.cache_01.private_ip
      security   = "secure"
    }
    monitor_01 = {
      id         = aws_instance.monitor_01.id
      private_ip = aws_instance.monitor_01.private_ip
      security   = "INSECURE"
    }
    backup_01 = {
      id         = aws_instance.backup_01.id
      private_ip = aws_instance.backup_01.private_ip
      security   = "secure"
    }
  }
}

# -------------------------------------------
# S3 Bucket Outputs
# -------------------------------------------
output "s3_buckets" {
  description = "S3 bucket details"
  value = {
    terraform_state = {
      name     = aws_s3_bucket.terraform_state.id
      arn      = aws_s3_bucket.terraform_state.arn
      security = "secure"
    }
    logs = {
      name     = aws_s3_bucket.logs.id
      arn      = aws_s3_bucket.logs.arn
      security = "secure"
    }
    data_insecure = {
      name     = aws_s3_bucket.data_insecure.id
      arn      = aws_s3_bucket.data_insecure.arn
      security = "INSECURE"
    }
    backup_insecure = {
      name     = aws_s3_bucket.backup_insecure.id
      arn      = aws_s3_bucket.backup_insecure.arn
      security = "INSECURE"
    }
  }
}

# -------------------------------------------
# Security Summary
# -------------------------------------------
output "security_summary" {
  description = "Summary of secure vs insecure resources"
  value = {
    total_instances     = 10
    secure_instances    = 6
    insecure_instances  = 4
    total_s3_buckets    = 4
    secure_buckets      = 2
    insecure_buckets    = 2
    insecure_resources  = [
      "cloud-sentinel-web-02 (open SSH, unencrypted EBS)",
      "cloud-sentinel-app-02 (IMDSv1, unencrypted EBS)",
      "cloud-sentinel-db-02 (public IP, unencrypted EBS)",
      "cloud-sentinel-monitor-01 (IMDSv1, unencrypted EBS)",
      "S3: data-insecure (no encryption, public access)",
      "S3: backup-insecure (no encryption, no versioning)",
      "IAM: ec2-insecure-role (wildcard permissions)",
      "IAM: admin-insecure-role (full admin access)"
    ]
  }
}
