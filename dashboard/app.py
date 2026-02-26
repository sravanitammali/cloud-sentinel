#!/usr/bin/env python3
"""
Cloud Sentinel - Web Dashboard
Real-time security monitoring dashboard
"""

from flask import Flask, render_template, jsonify, request
from flask_cors import CORS
import sys
from pathlib import Path
import json
from datetime import datetime, timedelta

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent / 'scanner'))

from database import Database

app = Flask(__name__)
CORS(app)

db = Database()


@app.route('/')
def index():
    """Main dashboard page"""
    return render_template('dashboard.html')


@app.route('/api/summary')
def get_summary():
    """Get scan summary statistics"""
    try:
        with db.get_connection() as conn:
            cursor = conn.cursor()
            
            # Check if violations table exists
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='violations'")
            if not cursor.fetchone():
                return jsonify({
                    'total_violations': 0,
                    'by_severity': {},
                    'by_framework': {},
                    'recent_scans': 0,
                    'last_updated': datetime.now().isoformat()
                })
            
            # Total violations
            cursor.execute("SELECT COUNT(*) FROM violations")
            total = cursor.fetchone()[0]
            
            # By severity
            cursor.execute("""
                SELECT severity, COUNT(*) 
                FROM violations 
                GROUP BY severity
            """)
            by_severity = dict(cursor.fetchall())
            
            # By framework (check if column exists first)
            try:
                cursor.execute("""
                    SELECT framework, COUNT(*) 
                    FROM violations 
                    GROUP BY framework
                """)
                by_framework = dict(cursor.fetchall())
            except:
                # Framework column doesn't exist yet, use default
                by_framework = {'terraform': total}
            
            # Recent scans
            cursor.execute("""
                SELECT COUNT(DISTINCT scan_id) 
                FROM violations 
                WHERE timestamp > datetime('now', '-7 days')
            """)
            recent_scans = cursor.fetchone()[0] if total > 0 else 0
            
            return jsonify({
                'total_violations': total,
                'by_severity': by_severity,
                'by_framework': by_framework,
                'recent_scans': recent_scans,
                'last_updated': datetime.now().isoformat()
            })
    except Exception as e:
        return jsonify({
            'error': str(e),
            'total_violations': 0,
            'by_severity': {},
            'by_framework': {},
            'recent_scans': 0,
            'last_updated': datetime.now().isoformat()
        }), 200  # Return 200 with error message instead of 500


@app.route('/api/violations')
def get_violations():
    """Get recent violations"""
    try:
        limit = request.args.get('limit', 50, type=int)
        framework = request.args.get('framework', None)
        
        with db.get_connection() as conn:
            cursor = conn.cursor()
            
            # Check if violations table exists
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='violations'")
            if not cursor.fetchone():
                return jsonify([])
            
            # Check if framework column exists
            cursor.execute("PRAGMA table_info(violations)")
            columns_info = cursor.fetchall()
            has_framework = any(col[1] == 'framework' for col in columns_info)
            
            query = "SELECT * FROM violations"
            params = []
            
            if framework and has_framework:
                query += " WHERE framework = ?"
                params.append(framework)
            
            query += " ORDER BY timestamp DESC LIMIT ?"
            params.append(limit)
            
            cursor.execute(query, params)
            
            columns = [desc[0] for desc in cursor.description]
            violations = [dict(zip(columns, row)) for row in cursor.fetchall()]
            
            return jsonify(violations)
    except Exception as e:
        return jsonify({'error': str(e), 'violations': []}), 200


@app.route('/api/trends')
def get_trends():
    """Get violation trends over time"""
    try:
        days = request.args.get('days', 7, type=int)
        
        conn = db.get_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT DATE(timestamp) as date, COUNT(*) as count
            FROM violations
            WHERE timestamp > datetime('now', ? || ' days')
            GROUP BY DATE(timestamp)
            ORDER BY date
        """, (f'-{days}',))
        
        trends = [{'date': row[0], 'count': row[1]} for row in cursor.fetchall()]
        
        conn.close()
        
        return jsonify(trends)
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/scan', methods=['POST'])
def trigger_scan():
    """Trigger a new security scan"""
    try:
        import subprocess
        import shutil
        
        # Check if checkov is installed
        if not shutil.which('checkov'):
            return jsonify({
                'status': 'error',
                'message': 'Checkov not installed. Install with: pip install checkov',
                'output': 'Please install Checkov first:\n  pip install checkov\n  OR\n  pip3 install checkov'
            }), 200
        
        # Run enhanced scanner
        result = subprocess.run(
            ['python', 'scanner/enhanced_scan.py'],
            capture_output=True,
            text=True,
            timeout=300
        )
        
        return jsonify({
            'status': 'success' if result.returncode == 0 else 'error',
            'message': 'Scan completed successfully!' if result.returncode == 0 else 'Scan failed - check output',
            'output': result.stdout + '\n' + result.stderr
        })
    except subprocess.TimeoutExpired:
        return jsonify({
            'status': 'error',
            'message': 'Scan timeout (>5 minutes)',
            'output': 'Scan took too long and was cancelled'
        }), 200
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': f'Error: {str(e)}',
            'output': str(e)
        }), 200


@app.route('/api/pipeline', methods=['POST'])
def trigger_pipeline():
    """Trigger full DevSecOps pipeline"""
    try:
        import subprocess
        
        # Run full pipeline
        result = subprocess.run(
            ['python', 'scanner/pipeline.py'],
            capture_output=True,
            text=True,
            timeout=600  # 10 minutes
        )
        
        return jsonify({
            'status': 'success' if result.returncode == 0 else 'error',
            'message': 'Pipeline completed! Check your email for reports.' if result.returncode == 0 else 'Pipeline failed',
            'output': result.stdout + '\n' + result.stderr
        })
    except subprocess.TimeoutExpired:
        return jsonify({
            'status': 'error',
            'message': 'Pipeline timeout (>10 minutes)',
            'output': 'Pipeline took too long and was cancelled'
        }), 200
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': f'Error: {str(e)}',
            'output': str(e)
        }), 200


if __name__ == '__main__':
    print("🚀 Starting Cloud Sentinel Dashboard...")
    print("📊 Dashboard available at: http://localhost:5000")
    app.run(debug=True, host='0.0.0.0', port=5000)
