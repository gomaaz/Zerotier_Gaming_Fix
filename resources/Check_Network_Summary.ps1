# Compact pass/fail summary of the same checks Check_Network_interfaces.bat
# prints in long form. Renders at the end of the diagnostic run so the user
# does not have to scroll back through the full output to know if anything
# is misconfigured.
#
# Status values:
#   OK    - check matches the expected state from the README "Verifying" table
#   WARN  - non-fatal: optional component missing, or no ZT adapter found yet
#   FAIL  - misconfiguration; the per-reconnect fix is not delivering this item
#   SKIP  - check intentionally bypassed (no ZT adapter -> route checks N/A)

$ErrorActionPreference = 'SilentlyContinue'

function New-Result {
    param([int]$Num, [string]$Section, [string]$Status, [string]$Details)
    [pscustomobject]@{
        '#'       = $Num
        Section   = $Section
        Status    = $Status
        Details   = $Details
    }
}

$results = @()

# [0] DirectPlay
$dp = Get-WindowsOptionalFeature -Online -FeatureName DirectPlay
if ($dp -and $dp.State -eq 'Enabled') {
    $results += New-Result 0 'DirectPlay' 'OK' 'State=Enabled'
} else {
    $state = if ($dp) { $dp.State } else { 'not present' }
    $results += New-Result 0 'DirectPlay' 'FAIL' "State=$state (expected Enabled)"
}

# Collect ZT adapters once. Used by [1], [2], [4], [5].
$ztIf = Get-NetIPInterface | Where-Object { $_.InterfaceAlias -like 'ZeroTier*' }
$ztIfV4 = $ztIf | Where-Object { $_.AddressFamily -eq 'IPv4' }
$hasZt = [bool]$ztIf

# [1] Adapter metric on ZT — family-specific: IPv4=1 (top priority for
# LAN gaming), IPv6=20 (deliberately deprioritized so other adapters'
# IPv6 wins route selection — see ZeroTier_Fix.bat for rationale).
if (-not $hasZt) {
    $results += New-Result 1 'ZT adapter metric' 'WARN' 'no ZeroTier adapters found'
} else {
    $badMetric = $ztIf | Where-Object {
        ($_.AddressFamily -eq 'IPv4' -and $_.InterfaceMetric -ne 1) -or
        ($_.AddressFamily -eq 'IPv6' -and $_.InterfaceMetric -ne 20)
    }
    if ($badMetric) {
        $detail = ($badMetric | ForEach-Object { "$($_.InterfaceAlias)($($_.AddressFamily))=$($_.InterfaceMetric)" } | Select-Object -Unique) -join ', '
        $results += New-Result 1 'ZT adapter metric' 'FAIL' "expected IPv4=1 IPv6=20 - got: $detail"
    } else {
        $results += New-Result 1 'ZT adapter metric' 'OK' 'IPv4=1, IPv6=20 on all ZT adapters'
    }
}

# [2] Network category Private on ZT
$ztProf = Get-NetConnectionProfile | Where-Object { $_.InterfaceAlias -like 'ZeroTier*' }
if (-not $ztProf) {
    $msg = if ($hasZt) { 'no active ZT connection profile' } else { 'no ZeroTier adapters found' }
    $results += New-Result 2 'ZT network category' 'WARN' $msg
} else {
    $bad = $ztProf | Where-Object { $_.NetworkCategory -ne 'Private' }
    if ($bad) {
        $detail = ($bad | ForEach-Object { "$($_.InterfaceAlias)=$($_.NetworkCategory)" }) -join ', '
        $results += New-Result 2 'ZT network category' 'FAIL' "expected Private - got: $detail"
    } else {
        $results += New-Result 2 'ZT network category' 'OK' 'all ZT profiles=Private'
    }
}

# [3] IPv6 prefix policy ::ffff:0:0/96 with precedence 100
# netsh prints the columns as "Precedence Label Prefix" (both EN and DE
# locales), so we match the precedence number at the start of the line
# containing our prefix - not "<prefix> 100 4" which was wrong.
$pp = netsh interface ipv6 show prefixpolicies 2>$null
$ppLine = $pp | Where-Object { $_ -match '::ffff:0:0/96' } | Select-Object -First 1
if ($ppLine -and $ppLine -match '^\s*100\s+\d+\s+::ffff:0:0/96\s*$') {
    $results += New-Result 3 'IPv6 prefix policy' 'OK' '::ffff:0:0/96 precedence=100'
} else {
    $results += New-Result 3 'IPv6 prefix policy' 'FAIL' '::ffff:0:0/96 precedence=100 missing (IPv4 not prioritized)'
}

# [4] No ::/0 default route on ZT (IPv6)
if (-not $hasZt) {
    $results += New-Result 4 'No ::/0 on ZT' 'SKIP' 'no ZeroTier adapters'
} else {
    $bad6 = Get-NetRoute -AddressFamily IPv6 | Where-Object {
        $_.InterfaceAlias -like 'ZeroTier*' -and $_.DestinationPrefix -eq '::/0'
    }
    if ($bad6) {
        $detail = ($bad6 | ForEach-Object { $_.InterfaceAlias } | Select-Object -Unique) -join ', '
        $results += New-Result 4 'No ::/0 on ZT' 'WARN' "::/0 route present on: $detail"
    } else {
        $results += New-Result 4 'No ::/0 on ZT' 'OK' 'no IPv6 default route on ZT adapters'
    }
}

