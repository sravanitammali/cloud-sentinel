# ===========================================
# CLOUD SENTINEL - Stop All EC2 Instances
# ===========================================
# Stops all instances to save money
# Run: .\scripts\stop_instances.ps1
# ===========================================

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "CLOUD SENTINEL - Stopping All Instances" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Get all running instance IDs with our project tag
$instances = aws ec2 describe-instances `
    --filters "Name=tag:Project,Values=cloud-sentinel" "Name=instance-state-name,Values=running" `
    --query "Reservations[*].Instances[*].InstanceId" `
    --output text

if ([string]::IsNullOrWhiteSpace($instances)) {
    Write-Host "No running instances found." -ForegroundColor Yellow
    exit 0
}

$instanceIds = $instances -split '\s+'
Write-Host "Found $($instanceIds.Count) running instances:" -ForegroundColor Green
$instanceIds | ForEach-Object { Write-Host "  - $_" }
Write-Host ""

# Confirm
$confirm = Read-Host "Stop all instances? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Stopping instances..." -ForegroundColor Yellow

aws ec2 stop-instances --instance-ids $instanceIds

Write-Host ""
Write-Host "Stop command sent! Waiting for instances to stop..." -ForegroundColor Yellow
aws ec2 wait instance-stopped --instance-ids $instanceIds

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "All instances stopped!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Cost savings: ~Rs.8-10/hour saved while stopped" -ForegroundColor Cyan
Write-Host "Note: Storage charges (~Rs.5/day) still apply" -ForegroundColor Yellow
Write-Host ""
Write-Host "To start again: .\scripts\start_instances.ps1" -ForegroundColor Cyan
