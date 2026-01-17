# ===========================================
# CLOUD SENTINEL - Check Instance Status
# ===========================================
# Shows status of all instances
# Run: .\scripts\status.ps1
# ===========================================

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "CLOUD SENTINEL - Instance Status" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Get all instances with our project tag
aws ec2 describe-instances `
    --filters "Name=tag:Project,Values=cloud-sentinel" `
    --query "Reservations[*].Instances[*].[Tags[?Key=='Name'].Value|[0],InstanceId,InstanceType,State.Name,PublicIpAddress,PrivateIpAddress]" `
    --output table

Write-Host ""

# Count by state
$running = (aws ec2 describe-instances `
    --filters "Name=tag:Project,Values=cloud-sentinel" "Name=instance-state-name,Values=running" `
    --query "Reservations[*].Instances[*].InstanceId" `
    --output text) -split '\s+' | Where-Object { $_ }

$stopped = (aws ec2 describe-instances `
    --filters "Name=tag:Project,Values=cloud-sentinel" "Name=instance-state-name,Values=stopped" `
    --query "Reservations[*].Instances[*].InstanceId" `
    --output text) -split '\s+' | Where-Object { $_ }

Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Running: $($running.Count)" -ForegroundColor Green
Write-Host "  Stopped: $($stopped.Count)" -ForegroundColor Yellow
Write-Host ""

if ($running.Count -gt 0) {
    Write-Host "Estimated cost while running: ~Rs.10-12/hour" -ForegroundColor Yellow
} else {
    Write-Host "All instances stopped - only storage charges apply (~Rs.5/day)" -ForegroundColor Green
}
