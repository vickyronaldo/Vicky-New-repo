<#
.SYNOPSIS
Collects Floor 6 endpoint evidence for suspected deployment assignment/config conflict (top-ranked cause).

.DESCRIPTION
Hand-Corrected Version (reviewed and refined).
This script is read-only by design and safe for endpoint execution.
It gathers system, deployment, event, policy, and configuration evidence to validate or invalidate
whether Friday's targeted app deployment is causing Monday login failures/slowness.

Traceability labels are included in all sections for auditability.

.PARAMETER DryRun
When set, prints planned actions and does not collect data, write files, or compress output.

.PARAMETER AppName
Keyword for the deployed application to correlate (default: DMS-Client).

.PARAMETER LookbackDays
Event/log lookback window in days (default: 7).

.PARAMETER OutputRoot
Root output path for evidence package.

.EXAMPLE
.\Floor6_Evidence_Collector_Hand_Corrected.ps1 -DryRun

.EXAMPLE
.\Floor6_Evidence_Collector_Hand_Corrected.ps1 -AppName 'DMS-Client' -LookbackDays 5
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [ValidateNotNullOrEmpty()]
    [string]$AppName = 'DMS-Client',
    [ValidateRange(1,30)]
    [int]$LookbackDays = 7,
    [ValidateNotNullOrEmpty()]
    [string]$OutputRoot = 'C:\Temp\DWP_Floor6_Evidence'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ============================================================
# SECTION T00 - Assumptions and Safety Controls
# Purpose:
# - Declare investigation scope and non-destructive behavior.
# - Ensure this script is usable by another engineer without hidden side effects.
# Collected Data:
# - None (control section).
# Expected Output:
# - Clear run mode and scope printed to console and log.
# ============================================================

$script:Run = [ordered]@{
    ScriptName = 'Floor6_Evidence_Collector_Hand_Corrected.ps1'
    ScriptVersion = '1.1-hand-corrected'
    RunId = [guid]::NewGuid().ToString()
    StartTime = Get-Date
    EndTime = $null
    DurationMinutes = $null
    DryRun = [bool]$DryRun
    AppName = $AppName
    LookbackDays = $LookbackDays
    SuspectedCause = 'Deployment assignment/config conflict in updated pool (to confirm)'
    ComputerName = $env:COMPUTERNAME
    UserName = $env:USERNAME
    OutputRoot = $OutputRoot
    OutputFolder = $null
    LogFile = $null
    ZipFile = $null
    Status = 'Running'
    CollectedArtifacts = New-Object System.Collections.ArrayList
    SkippedItems = New-Object System.Collections.ArrayList
    Errors = New-Object System.Collections.ArrayList
    Steps = New-Object System.Collections.ArrayList
}

function Write-ConsoleLine {
    param(
        [string]$Level,
        [string]$Message
    )
    $stamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Write-Host "[$stamp] [$Level] $Message"
}

