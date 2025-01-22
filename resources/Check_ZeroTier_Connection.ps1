$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$fixScript = "$scriptPath\ZeroTier_Fix.bat"

# Find ZeroTier Network Adapter
$ztInterfaces = Get-NetIPInterface | Where-Object { $_.InterfaceAlias -like "ZeroTier*" }

if ($ztInterfaces) {
    # Check if any ZeroTier adapter has a metric other than 1
    $wrongMetric = $ztInterfaces | Where-Object { $_.InterfaceMetric -ne 1 }

    if ($wrongMetric) {
        Write-Output "[INFO] ZeroTier adapter found with wrong metric! Running fix script..."
        Start-Process -FilePath $fixScript -WindowStyle Hidden -Verb RunAs
    }
}
