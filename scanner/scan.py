"""
CLOUD SENTINEL - Main Scanner Module
Runs Checkov security scans on Terraform code
"""

import json
import subprocess
import sys
import uuid
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Any, Optional
import time

from config import Config
from database import Database
from logger import ScanLogger


class SecurityScanner:
    """Main security scanner class using Checkov"""
    
    def __init__(self):
        self.config = Config
        self.db = Database()
        self.logger = ScanLogger()
        self.scan_id = None
    
    def generate_scan_id(self) -> str:
        """Generate unique scan ID"""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        unique_id = str(uuid.uuid4())[:8]
        return f"scan_{timestamp}_{unique_id}"
    
    def run_checkov(self, terraform_dir: Path) -> Dict[str, Any]:
        """Run Checkov scan on Terraform directory"""
        output_file = self.config.get_checkov_output_dir() / f"{self.scan_id}_results.json"
        
        cmd = [
            'checkov',
            '-d', str(terraform_dir),
            '-o', 'json',
            '--output-file-path', str(output_file.parent),
            '--framework', 'terraform',
            '--compact'
        ]
        
        self.logger.info(f"Running Checkov scan on: {terraform_dir}")
        self.logger.info(f"Command: {' '.join(cmd)}")
        
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=300  # 5 minute timeout
            )
            
            # Checkov returns exit code 1 if there are failures
            # This is expected behavior, not an error
            
            # Try to read the JSON output file
            json_output_file = output_file.parent / 'results_json.json'
            if json_output_file.exists():
                with open(json_output_file, 'r') as f:
                    return json.load(f)
            
            # If no file, try to parse stdout
            if result.stdout:
                try:
                    return json.loads(result.stdout)
                except json.JSONDecodeError:
                    pass
            
            # Return empty results if nothing found
            return {'results': {'passed_checks': [], 'failed_checks': [], 'skipped_checks': []}}
            
        except subprocess.TimeoutExpired:
            self.logger.error("Checkov scan timed out")
            raise
        except FileNotFoundError:
            self.logger.error("Checkov not found. Please install it: pip install checkov")
            raise
    
    def parse_results(self, checkov_output: Dict[str, Any]) -> Dict[str, Any]:
        """Parse Checkov output into structured format"""
        results = {
            'passed': [],
            'failed': [],
            'skipped': [],
            'summary': {
                'total': 0,
                'passed': 0,
                'failed': 0,
                'skipped': 0
            }
        }
        
        # Handle different Checkov output formats
        if isinstance(checkov_output, list):
            # Multiple check types
            for check_type in checkov_output:
                self._process_check_results(check_type, results)
        elif isinstance(checkov_output, dict):
            if 'results' in checkov_output:
                self._process_check_results(checkov_output, results)
            else:
                # Single result format
                self._process_check_results({'results': checkov_output}, results)
        
        # Calculate totals
        results['summary']['passed'] = len(results['passed'])
        results['summary']['failed'] = len(results['failed'])
        results['summary']['skipped'] = len(results['skipped'])
        results['summary']['total'] = (
            results['summary']['passed'] + 
            results['summary']['failed'] + 
            results['summary']['skipped']
        )
        
        return results
    
    def _process_check_results(self, check_data: Dict, results: Dict):
        """Process individual check results"""
        if 'results' not in check_data:
            return
        
        check_results = check_data['results']
        
        # Process passed checks
        for check in check_results.get('passed_checks', []):
            results['passed'].append(self._format_check(check, 'PASSED'))
        
        # Process failed checks
        for check in check_results.get('failed_checks', []):
            results['failed'].append(self._format_check(check, 'FAILED'))
        
        # Process skipped checks
        for check in check_results.get('skipped_checks', []):
            results['skipped'].append(self._format_check(check, 'SKIPPED'))
    
    def _format_check(self, check: Dict, status: str) -> Dict[str, Any]:
        """Format a single check result"""
        # Determine severity based on check ID patterns
        severity = self._determine_severity(check.get('check_id', ''))
        
        return {
            'check_id': check.get('check_id', ''),
            'check_name': check.get('check', {}).get('name', check.get('check_id', '')),
            'status': status,
            'severity': severity,
            'resource_type': check.get('resource', '').split('.')[0] if check.get('resource') else '',
            'resource_name': check.get('resource', ''),
            'file_path': check.get('file_path', ''),
            'file_line': check.get('file_line_range', [0])[0] if check.get('file_line_range') else 0,
            'guideline': check.get('guideline', ''),
            'description': check.get('check', {}).get('name', '')
        }
    
    def _determine_severity(self, check_id: str) -> str:
        """Determine severity based on check ID"""
        # Critical checks (data exposure, admin access)
        critical_patterns = ['CKV_AWS_19', 'CKV_AWS_20', 'CKV_AWS_21', 'CKV_AWS_57']
        
        # High severity checks (encryption, public access)
        high_patterns = ['CKV_AWS_3', 'CKV_AWS_8', 'CKV_AWS_17', 'CKV_AWS_18', 
                        'CKV_AWS_23', 'CKV_AWS_24', 'CKV_AWS_25', 'CKV_AWS_260']
        
        # Medium severity checks
        medium_patterns = ['CKV_AWS_79', 'CKV_AWS_88', 'CKV_AWS_135', 'CKV_AWS_136']
        
        if any(pattern in check_id for pattern in critical_patterns):
            return 'CRITICAL'
        elif any(pattern in check_id for pattern in high_patterns):
            return 'HIGH'
        elif any(pattern in check_id for pattern in medium_patterns):
            return 'MEDIUM'
        else:
            return 'LOW'
    
    def should_block_deployment(self, results: Dict[str, Any]) -> bool:
        """Determine if deployment should be blocked based on results"""
        for violation in results['failed']:
            if violation['severity'] == 'CRITICAL' and self.config.BLOCK_ON_CRITICAL:
                return True
            if violation['severity'] == 'HIGH' and self.config.BLOCK_ON_HIGH:
                return True
        return False
    
    def scan(self, terraform_dir: Path = None, commit_hash: str = None,
             branch: str = None, triggered_by: str = 'manual') -> Dict[str, Any]:
        """Run complete security scan"""
        start_time = time.time()
        
        # Setup
        terraform_dir = terraform_dir or self.config.get_terraform_dir()
        self.scan_id = self.generate_scan_id()
        
        self.logger.info("=" * 60)
        self.logger.info("CLOUD SENTINEL - Security Scan Started")
        self.logger.info("=" * 60)
        self.logger.info(f"Scan ID: {self.scan_id}")
        self.logger.info(f"Target: {terraform_dir}")
        self.logger.info(f"Triggered by: {triggered_by}")
        
        # Create scan record in database
        self.db.create_scan(
            scan_id=self.scan_id,
            commit_hash=commit_hash,
            branch=branch,
            triggered_by=triggered_by
        )
        
        try:
            # Run Checkov
            checkov_output = self.run_checkov(terraform_dir)
            
            # Parse results
            results = self.parse_results(checkov_output)
            
            # Determine if deployment should be blocked
            blocked = self.should_block_deployment(results)
            
            # Calculate duration
            duration = time.time() - start_time
            
            # Update scan record
            self.db.update_scan(
                scan_id=self.scan_id,
                status='completed',
                total_checks=results['summary']['total'],
                passed_checks=results['summary']['passed'],
                failed_checks=results['summary']['failed'],
                skipped_checks=results['summary']['skipped'],
                duration_seconds=duration,
                blocked_deployment=blocked
            )
            
            # Store violations
            violations_to_store = [
                {
                    'check_id': v['check_id'],
                    'check_name': v['check_name'],
                    'severity': v['severity'],
                    'resource_type': v['resource_type'],
                    'resource_name': v['resource_name'],
                    'file_path': v['file_path'],
                    'file_line': v['file_line'],
                    'guideline': v['guideline'],
                    'description': v['description']
                }
                for v in results['failed']
            ]
            self.db.add_violations_batch(self.scan_id, violations_to_store)
            
            # Log results
            self._log_results(results, blocked, duration)
            
            # Return complete results
            return {
                'scan_id': self.scan_id,
                'status': 'completed',
                'blocked': blocked,
                'duration_seconds': duration,
                'summary': results['summary'],
                'violations': results['failed'],
                'passed': results['passed'],
                'skipped': results['skipped']
            }
            
        except Exception as e:
            duration = time.time() - start_time
            self.logger.error(f"Scan failed: {str(e)}")
            
            self.db.update_scan(
                scan_id=self.scan_id,
                status='failed',
                total_checks=0,
                passed_checks=0,
                failed_checks=0,
                skipped_checks=0,
                duration_seconds=duration,
                blocked_deployment=True
            )
            
            raise
    
    def _log_results(self, results: Dict, blocked: bool, duration: float):
        """Log scan results"""
        self.logger.info("")
        self.logger.info("=" * 60)
        self.logger.info("SCAN RESULTS")
        self.logger.info("=" * 60)
        self.logger.info(f"Total Checks: {results['summary']['total']}")
        self.logger.success(f"Passed: {results['summary']['passed']}")
        self.logger.error(f"Failed: {results['summary']['failed']}")
        self.logger.warning(f"Skipped: {results['summary']['skipped']}")
        self.logger.info(f"Duration: {duration:.2f} seconds")
        self.logger.info("")
        
        if results['failed']:
            self.logger.info("VIOLATIONS FOUND:")
            self.logger.info("-" * 40)
            
            # Group by severity
            by_severity = {}
            for v in results['failed']:
                sev = v['severity']
                if sev not in by_severity:
                    by_severity[sev] = []
                by_severity[sev].append(v)
            
            for severity in ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW']:
                if severity in by_severity:
                    self.logger.info(f"\n[{severity}]")
                    for v in by_severity[severity]:
                        self.logger.info(f"  - {v['check_id']}: {v['check_name']}")
                        self.logger.info(f"    Resource: {v['resource_name']}")
                        self.logger.info(f"    File: {v['file_path']}:{v['file_line']}")
        
        self.logger.info("")
        self.logger.info("=" * 60)
        if blocked:
            self.logger.error("DEPLOYMENT BLOCKED - Critical/High severity issues found!")
        else:
            self.logger.success("DEPLOYMENT ALLOWED - No blocking issues found")
        self.logger.info("=" * 60)


def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Cloud Sentinel Security Scanner')
    parser.add_argument('-d', '--directory', type=str, 
                       help='Terraform directory to scan')
    parser.add_argument('--commit', type=str, help='Git commit hash')
    parser.add_argument('--branch', type=str, help='Git branch name')
    parser.add_argument('--triggered-by', type=str, default='manual',
                       help='What triggered this scan')
    
    args = parser.parse_args()
    
    scanner = SecurityScanner()
    
    terraform_dir = Path(args.directory) if args.directory else None
    
    try:
        results = scanner.scan(
            terraform_dir=terraform_dir,
            commit_hash=args.commit,
            branch=args.branch,
            triggered_by=args.triggered_by
        )
        
        # Exit with error code if deployment blocked
        if results['blocked']:
            sys.exit(1)
        sys.exit(0)
        
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(2)


if __name__ == '__main__':
    main()
