# Change the MTU of a ZeroTier Central-managed network.
#
# Requires you to be the network admin and to have an API token from
# my.zerotier.com -> Account -> API Access Tokens.
#
# Sends a PATCH-style update (only the MTU field), uses the documented
# "Authorization: token <token>" scheme, and reads the token as a
# SecureString so it does not sit in plain text on the command line.

$ErrorActionPreference = 'Stop'

Write-Host "ZeroTier Central - per-network MTU update"
Write-Host "-----------------------------------------"
Write-Host ""
Write-Host "You need:"
Write-Host "  * an API token (my.zerotier.com -> Account -> API Access Tokens)"
Write-Host "  * the 16-hex network ID"
Write-Host "  * admin rights on that network"
Write-Host ""

# Read the token as SecureString so it is not echoed and is easier to clear.
$secureToken = Read-Host -Prompt "API token" -AsSecureString
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
try {
    $token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
} finally {
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
}
if ([string]::IsNullOrWhiteSpace($token)) {
    Write-Host "[ERROR] No token entered. Aborting."
    exit 1
}

Write-Host ""
$network_id = Read-Host -Prompt "Network ID (16 hex chars)"
if ($network_id -notmatch '^[0-9a-fA-F]{16}$') {
    Write-Host "[ERROR] Network ID '$network_id' does not look like 16 hex chars. Aborting."
    exit 1
}

Write-Host ""
Write-Host "ZeroTier's default MTU is 2800. For gaming, 1400 or lower is common."
$mtuRaw = Read-Host -Prompt "Desired MTU (integer)"
$mtuParsed = 0
if (-not [int]::TryParse($mtuRaw, [ref]$mtuParsed)) {
    Write-Host "[ERROR] MTU must be an integer. Aborting."
    exit 1
}
if ($mtuParsed -lt 68 -or $mtuParsed -gt 9000) {
    Write-Host "[ERROR] MTU $mtuParsed out of plausible range (68..9000). Aborting."
    exit 1
}
$mtu = $mtuParsed

# Documented ZeroTier auth scheme.
$headers = @{
    Authorization  = "token $token"
    'Content-Type' = 'application/json'
}

# PATCH-style: send only the field we want to change. ZeroTier Central
# merges the partial config server-side, so we don't risk overwriting
# read-only fields by round-tripping the full document.
$body = @{ config = @{ mtu = $mtu } } | ConvertTo-Json -Depth 5 -Compress
$uri  = "https://api.zerotier.com/api/v1/network/$network_id"

try {
    Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body -TimeoutSec 30 | Out-Null
    Write-Host ""
    Write-Host "[OK] MTU set to $mtu on network $network_id."
    Write-Host ""
    Write-Host "Note: the ZeroTier dashboard may still show the old MTU (2800) -"
    Write-Host "that is a documented visual bug. Verify with:"
    Write-Host "    ping <peer-zt-ip> -l $($mtu + 100) -f"
    Write-Host "which should report 'Packet needs to be fragmented' once the new"
    Write-Host "MTU is in effect."
} catch {
    $status = $null
    if ($_.Exception.Response) { $status = $_.Exception.Response.StatusCode.value__ }
    Write-Host ""
    if ($status) {
        Write-Host "[ERROR] Update failed (HTTP $status): $($_.Exception.Message)"
    } else {
        Write-Host "[ERROR] Update failed: $($_.Exception.Message)"
    }
    exit 1
} finally {
    Remove-Variable token -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Press any key to continue..."
[System.Console]::ReadKey($true) | Out-Null