# [5] No 0.0.0.0/0 default route on ZT (IPv4)
if (-not $hasZt) {
    $results += New-Result 5 'No 0.0.0.0/0 on ZT' 'SKIP' 'no ZeroTier adapters'
} else {
    $bad4 = Get-NetRoute -AddressFamily IPv4 | Where-Object {
        $_.InterfaceAlias -like 'ZeroTier*' -and $_.DestinationPrefix -eq '0.0.0.0/0'
    }
    if ($bad4) {
        $detail = ($bad4 | ForEach-Object { $_.InterfaceAlias } | Select-Object -Unique) -join ', '
        $results += New-Result 5 'No 0.0.0.0/0 on ZT' 'WARN' "default route present on: $detail (ZT may hijack internet)"
    } else {
        $results += New-Result 5 'No 0.0.0.0/0 on ZT' 'OK' 'no IPv4 default route on ZT adapters'
    }
}

# [6] Broadcast route 255.255.255.255/32 present on each ZT adapter
if (-not $ztIfV4) {
    $results += New-Result 6 'Broadcast route' 'SKIP' 'no ZeroTier IPv4 adapters'
} else {
    $bcast = Get-NetRoute -AddressFamily IPv4 | Where-Object {
        $_.InterfaceAlias -like 'ZeroTier*' -and $_.DestinationPrefix -eq '255.255.255.255/32'
    }
    $coveredIdx = @($bcast | ForEach-Object { $_.InterfaceIndex } | Select-Object -Unique)
    $missing = $ztIfV4 | Where-Object { $coveredIdx -notcontains $_.InterfaceIndex }
    if ($missing) {
        $detail = ($missing | ForEach-Object { $_.InterfaceAlias }) -join ', '
        $results += New-Result 6 'Broadcast route' 'FAIL' "255.255.255.255/32 missing on: $detail"
    } else {
        $results += New-Result 6 'Broadcast route' 'OK' '255.255.255.255/32 on every ZT adapter'
    }
}

# [7] Scheduled task ZeroTier Auto Fix
$task = Get-ScheduledTask -TaskName 'ZeroTier Auto Fix' -ErrorAction SilentlyContinue
if (-not $task) {
    $results += New-Result 7 'Scheduled task' 'FAIL' "'ZeroTier Auto Fix' not registered"
} else {
    $info = $task | Get-ScheduledTaskInfo
    switch ($info.LastTaskResult) {
        0       { $results += New-Result 7 'Scheduled task' 'OK' "LastResult=0 at $($info.LastRunTime)" }
        267011  { $results += New-Result 7 'Scheduled task' 'WARN' 'registered, has not fired yet (267011)' }
        default { $results += New-Result 7 'Scheduled task' 'FAIL' "LastResult=$($info.LastTaskResult) at $($info.LastRunTime)" }
    }
}

# [8] WinIPBroadcast service (optional)
$svc = Get-Service -Name WinIPBroadcast -ErrorAction SilentlyContinue
if (-not $svc) {
    $results += New-Result 8 'WinIPBroadcast (opt)' 'SKIP' 'not installed'
} elseif ($svc.Status -eq 'Running') {
    $results += New-Result 8 'WinIPBroadcast (opt)' 'OK' 'Running'
} else {
    $results += New-Result 8 'WinIPBroadcast (opt)' 'WARN' "Status=$($svc.Status) (expected Running)"
}

Write-Host ''
Write-Host '=============================================================='
Write-Host '[SUMMARY] Diagnostic results'
Write-Host '=============================================================='

$results | Format-Table -AutoSize -Property '#', Section, Status, Details | Out-String -Width 200 | Write-Host

# @(...) wrap so .Count returns 0 (not $null) when zero items match,
# and returns the correct int when exactly one item matches (without
# the wrap, Where-Object returns a single PSCustomObject and .Count
# on that is unreliable in Windows PowerShell 5.1).
$fail = @($results | Where-Object { $_.Status -eq 'FAIL' }).Count
$warn = @($results | Where-Object { $_.Status -eq 'WARN' }).Count
$ok   = @($results | Where-Object { $_.Status -eq 'OK'   }).Count

Write-Host ('OK={0}  WARN={1}  FAIL={2}' -f $ok, $warn, $fail)
Write-Host ''
if ($fail -eq 0 -and $warn -eq 0) {
    Write-Host '[RESULT] All checks pass - the fix is delivering the expected state.'
} elseif ($fail -eq 0) {
    Write-Host '[RESULT] No failures. Warnings are usually fine (optional/no-ZT-yet).'
} else {
    Write-Host '[RESULT] Failures detected. Scroll up to the matching [#] block for raw output.'
}
Write-Host '=============================================================='
