#!/bin/bash
# ===========================================
# CLOUD SENTINEL - Start All EC2 Instances
# ===========================================
# Starts all stopped instances
# ===========================================

echo "=========================================="
echo "CLOUD SENTINEL - Starting All Instances"
echo "=========================================="

# Get all instance IDs with our project tag
INSTANCE_IDS=$(aws ec2 describe-instances \
    --filters "Name=tag:Project,Values=cloud-sentinel" "Name=instance-state-name,Values=stopped" \
    --query "Reservations[*].Instances[*].InstanceId" \
    --output text)

if [ -z "$INSTANCE_IDS" ]; then
    echo "No stopped instances found."
    exit 0
fi

echo "Found instances: $INSTANCE_IDS"
echo ""
echo "Starting instances..."

aws ec2 start-instances --instance-ids $INSTANCE_IDS

echo ""
echo "✓ Start command sent!"
echo ""
echo "Waiting for instances to start..."
aws ec2 wait instance-running --instance-ids $INSTANCE_IDS

echo ""
echo "=========================================="
echo "✓ All instances started!"
echo "=========================================="
echo ""
echo "Getting new public IPs..."
aws ec2 describe-instances \
    --filters "Name=tag:Project,Values=cloud-sentinel" "Name=instance-state-name,Values=running" \
    --query "Reservations[*].Instances[*].[Tags[?Key=='Name'].Value|[0],PublicIpAddress,PrivateIpAddress]" \
    --output table
