#!/usr/bin/env python3
"""
CLOUD SENTINEL - View Scan Results
Query and display scan results from SQLite database
"""

import sys
import os
from pathlib import Path

# Add scanner directory to path
sys.path.insert(0, str(Path(__file__).parent.parent / 'scanner'))

from database import Database
from tabulate import tabulate


def print_header(title: str):
    """Print a formatted header"""
    print("\n" + "=" * 60)
    print(f"  {title}")
    print("=" * 60)


def view_recent_scans(db: Database, limit: int = 10):
    """View recent scans"""
    print_header("Recent Scans")
    
    scans = db.get_recent_scans(limit)
    
    if not scans:
        print("No scans found.")
        return
    
    table_data = []
    for scan in scans:
        status_icon = "✓" if scan['status'] == 'completed' else "✗"
        blocked_icon = "🚫" if scan['blocked_deployment'] else "✅"
        
        table_data.append([
            scan['scan_id'][:20] + "...",
            scan['timestamp'],
            f"{status_icon} {scan['status']}",
            scan['passed_checks'],
            scan['failed_checks'],
            blocked_icon
        ])
    
    headers = ["Scan ID", "Timestamp", "Status", "Passed", "Failed", "Blocked"]
    print(tabulate(table_data, headers=headers, tablefmt="grid"))


def view_violations(db: Database, scan_id: str = None):
    """View violations for a scan"""
    print_header("Violations")
    
    if scan_id:
        violations = db.get_violations(scan_id)
        print(f"Scan: {scan_id}\n")
    else:
        # Get latest scan
        scans = db.get_recent_scans(1)
        if not scans:
            print("No scans found.")
            return
        scan_id = scans[0]['scan_id']
        violations = db.get_violations(scan_id)
        print(f"Latest Scan: {scan_id}\n")
    
    if not violations:
        print("No violations found.")
        return
    
    # Group by severity
    by_severity = {}
    for v in violations:
        sev = v['severity']
        if sev not in by_severity:
            by_severity[sev] = []
        by_severity[sev].append(v)
    
    for severity in ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW']:
        if severity in by_severity:
            print(f"\n[{severity}] - {len(by_severity[severity])} issues")
            print("-" * 40)
            
            for v in by_severity[severity]:
                print(f"  • {v['check_id']}: {v['check_name']}")
                print(f"    Resource: {v['resource_name']}")
                print(f"    File: {v['file_path']}:{v['file_line']}")
                print()


def view_statistics(db: Database):
    """View overall statistics"""
    print_header("Statistics")
    
    stats = db.get_statistics()
    
    print(f"Total Scans: {stats['total_scans']}")
    print(f"Total Violations: {stats['total_violations']}")
    print(f"Blocked Deployments: {stats['blocked_deployments']}")
    
    print("\nViolations by Severity:")
    for severity, count in stats['violations_by_severity'].items():
        print(f"  {severity}: {count}")


def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description='View Cloud Sentinel scan results')
    parser.add_argument('command', choices=['scans', 'violations', 'stats'],
                       help='What to view')
    parser.add_argument('--scan-id', type=str, help='Specific scan ID')
    parser.add_argument('--limit', type=int, default=10, help='Number of results')
    
    args = parser.parse_args()
    
    # Initialize database
    db = Database()
    
    if args.command == 'scans':
        view_recent_scans(db, args.limit)
    elif args.command == 'violations':
        view_violations(db, args.scan_id)
    elif args.command == 'stats':
        view_statistics(db)


if __name__ == '__main__':
    try:
        from tabulate import tabulate
    except ImportError:
        print("Installing tabulate...")
        os.system('pip3 install tabulate')
        from tabulate import tabulate
    
    main()
