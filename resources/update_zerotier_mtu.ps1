# 1. Ask the user for API token
Write-Host "This script uses the ZeroTier API to change the MTU settings for a specific network."
Write-Host "In order to authenticate and update network parameters (such as MTU), you need your API token."
Write-Host "You can find or create your API token by logging into the ZeroTier Dashboard (my.zerotier.com),"
Write-Host "navigating to account settings -> API Access Tokens -> New Token -> Copy the token and pase it here"
Write-Host ""

$token = Read-Host -Prompt "Please enter your API token"
Write-Host ""
Write-Host ""
# 2. Ask the user for network ID
Write-Host "Enter your vali ZeroTier network ID to apply the MTU settings."
Write-Host "You can find your network ID in the ZeroTier Dashboard (my.zerotier.com) under"
Write-Host "the 'Networks' section. Each network you create has a unique 16-character ID."
Write-Host ""
$network_id = Read-Host -Prompt "Please enter your network ID"
Write-Host ""
Write-Host ""

# 3. Ask the user for desired MTU size
Write-Host "ZeroTier's default MTU is 2800, which is generally well suited for file transfers."
Write-Host "For gaming, many users prefer a lower MTU such as 1400 or even below,"
Write-Host "to potentially reduce latency and avoid large packet fragmentation."
Write-Host ""

$mtu = Read-Host -Prompt "Please enter the desired MTU size"

# 4. Set up HTTP headers
$headers = @{
    Authorization = "bearer $token"
    "Content-Type" = "application/json"
}

# 5. Retrieve the current network configuration
try {
    $network_config = Invoke-RestMethod -Uri "https://api.zerotier.com/api/v1/network/$network_id" `
                                        -Method Get `
                                        -Headers $headers
}
catch {
    Write-Host "Error retrieving network data: $($_.Exception.Message)"
    exit 1
}

# 6. Check if data was retrieved successfully
if ($network_config -eq $null) {
    Write-Host "Error: No network data received!"
    exit 1
}

# 7. Change the MTU value
# Convert the user input to an integer for safety
$network_config.config.mtu = [int]$mtu

# 8. Convert the configuration back to JSON
$body = $network_config | ConvertTo-Json -Depth 10 -Compress

# 9. Send the updated configuration
try {
    Invoke-RestMethod -Uri "https://api.zerotier.com/api/v1/network/$network_id" `
                      -Method Post `
                      -Headers $headers `
                      -Body $body

    Write-Host "MTU successfully set to $mtu!"
    Write-Host "Note: If Windows is still showing MTU 2800, this is a visual bug!"
}
catch {
    Write-Host "Error while sending the updated configuration: $($_.Exception.Message)"
    exit 1
}
Write-Host ""
# 10. (Optional) Pause to prevent the console from closing immediately
Write-Host ""
Write-Host "Press any key to continue..."
[System.Console]::ReadKey() | Out-Null
