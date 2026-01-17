"""
CLOUD SENTINEL - Configuration Module
Loads configuration from environment variables and .env file
"""

import os
from pathlib import Path
from dotenv import load_dotenv

# Load .env file from project root
env_path = Path(__file__).parent.parent / '.env'
load_dotenv(env_path)


class Config:
    """Configuration class for Cloud Sentinel"""
    
    # Project Settings
    PROJECT_NAME = os.getenv('PROJECT_NAME', 'cloud-sentinel')
    ENVIRONMENT = os.getenv('ENVIRONMENT', 'dev')
    
    # AWS Settings
    AWS_REGION = os.getenv('AWS_REGION', 'ap-south-1')
    AWS_ACCESS_KEY_ID = os.getenv('AWS_ACCESS_KEY_ID', '')
    AWS_SECRET_ACCESS_KEY = os.getenv('AWS_SECRET_ACCESS_KEY', '')
    
    # Database Settings
    SQLITE_DB_PATH = os.getenv('SQLITE_DB_PATH', './data/scan_results.db')
    
    # GitHub Settings
    GITHUB_REPO_URL = os.getenv('GITHUB_REPO_URL', '')
    GITHUB_TOKEN = os.getenv('GITHUB_TOKEN', '')
    
    # Alert Settings
    ALERT_EMAIL = os.getenv('ALERT_EMAIL', '')
    
    # Author Settings
    AUTHOR_NAME = os.getenv('AUTHOR_NAME', 'Cloud Sentinel')
    AUTHOR_EMAIL = os.getenv('AUTHOR_EMAIL', '')
    
    # Scanner Settings
    TERRAFORM_DIR = os.getenv('TERRAFORM_DIR', './terraform')
    CHECKOV_OUTPUT_DIR = os.getenv('CHECKOV_OUTPUT_DIR', './checkov_results')
    
    # Severity Levels
    SEVERITY_LEVELS = {
        'CRITICAL': 4,
        'HIGH': 3,
        'MEDIUM': 2,
        'LOW': 1,
        'INFO': 0
    }
    
    # Block deployment if critical issues found
    BLOCK_ON_CRITICAL = True
    BLOCK_ON_HIGH = True
    
    @classmethod
    def get_db_path(cls) -> Path:
        """Get database path, creating directory if needed"""
        db_path = Path(cls.SQLITE_DB_PATH)
        db_path.parent.mkdir(parents=True, exist_ok=True)
        return db_path
    
    @classmethod
    def get_terraform_dir(cls) -> Path:
        """Get Terraform directory path"""
        return Path(cls.TERRAFORM_DIR)
    
    @classmethod
    def get_checkov_output_dir(cls) -> Path:
        """Get Checkov output directory, creating if needed"""
        output_dir = Path(cls.CHECKOV_OUTPUT_DIR)
        output_dir.mkdir(parents=True, exist_ok=True)
        return output_dir
    
    @classmethod
    def validate(cls) -> list:
        """Validate configuration and return list of warnings"""
        warnings = []
        
        if not cls.AWS_ACCESS_KEY_ID or cls.AWS_ACCESS_KEY_ID == 'your_aws_access_key_here':
            warnings.append("AWS_ACCESS_KEY_ID not configured")
        
        if not cls.AWS_SECRET_ACCESS_KEY or cls.AWS_SECRET_ACCESS_KEY == 'your_aws_secret_key_here':
            warnings.append("AWS_SECRET_ACCESS_KEY not configured")
        
        if not cls.GITHUB_TOKEN or cls.GITHUB_TOKEN == 'ghp_your_github_token_here':
            warnings.append("GITHUB_TOKEN not configured")
        
        return warnings


# Create singleton instance
config = Config()
