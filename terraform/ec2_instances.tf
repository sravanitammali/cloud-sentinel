# ===========================================
# CLOUD SENTINEL - EC2 Instances (10 Total)
# ===========================================

# -------------------------------------------
# 1. Control Node (DevOps Workstation)
# -------------------------------------------
resource "aws_instance" "control" {
  ami                    = var.ec2_ami_id
  instance_type          = var.ec2_instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.control_secure.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name         = "cloud-sentinel-control"
    Role         = "control"
    SecurityType = "secure"
  }
}

# -------------------------------------------
# 2. Web Server 01 (Secure)
# -------------------------------------------
resource "aws_instance" "web_01" {
  ami                    = var.ec2_ami_id
  instance_type          = var.ec2_instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.web_secure.id]

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name         = "cloud-sentinel-web-01"
    Role         = "web"
    SecurityType = "secure"
  }
}

# -------------------------------------------
# 3. Web Server 02 (INSECURE - For Demo)
# CHECKOV WILL FLAG: Unencrypted EBS
# -------------------------------------------
resource "aws_instance" "web_02" {
  ami                    = var.ec2_ami_id
  instance_type          = var.ec2_instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.public[1].id
  vpc_security_group_ids = [aws_security_group.web_insecure.id]

  # VULNERABILITY: EBS not encrypted!
  root_block_device {
    volume_size = 10
    volume_type = "gp3"
    encrypted   = false # INSECURE!
  }

  tags = {
    Name         = "cloud-sentinel-web-02"
    Role         = "web"
    SecurityType = "insecure"
    Warning      = "INTENTIONALLY_INSECURE_FOR_DEMO"
  }
}

# -------------------------------------------
# 4. App Server 01 (Secure)
# -------------------------------------------
resource "aws_instance" "app_01" {
  ami                    = var.ec2_ami_id
  instance_type          = var.ec2_instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.app_secure.id]

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens   = "required" # IMDSv2 required - secure
    http_endpoint = "enabled"
  }

  tags = {
    Name         = "cloud-sentinel-app-01"
    Role         = "app"
    SecurityType = "secure"
  }
}

# -------------------------------------------
# 5. App Server 02 (INSECURE - For Demo)
# CHECKOV WILL FLAG: IMDSv1 enabled, no encryption
# -------------------------------------------
resource "aws_instance" "app_02" {
  ami                    = var.ec2_ami_id
  instance_type          = var.ec2_instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.private[1].id
  vpc_security_group_ids = [aws_security_group.app_insecure.id]

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
    encrypted   = false # INSECURE!
  }

  # VULNERABILITY: IMDSv1 allowed (vulnerable to SSRF)
  metadata_options {
    http_tokens   = "optional" # INSECURE - allows IMDSv1
    http_endpoint = "enabled"
  }

  tags = {
    Name         = "cloud-sentinel-app-02"
    Role         = "app"
    SecurityType = "insecure"
    Warning      = "INTENTIONALLY_INSECURE_FOR_DEMO"
  }
}

# -------------------------------------------
# 6. Database Server 01 (Secure)
# -------------------------------------------
resource "aws_instance" "db_01" {
  ami                    = var.ec2_ami_id
  instance_type          = var.ec2_instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.db_secure.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name         = "cloud-sentinel-db-01"
    Role         = "database"
    SecurityType = "secure"
  }
}

# -------------------------------------------
# 7. Database Server 02 (INSECURE - For Demo)
# CHECKOV WILL FLAG: Public IP, no encryption
# -------------------------------------------
resource "aws_instance" "db_02" {
  ami                         = var.ec2_ami_id
  instance_type               = var.ec2_instance_type
  key_name                    = var.key_pair_name
  subnet_id                   = aws_subnet.public[0].id # INSECURE: DB in public subnet!
  vpc_security_group_ids      = [aws_security_group.db_insecure.id]
  associate_public_ip_address = true # INSECURE: Public IP for DB!

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = false # INSECURE!
  }

  tags = {
    Name         = "cloud-sentinel-db-02"
    Role         = "database"
    SecurityType = "insecure"
    Warning      = "INTENTIONALLY_INSECURE_FOR_DEMO"
  }
}

# -------------------------------------------
# 8. Cache Server 01 (Secure)
# -------------------------------------------
resource "aws_instance" "cache_01" {
  ami                    = var.ec2_ami_id
  instance_type          = var.ec2_instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.internal_secure.id]

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name         = "cloud-sentinel-cache-01"
    Role         = "cache"
    SecurityType = "secure"
  }
}

# -------------------------------------------
# 9. Monitoring Server 01 (INSECURE - For Demo)
# CHECKOV WILL FLAG: Multiple issues
# -------------------------------------------
resource "aws_instance" "monitor_01" {
  ami                    = var.ec2_ami_id
  instance_type          = var.ec2_instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.private[1].id
  vpc_security_group_ids = [aws_security_group.internal_insecure.id]

  root_block_device {
    volume_size = 15
    volume_type = "gp3"
    encrypted   = false # INSECURE!
  }

  metadata_options {
    http_tokens   = "optional" # INSECURE!
    http_endpoint = "enabled"
  }

  tags = {
    Name         = "cloud-sentinel-monitor-01"
    Role         = "monitoring"
    SecurityType = "insecure"
    Warning      = "INTENTIONALLY_INSECURE_FOR_DEMO"
  }
}

# -------------------------------------------
# 10. Backup Server 01 (Secure)
# -------------------------------------------
resource "aws_instance" "backup_01" {
  ami                    = var.ec2_ami_id
  instance_type          = var.ec2_instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.internal_secure.id]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name         = "cloud-sentinel-backup-01"
    Role         = "backup"
    SecurityType = "secure"
  }
}