function Write-RunLog {
    param(
        [string]$Level,
        [string]$Section,
        [string]$Message
    )

    $line = "{0}`t{1}`t{2}`t{3}" -f (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff'), $Level, $Section, $Message
    Write-ConsoleLine -Level $Level -Message "$Section - $Message"

    if (-not $DryRun -and $script:Run.LogFile) {
        try {
            Add-Content -Path $script:Run.LogFile -Value $line -Encoding UTF8
        } catch {
            Write-ConsoleLine -Level 'WARN' -Message "T00 - Logging fallback only: $($_.Exception.Message)"
        }
    }
}

function Add-StepRecord {
    param(
        [string]$StepId,
        [string]$Title,
        [string]$Outcome,
        [string]$Details
    )

    [void]$script:Run.Steps.Add([pscustomobject]@{
        Timestamp = (Get-Date).ToString('s')
        StepId = $StepId
        Title = $Title
        Outcome = $Outcome
        Details = $Details
    })
}

function Add-ArtifactPath {
    param([string]$Path)
    [void]$script:Run.CollectedArtifacts.Add($Path)
}

function Add-SkippedItem {
    param([string]$Reason)
    [void]$script:Run.SkippedItems.Add($Reason)
}

function Add-RunError {
    param([string]$ErrorText)
    [void]$script:Run.Errors.Add($ErrorText)
}

function New-IdempotentOutputFolder {
    param([string]$BasePath)

    $candidate = $BasePath
    $i = 1
    while (Test-Path -Path $candidate) {
        $candidate = "{0}_{1:D2}" -f $BasePath, $i
        $i++
    }
    New-Item -Path $candidate -ItemType Directory -Force | Out-Null
    return $candidate
}

function Invoke-SafeStep {
    param(
        [string]$StepId,
        [string]$Title,
        [string]$Purpose,
        [scriptblock]$Action
    )

    if ($DryRun) {
        Write-RunLog -Level 'INFO' -Section $StepId -Message "DRY-RUN: Would execute '$Title'. Purpose: $Purpose"
        Add-StepRecord -StepId $StepId -Title $Title -Outcome 'Skipped(DryRun)' -Details $Purpose
        Add-SkippedItem "$StepId - $Title (dry-run)"
        return
    }

    try {
        Write-RunLog -Level 'INFO' -Section $StepId -Message "Starting '$Title'. Purpose: $Purpose"
        & $Action
        Write-RunLog -Level 'SUCCESS' -Section $StepId -Message "Completed '$Title'."
        Add-StepRecord -StepId $StepId -Title $Title -Outcome 'Success' -Details $Purpose
    } catch {
        $err = $_.Exception.Message
        Write-RunLog -Level 'ERROR' -Section $StepId -Message "Failed '$Title': $err"
        Add-StepRecord -StepId $StepId -Title $Title -Outcome 'Error' -Details $err
        Add-RunError "$StepId - $Title: $err"
    }
}

# T01: Initialize output structure (idempotent and traceable)
# Purpose:
# - Create unique output folder and fixed subfolder layout.
# Collected Data:
# - None.
# Expected Output:
# - Evidence root + sections + run log.
if ($DryRun) {
    $script:Run.OutputFolder = Join-Path $OutputRoot ("{0}_{1}" -f $env:COMPUTERNAME, (Get-Date -Format 'yyyyMMdd_HHmmss'))
    Write-RunLog -Level 'INFO' -Section 'T01' -Message "DRY-RUN output target: $($script:Run.OutputFolder)"
    Add-StepRecord -StepId 'T01' -Title 'Initialize output structure' -Outcome 'Skipped(DryRun)' -Details 'Would create idempotent output folder and log.'
} else {
    try {
        if (-not (Test-Path -Path $OutputRoot)) {
            New-Item -Path $OutputRoot -ItemType Directory -Force | Out-Null
        }

        $baseName = "{0}_{1}" -f $env:COMPUTERNAME, (Get-Date -Format 'yyyyMMdd')
        $basePath = Join-Path $OutputRoot $baseName
        $script:Run.OutputFolder = New-IdempotentOutputFolder -BasePath $basePath

        $subfolders = @('00_Admin','10_System','20_Deployment','30_Events','40_Config','50_Diagnostics','90_Summary')
        foreach ($sub in $subfolders) {
            try {
                New-Item -Path (Join-Path $script:Run.OutputFolder $sub) -ItemType Directory -Force | Out-Null
            } catch {
                throw "Unable to create subfolder '$sub': $($_.Exception.Message)"
            }
        }

        $script:Run.LogFile = Join-Path (Join-Path $script:Run.OutputFolder '00_Admin') ("runlog_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
        New-Item -Path $script:Run.LogFile -ItemType File -Force | Out-Null
        Add-ArtifactPath $script:Run.LogFile

        Write-RunLog -Level 'INFO' -Section 'T01' -Message "Initialized output at $($script:Run.OutputFolder)"
        Add-StepRecord -StepId 'T01' -Title 'Initialize output structure' -Outcome 'Success' -Details 'Idempotent folder and log created.'
    } catch {
        Write-ConsoleLine -Level 'FATAL' -Message "T01 failed: $($_.Exception.Message)"
        throw
    }
}

Write-RunLog -Level 'INFO' -Section 'T00' -Message "RunId=$($script:Run.RunId); DryRun=$($script:Run.DryRun); SuspectedCause='$($script:Run.SuspectedCause)'"

$windowStart = (Get-Date).AddDays(-$LookbackDays)

# T02: Collect host baseline system information
# Purpose:
# - Capture immutable host context for correlation and reproducibility.
# Collected Data:
# - Get-ComputerInfo, systeminfo, OS CIM snapshot.
# Expected Output:
# - JSON/TXT files in 10_System.
Invoke-SafeStep -StepId 'T02' -Title 'System baseline collection' -Purpose 'Capture host identity and OS context for evidence correlation.' -Action {
    $out = Join-Path $script:Run.OutputFolder '10_System'

    try {
        Get-ComputerInfo | ConvertTo-Json -Depth 5 | Out-File -FilePath (Join-Path $out 'computer_info.json') -Encoding UTF8
        Add-ArtifactPath (Join-Path $out 'computer_info.json')
    } catch {
        throw "Get-ComputerInfo failed: $($_.Exception.Message)"
    }

    try {
        systeminfo | Out-File -FilePath (Join-Path $out 'systeminfo.txt') -Encoding UTF8
        Add-ArtifactPath (Join-Path $out 'systeminfo.txt')
    } catch {
        throw "systeminfo capture failed: $($_.Exception.Message)"
    }

    try {
        Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object * |
            ConvertTo-Json -Depth 5 | Out-File -FilePath (Join-Path $out 'os_cim.json') -Encoding UTF8
        Add-ArtifactPath (Join-Path $out 'os_cim.json')
    } catch {
        throw "OS CIM capture failed: $($_.Exception.Message)"
    }
}

# T03: Collect user and network context
# Purpose:
# - Record current security token and network state for login troubleshooting.
# Collected Data:
# - whoami /all, ipconfig /all.
# Expected Output:
# - TXT files in 10_System.
Invoke-SafeStep -StepId 'T03' -Title 'User and network context' -Purpose 'Capture sign-in token and network configuration snapshot.' -Action {
    $out = Join-Path $script:Run.OutputFolder '10_System'

    try {
        whoami /all | Out-File -FilePath (Join-Path $out 'whoami_all.txt') -Encoding UTF8
        Add-ArtifactPath (Join-Path $out 'whoami_all.txt')
    } catch {
        throw "whoami capture failed: $($_.Exception.Message)"
    }

    try {
        ipconfig /all | Out-File -FilePath (Join-Path $out 'ipconfig_all.txt') -Encoding UTF8
        Add-ArtifactPath (Join-Path $out 'ipconfig_all.txt')
    } catch {
        throw "ipconfig capture failed: $($_.Exception.Message)"
    }
}

# T04: Collect deployment-agent logs and app-specific extracts
# Purpose:
# - Validate app assignment receipt, install status, error codes, and detection outcomes.
# Collected Data:
# - Intune agent logs (if present), app-focused extract lines.
# Expected Output:
# - Raw copied log files + filtered extract in 20_Deployment.
Invoke-SafeStep -StepId 'T04' -Title 'Deployment log collection' -Purpose 'Capture assignment/install evidence for deployment-cause validation.' -Action {
    $out = Join-Path $script:Run.OutputFolder '20_Deployment'
    $paths = @(
        'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log',
        'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\AgentExecutor.log'
    )

    foreach ($p in $paths) {
        try {
            if (Test-Path -Path $p) {
                $dest = Join-Path $out ([System.IO.Path]::GetFileName($p))
                Copy-Item -Path $p -Destination $dest -Force
                Add-ArtifactPath $dest
            } else {
                Write-RunLog -Level 'WARN' -Section 'T04' -Message "Log file not found: $p"
                Add-SkippedItem "T04 missing log file: $p"
            }
        } catch {
            throw "Failed copying deployment log '$p': $($_.Exception.Message)"
        }
    }

    $extractPath = Join-Path $out 'deployment_extract_app_focus.txt'
    $patterns = @($AppName, 'Assignment received', 'InstallState', 'ErrorCode', 'DetectionRule', 'NotDetected')

    try {
        $copiedLogs = Get-ChildItem -Path $out -Filter '*.log' -ErrorAction Stop
    } catch {
        throw "Could not enumerate copied deployment logs: $($_.Exception.Message)"
    }

    foreach ($log in $copiedLogs) {
        foreach ($pattern in $patterns) {
            try {
                Select-String -Path $log.FullName -Pattern $pattern -SimpleMatch -ErrorAction Stop |
                    ForEach-Object { "{0}`t{1}`t{2}" -f $log.Name, $_.LineNumber, $_.Line } |
                    Out-File -FilePath $extractPath -Encoding UTF8 -Append
            } catch {
                # Pattern not found is not a hard failure; only log as warning.
                Write-RunLog -Level 'WARN' -Section 'T04' -Message "Pattern '$pattern' not found or unreadable in $($log.Name): $($_.Exception.Message)"
                Add-SkippedItem "T04 pattern scan warning: $($log.Name) for '$pattern'"
            }
        }
    }

    if (Test-Path -Path $extractPath) {
        Add-ArtifactPath $extractPath
    } else {
        Write-RunLog -Level 'WARN' -Section 'T04' -Message 'No extract file produced; app pattern may be absent (to confirm).'
        Add-SkippedItem 'T04 no deployment extract produced.'
    }
}

# T05: Collect app registry presence evidence
# Purpose:
# - Verify installed/partial/absent app state from uninstall registry keys.
# Collected Data:
# - DisplayName, version, publisher, install date, uninstall string.
# Expected Output:
# - CSV + JSON in 40_Config.
Invoke-SafeStep -StepId 'T05' -Title 'App registry evidence' -Purpose 'Correlate deployment assignment with local app registration state.' -Action {
    $out = Join-Path $script:Run.OutputFolder '40_Config'
    $regPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    $results = New-Object System.Collections.ArrayList

    foreach ($rp in $regPaths) {
        try {
            $items = Get-ItemProperty -Path $rp -ErrorAction Stop |
                Where-Object { $_.DisplayName -and $_.DisplayName -like "*$AppName*" } |
                Select-Object PSPath, DisplayName, DisplayVersion, Publisher, InstallDate, UninstallString
            foreach ($item in $items) {
                [void]$results.Add($item)
            }
        } catch {
            Write-RunLog -Level 'WARN' -Section 'T05' -Message "Registry query failed for $rp: $($_.Exception.Message)"
            Add-SkippedItem "T05 registry query failed: $rp"
        }
    }

    try {
        $csv = Join-Path $out 'app_registry_matches.csv'
        $json = Join-Path $out 'app_registry_matches.json'
        $results | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
        $results | ConvertTo-Json -Depth 5 | Out-File -FilePath $json -Encoding UTF8
        Add-ArtifactPath $csv
        Add-ArtifactPath $json
    } catch {
        throw "Failed writing app registry outputs: $($_.Exception.Message)"
    }
}

# T06: Collect event evidence for install, policy, and profile symptoms
# Purpose:
# - Obtain timestamped event evidence that supports/contradicts deployment-cause hypothesis.
# Collected Data:
# - MSI install events, Group Policy operational events, User Profile Service events,
#   DeviceManagement events.
# Expected Output:
# - One CSV per event source in 30_Events.
Invoke-SafeStep -StepId 'T06' -Title 'Event log evidence collection' -Purpose 'Gather event-level diagnostics mapped to login/deployment behavior.' -Action {
    $out = Join-Path $script:Run.OutputFolder '30_Events'

    $eventQueries = @(
        @{ Name='Application_MsiInstaller'; Log='Application'; Provider='MsiInstaller'; Ids=@(11707,11708,1033) },
        @{ Name='GroupPolicy_Operational'; Log='Microsoft-Windows-GroupPolicy/Operational'; Provider=$null; Ids=@(1129,5312,5317,5326) },
        @{ Name='UserProfileService_Application'; Log='Application'; Provider='User Profile Service'; Ids=@(1511,1515,1530,1534) },
        @{ Name='DeviceManagement_Admin'; Log='Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin'; Provider=$null; Ids=@(404,409,814,1819) }
    )

    foreach ($q in $eventQueries) {
        try {
            $fh = @{ LogName = $q.Log; StartTime = $windowStart; Id = $q.Ids }
            if ($q.Provider) { $fh.ProviderName = $q.Provider }

            $events = Get-WinEvent -FilterHashtable $fh -ErrorAction Stop |
                Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, MachineName, Message

            $csvPath = Join-Path $out ($q.Name + '.csv')
            $events | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
            Add-ArtifactPath $csvPath
        } catch {
            Write-RunLog -Level 'WARN' -Section 'T06' -Message "Event query failed for $($q.Name): $($_.Exception.Message)"
            Add-SkippedItem "T06 event query failed: $($q.Name)"
        }
    }
}

# T07: Collect policy and startup diagnostics
# Purpose:
# - Capture policy results and startup entries potentially affected by deployment.
# Collected Data:
# - gpresult output, startup run keys, app-related scheduled tasks.
# Expected Output:
# - TXT/JSON/CSV in 50_Diagnostics.
Invoke-SafeStep -StepId 'T07' -Title 'Policy and startup diagnostics' -Purpose 'Detect startup/policy regressions linked to app rollout.' -Action {
    $out = Join-Path $script:Run.OutputFolder '50_Diagnostics'

    try {
        gpresult /R /SCOPE COMPUTER | Out-File -FilePath (Join-Path $out 'gpresult_computer.txt') -Encoding UTF8
        Add-ArtifactPath (Join-Path $out 'gpresult_computer.txt')
    } catch {
        throw "gpresult computer failed: $($_.Exception.Message)"
    }

    try {
        gpresult /R /SCOPE USER | Out-File -FilePath (Join-Path $out 'gpresult_user.txt') -Encoding UTF8
        Add-ArtifactPath (Join-Path $out 'gpresult_user.txt')
    } catch {
        throw "gpresult user failed: $($_.Exception.Message)"
    }

    try {
        $startupObjects = @()

        try {
            $hklm = Get-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run' -ErrorAction Stop
            $startupObjects += [pscustomobject]@{ Hive='HKLM'; Properties=$hklm }
        } catch {
            Write-RunLog -Level 'WARN' -Section 'T07' -Message "HKLM Run key read failed: $($_.Exception.Message)"
            Add-SkippedItem 'T07 HKLM Run key unavailable.'
        }

        try {
            $hkcu = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -ErrorAction Stop
            $startupObjects += [pscustomobject]@{ Hive='HKCU'; Properties=$hkcu }
        } catch {
            Write-RunLog -Level 'WARN' -Section 'T07' -Message "HKCU Run key read failed: $($_.Exception.Message)"
            Add-SkippedItem 'T07 HKCU Run key unavailable.'
        }

        $startupJson = Join-Path $out 'startup_run_keys.json'
        $startupObjects | ConvertTo-Json -Depth 6 | Out-File -FilePath $startupJson -Encoding UTF8
        Add-ArtifactPath $startupJson
    } catch {
        throw "Startup key collection failed: $($_.Exception.Message)"
    }

    try {
        $tasks = Get-ScheduledTask -ErrorAction Stop |
            Where-Object { $_.TaskName -like "*$AppName*" -or $_.TaskPath -like "*$AppName*" } |
            Select-Object TaskName, TaskPath, State, Author, Description

        $taskCsv = Join-Path $out 'scheduled_tasks_related.csv'
        $tasks | Export-Csv -Path $taskCsv -NoTypeInformation -Encoding UTF8
        Add-ArtifactPath $taskCsv
    } catch {
        Write-RunLog -Level 'WARN' -Section 'T07' -Message "Scheduled task query failed: $($_.Exception.Message)"
        Add-SkippedItem 'T07 scheduled task query unavailable.'
    }
}

# T08: Collect service evidence related to app keyword
# Purpose:
# - Identify app-linked services that may delay or fail at startup/login.
# Collected Data:
# - Service name/display/status/start type.
# Expected Output:
# - CSV in 40_Config.
Invoke-SafeStep -StepId 'T08' -Title 'Service evidence collection' -Purpose 'Capture app-related services for startup impact analysis.' -Action {
    $out = Join-Path $script:Run.OutputFolder '40_Config'

    try {
        $svc = Get-Service -ErrorAction Stop |
            Where-Object { $_.Name -like "*$AppName*" -or $_.DisplayName -like "*$AppName*" } |
            Select-Object Name, DisplayName, Status, StartType

        $csv = Join-Path $out 'services_related.csv'
        $svc | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
        Add-ArtifactPath $csv
    } catch {
        throw "Service evidence collection failed: $($_.Exception.Message)"
    }
}

# T09: Build manifests and package output
# Purpose:
# - Produce structured outputs for independent continuation by another engineer.
# Collected Data:
# - Step results, manifest, summary, and archive.
# Expected Output:
# - JSON/TXT/CSV summary files and ZIP archive.
Invoke-SafeStep -StepId 'T09' -Title 'Manifest and packaging' -Purpose 'Create audit-ready summary and evidence package archive.' -Action {
    $sum = Join-Path $script:Run.OutputFolder '90_Summary'

    try {
        $stepsCsv = Join-Path $sum 'collection_steps.csv'
        $script:Run.Steps | Export-Csv -Path $stepsCsv -NoTypeInformation -Encoding UTF8
        Add-ArtifactPath $stepsCsv
    } catch {
        throw "Failed writing collection_steps.csv: $($_.Exception.Message)"
    }

    try {
        $manifestCsv = Join-Path $sum 'artifact_manifest.csv'
        $manifest = foreach ($a in $script:Run.CollectedArtifacts) {
            [pscustomobject]@{ ArtifactPath = $a; Exists = (Test-Path -Path $a) }
        }
        $manifest | Export-Csv -Path $manifestCsv -NoTypeInformation -Encoding UTF8
        Add-ArtifactPath $manifestCsv
    } catch {
        throw "Failed writing artifact_manifest.csv: $($_.Exception.Message)"
    }

    try {
        $script:Run.EndTime = Get-Date
        $script:Run.DurationMinutes = [math]::Round((New-TimeSpan -Start $script:Run.StartTime -End $script:Run.EndTime).TotalMinutes, 2)
        $script:Run.Status = if ($script:Run.Errors.Count -gt 0) { 'CompletedWithErrors' } else { 'Completed' }

        $json = Join-Path $sum 'run_summary.json'
        $txt = Join-Path $sum 'run_summary.txt'

        $script:Run | ConvertTo-Json -Depth 8 | Out-File -FilePath $json -Encoding UTF8
        Add-ArtifactPath $json

        @(
            'DWP Floor 6 Evidence Collection Summary',
            "RunId               : $($script:Run.RunId)",
            "ScriptVersion       : $($script:Run.ScriptVersion)",
            "Status              : $($script:Run.Status)",
            "SuspectedCause      : $($script:Run.SuspectedCause)",
            "ComputerName        : $($script:Run.ComputerName)",
            "UserName            : $($script:Run.UserName)",
            "StartTime           : $($script:Run.StartTime)",
            "EndTime             : $($script:Run.EndTime)",
            "DurationMinutes     : $($script:Run.DurationMinutes)",
            "ArtifactsCollected  : $($script:Run.CollectedArtifacts.Count)",
            "SkippedItems        : $($script:Run.SkippedItems.Count)",
            "Errors              : $($script:Run.Errors.Count)",
            "OutputFolder        : $($script:Run.OutputFolder)",
            "LogFile             : $($script:Run.LogFile)",
            'Next Reviewer Actions:',
            '1. Compare deployment assignment/install evidence against unaffected pool device (to confirm).',
            '2. Correlate event timestamps across T04 and T06 outputs.',
            '3. Determine whether evidence supports or rules out deployment-cause hypothesis.'
        ) | Out-File -FilePath $txt -Encoding UTF8
        Add-ArtifactPath $txt
    } catch {
        throw "Failed writing run summary outputs: $($_.Exception.Message)"
    }

    try {
        $script:Run.ZipFile = "{0}.zip" -f $script:Run.OutputFolder
        if (Test-Path -Path $script:Run.ZipFile) {
            Remove-Item -Path $script:Run.ZipFile -Force
        }
        Compress-Archive -Path (Join-Path $script:Run.OutputFolder '*') -DestinationPath $script:Run.ZipFile -Force
        Add-ArtifactPath $script:Run.ZipFile
    } catch {
        throw "Compress-Archive failed: $($_.Exception.Message)"
    }
}

# T10: Final console summary
# Purpose:
# - Provide actionable run outcome to engineer at console.
# Collected Data:
# - None.
# Expected Output:
# - Structured status, artifact list, skipped items, and errors.
if ($DryRun) {
    $script:Run.EndTime = Get-Date
    $script:Run.DurationMinutes = [math]::Round((New-TimeSpan -Start $script:Run.StartTime -End $script:Run.EndTime).TotalMinutes, 2)
    $script:Run.Status = 'DryRunOnly'
}

Write-Host ''
Write-Host '================ DWP Floor 6 Evidence Collection ================'
Write-Host ("RunId              : {0}" -f $script:Run.RunId)
Write-Host ("Status             : {0}" -f $script:Run.Status)
Write-Host ("DryRun             : {0}" -f $script:Run.DryRun)
Write-Host ("Suspected Cause    : {0}" -f $script:Run.SuspectedCause)
Write-Host ("Output Folder      : {0}" -f $script:Run.OutputFolder)
Write-Host ("Collected Artifacts: {0}" -f $script:Run.CollectedArtifacts.Count)
Write-Host ("Skipped Items      : {0}" -f $script:Run.SkippedItems.Count)
Write-Host ("Errors             : {0}" -f $script:Run.Errors.Count)
Write-Host '-----------------------------------------------------------------'

if ($script:Run.CollectedArtifacts.Count -gt 0) {
    Write-Host 'Artifacts:'
    foreach ($a in $script:Run.CollectedArtifacts) {
        Write-Host (" - {0}" -f $a)
    }
}

if ($script:Run.SkippedItems.Count -gt 0) {
    Write-Host 'Skipped:'
    foreach ($s in $script:Run.SkippedItems) {
        Write-Host (" - {0}" -f $s)
    }
}

if ($script:Run.Errors.Count -gt 0) {
    Write-Host 'Errors:'
    foreach ($e in $script:Run.Errors) {
        Write-Host (" - {0}" -f $e)
    }
}

Write-Host '================================================================='
