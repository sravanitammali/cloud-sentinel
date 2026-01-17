#!/bin/bash
# ===========================================
# CLOUD SENTINEL - Run Security Scan
# ===========================================
# Manually trigger a security scan on Terraform code
#
# Usage: ./scripts/run_scan.sh [terraform_dir]
# ===========================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default terraform directory
TERRAFORM_DIR="${1:-./terraform}"

echo -e "${BLUE}"
echo "=========================================="
echo "   CLOUD SENTINEL - Security Scanner"
echo "=========================================="
echo -e "${NC}"

# Check if terraform directory exists
if [ ! -d "$TERRAFORM_DIR" ]; then
    echo -e "${RED}Error: Terraform directory not found: $TERRAFORM_DIR${NC}"
    exit 1
fi

# Check if checkov is installed
if ! command -v checkov &> /dev/null; then
    # Try local installation
    if [ -f ~/.local/bin/checkov ]; then
        CHECKOV_CMD=~/.local/bin/checkov
    else
        echo -e "${RED}Error: Checkov not installed. Run setup.sh first.${NC}"
        exit 1
    fi
else
    CHECKOV_CMD=checkov
fi

# Create output directory
OUTPUT_DIR="./checkov_results"
mkdir -p "$OUTPUT_DIR"

# Generate timestamp for this scan
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="$OUTPUT_DIR/scan_${TIMESTAMP}.json"

echo -e "${YELLOW}Scanning: $TERRAFORM_DIR${NC}"
echo -e "${YELLOW}Output: $OUTPUT_FILE${NC}"
echo ""

# Run Checkov
echo "Running Checkov security scan..."
echo "----------------------------------------"

$CHECKOV_CMD \
    -d "$TERRAFORM_DIR" \
    --framework terraform \
    -o cli \
    -o json \
    --output-file-path "$OUTPUT_DIR" \
    --compact

# Rename output file
if [ -f "$OUTPUT_DIR/results_json.json" ]; then
    mv "$OUTPUT_DIR/results_json.json" "$OUTPUT_FILE"
fi

echo ""
echo "----------------------------------------"
echo -e "${GREEN}Scan complete!${NC}"
echo -e "Results saved to: ${BLUE}$OUTPUT_FILE${NC}"
echo ""

# Parse and display summary
if [ -f "$OUTPUT_FILE" ]; then
    echo "Quick Summary:"
    echo "----------------------------------------"
    
    # Use Python to parse JSON
    python3 << EOF
import json
import sys

try:
    with open("$OUTPUT_FILE", 'r') as f:
        data = json.load(f)
    
    if isinstance(data, list):
        passed = sum(len(d.get('results', {}).get('passed_checks', [])) for d in data)
        failed = sum(len(d.get('results', {}).get('failed_checks', [])) for d in data)
        skipped = sum(len(d.get('results', {}).get('skipped_checks', [])) for d in data)
    else:
        results = data.get('results', {})
        passed = len(results.get('passed_checks', []))
        failed = len(results.get('failed_checks', []))
        skipped = len(results.get('skipped_checks', []))
    
    total = passed + failed + skipped
    
    print(f"Total Checks: {total}")
    print(f"✓ Passed: {passed}")
    print(f"✗ Failed: {failed}")
    print(f"⊘ Skipped: {skipped}")
    
    if failed > 0:
        print("\n⚠️  Security issues found! Review the output above.")
        sys.exit(1)
    else:
        print("\n✅ No security issues found!")
        sys.exit(0)
        
except Exception as e:
    print(f"Error parsing results: {e}")
    sys.exit(1)
EOF
fi
