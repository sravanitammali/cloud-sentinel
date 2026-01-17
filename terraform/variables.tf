# ===========================================
# CLOUD SENTINEL - Terraform Variables
# ===========================================

# -------------------------------------------
# AWS Configuration
# -------------------------------------------
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-south-1"
}

# -------------------------------------------
# Project Configuration
# -------------------------------------------
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "cloud-sentinel"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# -------------------------------------------
# EC2 Configuration
# -------------------------------------------
variable "ec2_ami_id" {
  description = "AMI ID for EC2 instances (Ubuntu 22.04 LTS)"
  type        = string
  default     = "ami-0ff91eb5c6fe7cc86" # Ubuntu 22.04 in ap-south-1 (latest)
}

variable "ec2_instance_type" {
  description = "Instance type for EC2"
  type        = string
  default     = "t2.micro"
}

variable "key_pair_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "cloud-sentinel-key"
}

# -------------------------------------------
# Network Configuration
# -------------------------------------------
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

# -------------------------------------------
# Instance Configuration
# -------------------------------------------
variable "instances" {
  description = "Map of EC2 instances to create"
  type = map(object({
    name          = string
    role          = string
    subnet_type   = string
    security_type = string
  }))
  default = {
    control = {
      name          = "cloud-sentinel-control"
      role          = "control"
      subnet_type   = "public"
      security_type = "secure"
    }
    web_01 = {
      name          = "cloud-sentinel-web-01"
      role          = "web"
      subnet_type   = "public"
      security_type = "secure"
    }
    web_02 = {
      name          = "cloud-sentinel-web-02"
      role          = "web"
      subnet_type   = "public"
      security_type = "insecure" # Intentionally insecure for demo
    }
    app_01 = {
      name          = "cloud-sentinel-app-01"
      role          = "app"
      subnet_type   = "private"
      security_type = "secure"
    }
    app_02 = {
      name          = "cloud-sentinel-app-02"
      role          = "app"
      subnet_type   = "private"
      security_type = "insecure" # Intentionally insecure for demo
    }
    db_01 = {
      name          = "cloud-sentinel-db-01"
      role          = "database"
      subnet_type   = "private"
      security_type = "secure"
    }
    db_02 = {
      name          = "cloud-sentinel-db-02"
      role          = "database"
      subnet_type   = "private"
      security_type = "insecure" # Intentionally insecure for demo
    }
    cache_01 = {
      name          = "cloud-sentinel-cache-01"
      role          = "cache"
      subnet_type   = "private"
      security_type = "secure"
    }
    monitor_01 = {
      name          = "cloud-sentinel-monitor-01"
      role          = "monitoring"
      subnet_type   = "private"
      security_type = "insecure" # Intentionally insecure for demo
    }
    backup_01 = {
      name          = "cloud-sentinel-backup-01"
      role          = "backup"
      subnet_type   = "private"
      security_type = "secure"
    }
  }
}
