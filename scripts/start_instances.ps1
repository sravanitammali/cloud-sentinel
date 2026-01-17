# ===========================================
# CLOUD SENTINEL - Start All EC2 Instances
# ===========================================
# Starts all stopped instances
# Run: .\scripts\start_instances.ps1
# ===========================================

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "CLOUD SENTINEL - Starting All Instances" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Get all stopped instance IDs with our project tag
$instances = aws ec2 describe-instances `
    --filters "Name=tag:Project,Values=cloud-sentinel" "Name=instance-state-name,Values=stopped" `
    --query "Reservations[*].Instances[*].InstanceId" `
    --output text

if ([string]::IsNullOrWhiteSpace($instances)) {
    Write-Host "No stopped instances found." -ForegroundColor Yellow
    exit 0
}

$instanceIds = $instances -split '\s+'
Write-Host "Found $($instanceIds.Count) stopped instances:" -ForegroundColor Green
$instanceIds | ForEach-Object { Write-Host "  - $_" }
Write-Host ""

Write-Host "Starting instances..." -ForegroundColor Yellow

aws ec2 start-instances --instance-ids $instanceIds

Write-Host ""
Write-Host "Start command sent! Waiting for instances to start..." -ForegroundColor Yellow
aws ec2 wait instance-running --instance-ids $instanceIds

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "All instances started!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""

# Show instance details
Write-Host "Instance Details:" -ForegroundColor Cyan
Write-Host "-----------------" -ForegroundColor Cyan
aws ec2 describe-instances `
    --filters "Name=tag:Project,Values=cloud-sentinel" "Name=instance-state-name,Values=running" `
    --query "Reservations[*].Instances[*].[Tags[?Key=='Name'].Value|[0],InstanceId,PublicIpAddress,PrivateIpAddress,State.Name]" `
    --output table

Write-Host ""
Write-Host "Note: Public IPs may have changed after restart!" -ForegroundColor Yellow
