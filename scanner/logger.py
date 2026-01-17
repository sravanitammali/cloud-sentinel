"""
CLOUD SENTINEL - Logging Module
Provides colored console output and file logging
"""

import logging
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional

from config import Config


class Colors:
    """ANSI color codes for terminal output"""
    RESET = '\033[0m'
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    BOLD = '\033[1m'


class ScanLogger:
    """Custom logger with colored output for scan results"""
    
    def __init__(self, name: str = 'cloud-sentinel', log_file: Optional[Path] = None):
        self.name = name
        self.log_file = log_file
        
        # Setup Python logger for file output
        self._setup_file_logger()
    
    def _setup_file_logger(self):
        """Setup file logger"""
        self.file_logger = logging.getLogger(self.name)
        self.file_logger.setLevel(logging.DEBUG)
        
        # Create logs directory
        logs_dir = Path('./logs')
        logs_dir.mkdir(exist_ok=True)
        
        # File handler
        log_file = self.log_file or logs_dir / f"scan_{datetime.now().strftime('%Y%m%d')}.log"
        file_handler = logging.FileHandler(log_file)
        file_handler.setLevel(logging.DEBUG)
        
        # Formatter
        formatter = logging.Formatter(
            '%(asctime)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        file_handler.setFormatter(formatter)
        
        # Add handler if not already added
        if not self.file_logger.handlers:
            self.file_logger.addHandler(file_handler)
    
    def _print(self, message: str, color: str = Colors.WHITE, bold: bool = False):
        """Print colored message to console"""
        prefix = Colors.BOLD if bold else ''
        print(f"{prefix}{color}{message}{Colors.RESET}")
    
    def info(self, message: str):
        """Log info message"""
        self._print(message, Colors.WHITE)
        self.file_logger.info(message)
    
    def success(self, message: str):
        """Log success message (green)"""
        self._print(f"✓ {message}", Colors.GREEN)
        self.file_logger.info(f"SUCCESS: {message}")
    
    def warning(self, message: str):
        """Log warning message (yellow)"""
        self._print(f"⚠ {message}", Colors.YELLOW)
        self.file_logger.warning(message)
    
    def error(self, message: str):
        """Log error message (red)"""
        self._print(f"✗ {message}", Colors.RED)
        self.file_logger.error(message)
    
    def critical(self, message: str):
        """Log critical message (red bold)"""
        self._print(f"🚨 {message}", Colors.RED, bold=True)
        self.file_logger.critical(message)
    
    def debug(self, message: str):
        """Log debug message (cyan)"""
        self._print(f"[DEBUG] {message}", Colors.CYAN)
        self.file_logger.debug(message)
    
    def header(self, message: str):
        """Log header message (blue bold)"""
        self._print(message, Colors.BLUE, bold=True)
        self.file_logger.info(message)
    
    def violation(self, severity: str, check_id: str, message: str):
        """Log a security violation with appropriate color"""
        color_map = {
            'CRITICAL': Colors.RED,
            'HIGH': Colors.RED,
            'MEDIUM': Colors.YELLOW,
            'LOW': Colors.CYAN,
            'INFO': Colors.WHITE
        }
        color = color_map.get(severity, Colors.WHITE)
        
        self._print(f"[{severity}] {check_id}: {message}", color)
        self.file_logger.warning(f"VIOLATION [{severity}] {check_id}: {message}")
    
    def scan_summary(self, passed: int, failed: int, skipped: int):
        """Log scan summary with colors"""
        total = passed + failed + skipped
        
        self._print("\n" + "=" * 50, Colors.WHITE)
        self._print("SCAN SUMMARY", Colors.BLUE, bold=True)
        self._print("=" * 50, Colors.WHITE)
        self._print(f"Total Checks: {total}", Colors.WHITE)
        self._print(f"Passed: {passed}", Colors.GREEN)
        self._print(f"Failed: {failed}", Colors.RED if failed > 0 else Colors.GREEN)
        self._print(f"Skipped: {skipped}", Colors.YELLOW)
        self._print("=" * 50 + "\n", Colors.WHITE)
        
        self.file_logger.info(f"SCAN SUMMARY - Total: {total}, Passed: {passed}, Failed: {failed}, Skipped: {skipped}")
    
    def deployment_status(self, blocked: bool, reason: str = ""):
        """Log deployment status"""
        if blocked:
            self._print("\n" + "!" * 50, Colors.RED)
            self._print("🚫 DEPLOYMENT BLOCKED", Colors.RED, bold=True)
            if reason:
                self._print(f"Reason: {reason}", Colors.RED)
            self._print("!" * 50 + "\n", Colors.RED)
            self.file_logger.error(f"DEPLOYMENT BLOCKED: {reason}")
        else:
            self._print("\n" + "=" * 50, Colors.GREEN)
            self._print("✅ DEPLOYMENT ALLOWED", Colors.GREEN, bold=True)
            self._print("=" * 50 + "\n", Colors.GREEN)
            self.file_logger.info("DEPLOYMENT ALLOWED")


# Create singleton instance
logger = ScanLogger()
