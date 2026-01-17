#!/usr/bin/env python3
"""
Quick test script to verify Checkov detects our intentional vulnerabilities
"""

import subprocess
import json
import sys
import os

def run_checkov_test():
    """Run Checkov and check if it detects expected violations"""
    
    print("🔍 Testing Checkov configuration...")
    print("=" * 50)
    
    # Change to terraform directory
    terraform_dir = "terraform"
    if not os.path.exists(terraform_dir):
        print("❌ Terraform directory not found!")
        return False
    
    try:
        # Run Checkov with JSON output
        cmd = ["checkov", "-d", terraform_dir, "-o", "json", "--compact"]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        
        if result.returncode != 0:
            print(f"⚠️  Checkov exited with code {result.returncode} (expected for violations)")
        
        # Parse JSON output
        if result.stdout:
            try:
                data = json.loads(result.stdout)
                
                # Count violations
                total_failed = 0
                total_passed = 0
                
                if isinstance(data, list):
                    for item in data:
                        if 'results' in item:
                            results = item['results']
                            total_failed += len(results.get('failed_checks', []))
                            total_passed += len(results.get('passed_checks', []))
                elif isinstance(data, dict) and 'results' in data:
                    results = data['results']
                    total_failed = len(results.get('failed_checks', []))
                    total_passed = len(results.get('passed_checks', []))
                
                print(f"✅ Passed checks: {total_passed}")
                print(f"❌ Failed checks: {total_failed}")
                print("=" * 50)
                
                if total_failed > 0:
                    print("🎯 SUCCESS: Checkov detected security violations!")
                    print(f"   Expected violations in:")
                    print(f"   - Security groups (SSH open to 0.0.0.0/0)")
                    print(f"   - EC2 instances (unencrypted EBS)")
                    print(f"   - S3 buckets (no encryption/public access)")
                    print(f"   - IAM policies (wildcard permissions)")
                    return True
                else:
                    print("⚠️  No violations detected - check configuration!")
                    return False
                    
            except json.JSONDecodeError:
                print("❌ Failed to parse Checkov JSON output")
                print("Raw output:", result.stdout[:500])
                return False
        else:
            print("❌ No output from Checkov")
            return False
            
    except subprocess.TimeoutExpired:
        print("❌ Checkov scan timed out")
        return False
    except FileNotFoundError:
        print("❌ Checkov not found - please install: pip3 install checkov")
        return False
    except Exception as e:
        print(f"❌ Error running Checkov: {e}")
        return False

def check_config_files():
    """Check if configuration files are properly set up"""
    
    print("📋 Checking configuration files...")
    print("=" * 50)
    
    # Check .checkov.yaml
    checkov_config = ".checkov.yaml"
    if os.path.exists(checkov_config):
        with open(checkov_config, 'r') as f:
            content = f.read()
            if "soft-fail: true" in content:
                print("✅ .checkov.yaml: soft-fail enabled for demo")
            if "skip-check: []" in content:
                print("✅ .checkov.yaml: no checks skipped")
            else:
                print("⚠️  .checkov.yaml: some checks may be skipped")
    else:
        print("❌ .checkov.yaml not found")
    
    # Check GitHub Actions workflow
    workflow_file = ".github/workflows/security-scan.yml"
    if os.path.exists(workflow_file):
        print("✅ GitHub Actions workflow found")
    else:
        print("❌ GitHub Actions workflow not found")
    
    print("=" * 50)

if __name__ == "__main__":
    print("🛡️  Cloud Sentinel - Configuration Test")
    print("=" * 50)
    
    check_config_files()
    
    if run_checkov_test():
        print("\n🎉 Configuration test PASSED!")
        print("   Your GitHub Actions pipeline should now detect violations.")
        sys.exit(0)
    else:
        print("\n❌ Configuration test FAILED!")
        print("   Please check the Checkov installation and configuration.")
        sys.exit(1)