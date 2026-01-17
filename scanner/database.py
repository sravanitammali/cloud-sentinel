"""
CLOUD SENTINEL - Database Module
SQLite database for storing scan results and audit logs
"""

import sqlite3
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Optional, Any
from contextlib import contextmanager

from config import Config


class Database:
    """SQLite database handler for scan results"""
    
    def __init__(self, db_path: Optional[Path] = None):
        self.db_path = db_path or Config.get_db_path()
        self._init_database()
    
    @contextmanager
    def get_connection(self):
        """Context manager for database connections"""
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        try:
            yield conn
            conn.commit()
        except Exception as e:
            conn.rollback()
            raise e
        finally:
            conn.close()
    
    def _init_database(self):
        """Initialize database schema"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            
            # Scans table - stores each scan run
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS scans (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    scan_id TEXT UNIQUE NOT NULL,
                    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                    status TEXT NOT NULL,
                    total_checks INTEGER DEFAULT 0,
                    passed_checks INTEGER DEFAULT 0,
                    failed_checks INTEGER DEFAULT 0,
                    skipped_checks INTEGER DEFAULT 0,
                    commit_hash TEXT,
                    branch TEXT,
                    triggered_by TEXT,
                    duration_seconds REAL,
                    blocked_deployment BOOLEAN DEFAULT FALSE
                )
            ''')
            
            # Violations table - stores individual violations
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS violations (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    scan_id TEXT NOT NULL,
                    check_id TEXT NOT NULL,
                    check_name TEXT,
                    severity TEXT,
                    resource_type TEXT,
                    resource_name TEXT,
                    file_path TEXT,
                    file_line INTEGER,
                    guideline TEXT,
                    description TEXT,
                    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                    remediated BOOLEAN DEFAULT FALSE,
                    remediation_date DATETIME,
                    FOREIGN KEY (scan_id) REFERENCES scans(scan_id)
                )
            ''')
            
            # Resources table - tracks scanned resources
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS resources (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    scan_id TEXT NOT NULL,
                    resource_type TEXT NOT NULL,
                    resource_name TEXT NOT NULL,
                    file_path TEXT,
                    security_status TEXT,
                    check_count INTEGER DEFAULT 0,
                    violation_count INTEGER DEFAULT 0,
                    FOREIGN KEY (scan_id) REFERENCES scans(scan_id)
                )
            ''')
            
            # Audit log table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS audit_log (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                    action TEXT NOT NULL,
                    details TEXT,
                    user TEXT,
                    scan_id TEXT
                )
            ''')
            
            # Create indexes for better query performance
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_violations_scan_id ON violations(scan_id)')
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_violations_severity ON violations(severity)')
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_scans_timestamp ON scans(timestamp)')
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_resources_scan_id ON resources(scan_id)')
    
    def create_scan(self, scan_id: str, commit_hash: str = None, 
                    branch: str = None, triggered_by: str = None) -> str:
        """Create a new scan record"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO scans (scan_id, status, commit_hash, branch, triggered_by)
                VALUES (?, 'running', ?, ?, ?)
            ''', (scan_id, commit_hash, branch, triggered_by))
            
            self._log_audit(conn, 'SCAN_STARTED', f'Scan {scan_id} started', scan_id=scan_id)
        
        return scan_id
    
    def update_scan(self, scan_id: str, status: str, total_checks: int,
                    passed_checks: int, failed_checks: int, skipped_checks: int,
                    duration_seconds: float, blocked_deployment: bool = False):
        """Update scan with results"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                UPDATE scans 
                SET status = ?, total_checks = ?, passed_checks = ?,
                    failed_checks = ?, skipped_checks = ?, duration_seconds = ?,
                    blocked_deployment = ?
                WHERE scan_id = ?
            ''', (status, total_checks, passed_checks, failed_checks, 
                  skipped_checks, duration_seconds, blocked_deployment, scan_id))
            
            action = 'SCAN_COMPLETED' if status == 'completed' else 'SCAN_FAILED'
            self._log_audit(conn, action, 
                          f'Scan {scan_id}: {passed_checks} passed, {failed_checks} failed',
                          scan_id=scan_id)
    
    def add_violation(self, scan_id: str, violation: Dict[str, Any]):
        """Add a violation record"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO violations 
                (scan_id, check_id, check_name, severity, resource_type,
                 resource_name, file_path, file_line, guideline, description)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                scan_id,
                violation.get('check_id', ''),
                violation.get('check_name', ''),
                violation.get('severity', 'MEDIUM'),
                violation.get('resource_type', ''),
                violation.get('resource_name', ''),
                violation.get('file_path', ''),
                violation.get('file_line', 0),
                violation.get('guideline', ''),
                violation.get('description', '')
            ))
    
    def add_violations_batch(self, scan_id: str, violations: List[Dict[str, Any]]):
        """Add multiple violations in a batch"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            for violation in violations:
                cursor.execute('''
                    INSERT INTO violations 
                    (scan_id, check_id, check_name, severity, resource_type,
                     resource_name, file_path, file_line, guideline, description)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ''', (
                    scan_id,
                    violation.get('check_id', ''),
                    violation.get('check_name', ''),
                    violation.get('severity', 'MEDIUM'),
                    violation.get('resource_type', ''),
                    violation.get('resource_name', ''),
                    violation.get('file_path', ''),
                    violation.get('file_line', 0),
                    violation.get('guideline', ''),
                    violation.get('description', '')
                ))
    
    def add_resource(self, scan_id: str, resource: Dict[str, Any]):
        """Add a scanned resource record"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO resources 
                (scan_id, resource_type, resource_name, file_path, 
                 security_status, check_count, violation_count)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (
                scan_id,
                resource.get('resource_type', ''),
                resource.get('resource_name', ''),
                resource.get('file_path', ''),
                resource.get('security_status', 'unknown'),
                resource.get('check_count', 0),
                resource.get('violation_count', 0)
            ))
    
    def get_scan(self, scan_id: str) -> Optional[Dict]:
        """Get scan details by ID"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('SELECT * FROM scans WHERE scan_id = ?', (scan_id,))
            row = cursor.fetchone()
            return dict(row) if row else None
    
    def get_violations(self, scan_id: str, severity: str = None) -> List[Dict]:
        """Get violations for a scan, optionally filtered by severity"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            if severity:
                cursor.execute(
                    'SELECT * FROM violations WHERE scan_id = ? AND severity = ?',
                    (scan_id, severity)
                )
            else:
                cursor.execute(
                    'SELECT * FROM violations WHERE scan_id = ?',
                    (scan_id,)
                )
            return [dict(row) for row in cursor.fetchall()]
    
    def get_recent_scans(self, limit: int = 10) -> List[Dict]:
        """Get recent scans"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                'SELECT * FROM scans ORDER BY timestamp DESC LIMIT ?',
                (limit,)
            )
            return [dict(row) for row in cursor.fetchall()]
    
    def get_violation_summary(self, scan_id: str) -> Dict[str, int]:
        """Get violation count by severity for a scan"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                SELECT severity, COUNT(*) as count 
                FROM violations 
                WHERE scan_id = ? 
                GROUP BY severity
            ''', (scan_id,))
            return {row['severity']: row['count'] for row in cursor.fetchall()}
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get overall statistics"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            
            # Total scans
            cursor.execute('SELECT COUNT(*) as count FROM scans')
            total_scans = cursor.fetchone()['count']
            
            # Total violations
            cursor.execute('SELECT COUNT(*) as count FROM violations')
            total_violations = cursor.fetchone()['count']
            
            # Violations by severity
            cursor.execute('''
                SELECT severity, COUNT(*) as count 
                FROM violations 
                GROUP BY severity
            ''')
            by_severity = {row['severity']: row['count'] for row in cursor.fetchall()}
            
            # Blocked deployments
            cursor.execute('SELECT COUNT(*) as count FROM scans WHERE blocked_deployment = 1')
            blocked_deployments = cursor.fetchone()['count']
            
            return {
                'total_scans': total_scans,
                'total_violations': total_violations,
                'violations_by_severity': by_severity,
                'blocked_deployments': blocked_deployments
            }
    
    def _log_audit(self, conn, action: str, details: str, 
                   user: str = 'system', scan_id: str = None):
        """Log an audit entry"""
        cursor = conn.cursor()
        cursor.execute('''
            INSERT INTO audit_log (action, details, user, scan_id)
            VALUES (?, ?, ?, ?)
        ''', (action, details, user, scan_id))


# Create singleton instance
db = Database()
