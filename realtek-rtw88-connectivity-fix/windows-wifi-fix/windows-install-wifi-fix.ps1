# 1. Dynamically discover the active gateway IP address
$Gateway = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Select-Object -First 1).NextHop

# 2. Block the script if no connection is active
if (-not $Gateway) {
    Exit
}

# 3. Execution loop: Send low-overhead pulse every 10 seconds to trick the driver
while ($true) {
    # Check if gateway path is still valid
    if (Test-Connection -ComputerName $Gateway -Count 1 -Quiet) {
        # Success - line kept warm
    }
    Start-Sleep -Seconds 10
}
