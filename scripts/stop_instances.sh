#!/bin/bash
# ===========================================
# CLOUD SENTINEL - Stop All EC2 Instances
# ===========================================
# Stops all instances to save money
# Storage charges still apply (~₹5/day) but compute stops
# ===========================================

echo "=========================================="
echo "CLOUD SENTINEL - Stopping All Instances"
echo "=========================================="

# Get all instance IDs with our project tag
INSTANCE_IDS=$(aws ec2 describe-instances \
    --filters "Name=tag:Project,Values=cloud-sentinel" "Name=instance-state-name,Values=running" \
    --query "Reservations[*].Instances[*].InstanceId" \
    --output text)

if [ -z "$INSTANCE_IDS" ]; then
    echo "No running instances found."
    exit 0
fi

echo "Found instances: $INSTANCE_IDS"
echo ""
echo "Stopping instances..."

aws ec2 stop-instances --instance-ids $INSTANCE_IDS

echo ""
echo "✓ Stop command sent!"
echo ""
echo "Waiting for instances to stop..."
aws ec2 wait instance-stopped --instance-ids $INSTANCE_IDS

echo ""
echo "=========================================="
echo "✓ All instances stopped!"
echo "=========================================="
echo ""
echo "To start them again, run: ./scripts/start_instances.sh"
