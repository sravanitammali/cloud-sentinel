# ===========================================
# CLOUD SENTINEL - Security Groups
# ===========================================
# Some security groups are INTENTIONALLY INSECURE
# for demonstration purposes. Checkov will catch these!

# -------------------------------------------
# SECURE: Control Node Security Group
# -------------------------------------------
resource "aws_security_group" "control_secure" {
  name        = "${var.project_name}-control-sg"
  description = "Security group for control node - SECURE"
  vpc_id      = aws_vpc.main.id

  # SSH from specific IP only (placeholder - update with your IP)
  ingress {
    description = "SSH from admin IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # TODO: Replace with your IP
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name         = "${var.project_name}-control-sg"
    SecurityType = "secure"
  }
}

# -------------------------------------------
# SECURE: Web Server Security Group
# -------------------------------------------
resource "aws_security_group" "web_secure" {
  name        = "${var.project_name}-web-secure-sg"
  description = "Security group for web servers - SECURE"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "SSH from control node only"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.control_secure.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name         = "${var.project_name}-web-secure-sg"
    SecurityType = "secure"
  }
}

# -------------------------------------------
# INSECURE: Web Server Security Group
# CHECKOV WILL FLAG THIS!
# -------------------------------------------
# checkov:skip=CKV_AWS_260: Intentionally insecure for demo
# checkov:skip=CKV_AWS_24: Intentionally insecure for demo
resource "aws_security_group" "web_insecure" {
  name        = "${var.project_name}-web-insecure-sg"
  description = "INSECURE security group for demo - SSH open to world"
  vpc_id      = aws_vpc.main.id

  # VULNERABILITY: SSH open to the entire internet!
  ingress {
    description = "SSH from anywhere - INSECURE!"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # VULNERABILITY: All ports open!
  ingress {
    description = "All traffic - INSECURE!"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name         = "${var.project_name}-web-insecure-sg"
    SecurityType = "insecure"
    Warning      = "INTENTIONALLY_INSECURE_FOR_DEMO"
  }
}

# -------------------------------------------
# SECURE: App Server Security Group
# -------------------------------------------
resource "aws_security_group" "app_secure" {
  name        = "${var.project_name}-app-secure-sg"
  description = "Security group for app servers - SECURE"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "App port from web servers"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web_secure.id]
  }

  ingress {
    description     = "SSH from control node only"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.control_secure.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name         = "${var.project_name}-app-secure-sg"
    SecurityType = "secure"
  }
}

# -------------------------------------------
# INSECURE: App Server Security Group
# CHECKOV WILL FLAG THIS!
# -------------------------------------------
resource "aws_security_group" "app_insecure" {
  name        = "${var.project_name}-app-insecure-sg"
  description = "INSECURE security group for demo"
  vpc_id      = aws_vpc.main.id

  # VULNERABILITY: Database port open to internet!
  ingress {
    description = "MySQL from anywhere - INSECURE!"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from anywhere - INSECURE!"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name         = "${var.project_name}-app-insecure-sg"
    SecurityType = "insecure"
    Warning      = "INTENTIONALLY_INSECURE_FOR_DEMO"
  }
}

# -------------------------------------------
# SECURE: Database Security Group
# -------------------------------------------
resource "aws_security_group" "db_secure" {
  name        = "${var.project_name}-db-secure-sg"
  description = "Security group for database servers - SECURE"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from app servers only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_secure.id]
  }

  ingress {
    description     = "SSH from control node only"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.control_secure.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name         = "${var.project_name}-db-secure-sg"
    SecurityType = "secure"
  }
}

# -------------------------------------------
# INSECURE: Database Security Group
# CHECKOV WILL FLAG THIS!
# -------------------------------------------
resource "aws_security_group" "db_insecure" {
  name        = "${var.project_name}-db-insecure-sg"
  description = "INSECURE security group for demo - DB open to world"
  vpc_id      = aws_vpc.main.id

  # VULNERABILITY: Database accessible from internet!
  ingress {
    description = "MySQL from anywhere - INSECURE!"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # VULNERABILITY: PostgreSQL accessible from internet!
  ingress {
    description = "PostgreSQL from anywhere - INSECURE!"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from anywhere - INSECURE!"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name         = "${var.project_name}-db-insecure-sg"
    SecurityType = "insecure"
    Warning      = "INTENTIONALLY_INSECURE_FOR_DEMO"
  }
}

# -------------------------------------------
# SECURE: Internal Services Security Group
# (Cache, Monitoring, Backup)
# -------------------------------------------
resource "aws_security_group" "internal_secure" {
  name        = "${var.project_name}-internal-secure-sg"
  description = "Security group for internal services - SECURE"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Redis from VPC"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description     = "SSH from control node only"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.control_secure.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name         = "${var.project_name}-internal-secure-sg"
    SecurityType = "secure"
  }
}

# -------------------------------------------
# INSECURE: Internal Services Security Group
# CHECKOV WILL FLAG THIS!
# -------------------------------------------
resource "aws_security_group" "internal_insecure" {
  name        = "${var.project_name}-internal-insecure-sg"
  description = "INSECURE security group for demo"
  vpc_id      = aws_vpc.main.id

  # VULNERABILITY: Redis open to internet!
  ingress {
    description = "Redis from anywhere - INSECURE!"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # VULNERABILITY: Monitoring ports open!
  ingress {
    description = "Prometheus from anywhere - INSECURE!"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from anywhere - INSECURE!"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name         = "${var.project_name}-internal-insecure-sg"
    SecurityType = "insecure"
    Warning      = "INTENTIONALLY_INSECURE_FOR_DEMO"
  }
}
