<#
.SYNOPSIS
Collects Floor 6 endpoint evidence for suspected deployment assignment/config conflict.

.DESCRIPTION
AI-Generated Version (initial output).
PowerShell 5.1 script to gather read-only evidence from a Windows endpoint.
Includes dry-run mode, timestamped logging, error handling, structured outputs,
and evidence package generation for handoff.

.PARAMETER DryRun
Shows actions the script would take without collecting data or writing files.

.PARAMETER AppName
Application name keyword to target in logs/config (default: DMS-Client).

.PARAMETER LookbackDays
How many days back to query logs.

.PARAMETER OutputRoot
Root folder where evidence package will be created.
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$AppName = 'DMS-Client',
    [int]$LookbackDays = 7,
    [string]$OutputRoot = 'C:\Temp\DWP_Floor6_Evidence'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Section: Runtime state and summary tracking
# Purpose: Keep an auditable record of actions, outputs, warnings, and errors.
$script:Summary = [ordered]@{
    ScriptVersion = 'AI-Generated'
    StartTime = Get-Date
    ComputerName = $env:COMPUTERNAME
    UserName = $env:USERNAME
    DryRun = [bool]$DryRun
    AppName = $AppName
    LookbackDays = $LookbackDays
    OutputFolder = $null
    LogFile = $null
    Status = 'Running'
    Steps = New-Object System.Collections.ArrayList
    Artifacts = New-Object System.Collections.ArrayList
    SkippedItems = New-Object System.Collections.ArrayList
    Errors = New-Object System.Collections.ArrayList
}

function Write-Console {
    param(
        [string]$Level,
        [string]$Message
    )
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Write-Host "[$ts] [$Level] $Message"
}

function Write-Log {
    param(
        [string]$Level,
        [string]$Message,
        [string]$StepName = 'General'
    )

    $line = "{0}`t{1}`t{2}`t{3}" -f (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff'), $Level, $StepName, $Message
    Write-Console -Level $Level -Message "$StepName - $Message"

    if (-not $DryRun -and $script:Summary.LogFile) {
        try {
            Add-Content -Path $script:Summary.LogFile -Value $line -Encoding UTF8
        } catch {
            Write-Host "[WARN] Failed to write log file: $($_.Exception.Message)"
        }
    }
}

function Add-StepResult {
    param(
        [string]$Step,
        [string]$Status,
        [string]$Detail
    )
    [void]$script:Summary.Steps.Add([pscustomobject]@{
        Time = (Get-Date).ToString('s')
        Step = $Step
        Status = $Status
        Detail = $Detail
    })
}

function Add-Artifact {
    param([string]$Path)
    [void]$script:Summary.Artifacts.Add($Path)
}

function Add-Skipped {
    param([string]$Message)
    [void]$script:Summary.SkippedItems.Add($Message)
}

function Add-Err {
    param([string]$Message)
    [void]$script:Summary.Errors.Add($Message)
}

function New-UniqueFolder {
    param([string]$BasePath)

    $candidate = $BasePath
    $counter = 1
    while (Test-Path -Path $candidate) {
        $candidate = "{0}_{1:D2}" -f $BasePath, $counter
        $counter++
    }
    New-Item -Path $candidate -ItemType Directory -Force | Out-Null
    return $candidate
}

function Invoke-CollectionStep {
    param(
        [string]$StepName,
        [string]$Description,
        [scriptblock]$Action
    )

    if ($DryRun) {
        Write-Log -Level 'INFO' -StepName $StepName -Message "DRY-RUN: Would perform step. $Description"
        Add-StepResult -Step $StepName -Status 'Skipped(DryRun)' -Detail $Description
        Add-Skipped "$StepName (dry-run)"
        return
    }

    try {
        Write-Log -Level 'INFO' -StepName $StepName -Message "Starting. $Description"
        & $Action
        Write-Log -Level 'SUCCESS' -StepName $StepName -Message 'Completed successfully.'
        Add-StepResult -Step $StepName -Status 'Success' -Detail $Description
    } catch {
        $msg = $_.Exception.Message
        Write-Log -Level 'ERROR' -StepName $StepName -Message $msg
        Add-StepResult -Step $StepName -Status 'Error' -Detail $msg
        Add-Err "$StepName: $msg"
    }
}

# Section: Prepare output folder and structure
# Purpose: Ensure idempotent output by creating a unique, timestamped evidence folder.
# Expected output: Root folder with subfolders for system, logs, config, diagnostics, and summary.
if ($DryRun) {
    $plannedFolder = Join-Path $OutputRoot ("{0}_{1}" -f $env:COMPUTERNAME, (Get-Date -Format 'yyyyMMdd_HHmmss'))
    $script:Summary.OutputFolder = $plannedFolder
    Write-Log -Level 'INFO' -StepName 'Init' -Message "DRY-RUN: Would create output structure at $plannedFolder"
} else {
    try {
        if (-not (Test-Path $OutputRoot)) {
            New-Item -Path $OutputRoot -ItemType Directory -Force | Out-Null
        }
        $base = Join-Path $OutputRoot ("{0}_{1}" -f $env:COMPUTERNAME, (Get-Date -Format 'yyyyMMdd'))
        $evidenceFolder = New-UniqueFolder -BasePath $base
        $script:Summary.OutputFolder = $evidenceFolder

        $null = New-Item -Path (Join-Path $evidenceFolder 'System') -ItemType Directory -Force
        $null = New-Item -Path (Join-Path $evidenceFolder 'Logs') -ItemType Directory -Force
        $null = New-Item -Path (Join-Path $evidenceFolder 'Config') -ItemType Directory -Force
        $null = New-Item -Path (Join-Path $evidenceFolder 'Diagnostics') -ItemType Directory -Force
        $null = New-Item -Path (Join-Path $evidenceFolder 'Summary') -ItemType Directory -Force

        $script:Summary.LogFile = Join-Path $evidenceFolder ("collector_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
        New-Item -Path $script:Summary.LogFile -ItemType File -Force | Out-Null
        Write-Log -Level 'INFO' -StepName 'Init' -Message "Output initialized at $evidenceFolder"
        Add-Artifact $script:Summary.LogFile
    } catch {
        Write-Host "[FATAL] Failed to initialize output folder: $($_.Exception.Message)"
        throw
    }
}

$startTime = (Get-Date).AddDays(-$LookbackDays)

# Section: System profile evidence
# Purpose: Capture endpoint identity, OS build, and hardware context.
# Expected output: JSON and TXT files under System.
Invoke-CollectionStep -StepName 'SystemInfo' -Description 'Collect computer info and OS details.' -Action {
    $systemDir = Join-Path $script:Summary.OutputFolder 'System'
    Get-ComputerInfo | ConvertTo-Json -Depth 4 | Out-File -FilePath (Join-Path $systemDir 'computer_info.json') -Encoding UTF8
    Add-Artifact (Join-Path $systemDir 'computer_info.json')

    systeminfo | Out-File -FilePath (Join-Path $systemDir 'systeminfo.txt') -Encoding UTF8
    Add-Artifact (Join-Path $systemDir 'systeminfo.txt')

    Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object * | ConvertTo-Json -Depth 4 | Out-File -FilePath (Join-Path $systemDir 'os_cim.json') -Encoding UTF8
    Add-Artifact (Join-Path $systemDir 'os_cim.json')
}

# Section: User and network context
# Purpose: Capture current user security context and network configuration.
# Expected output: whoami and ipconfig text files.
Invoke-CollectionStep -StepName 'UserNetworkContext' -Description 'Collect user token and network configuration.' -Action {
    $systemDir = Join-Path $script:Summary.OutputFolder 'System'
    whoami /all | Out-File -FilePath (Join-Path $systemDir 'whoami_all.txt') -Encoding UTF8
    Add-Artifact (Join-Path $systemDir 'whoami_all.txt')

    ipconfig /all | Out-File -FilePath (Join-Path $systemDir 'ipconfig_all.txt') -Encoding UTF8
    Add-Artifact (Join-Path $systemDir 'ipconfig_all.txt')
}

# Section: Deployment and app install evidence
# Purpose: Capture app assignment and installation traces for suspected deployment issue.
# Expected output: Raw copied logs and filtered extract.
Invoke-CollectionStep -StepName 'DeploymentLogs' -Description 'Collect Intune/endpoint deployment logs and extract app-related lines.' -Action {
    $logDir = Join-Path $script:Summary.OutputFolder 'Logs'
    $intunePaths = @(
        'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log',
        'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\AgentExecutor.log'
    )

    foreach ($p in $intunePaths) {
        try {
            if (Test-Path $p) {
                $dest = Join-Path $logDir ([IO.Path]::GetFileName($p))
                Copy-Item -Path $p -Destination $dest -Force
                Add-Artifact $dest
            } else {
                Write-Log -Level 'WARN' -StepName 'DeploymentLogs' -Message "Path not found: $p"
                Add-Skipped "Missing file: $p"
            }
        } catch {
            throw
        }
    }

    $extract = Join-Path $logDir 'deployment_app_extract.txt'
    $patterns = @($AppName, 'InstallState', 'ErrorCode', 'DetectionRule', 'Assignment received')
    foreach ($copied in Get-ChildItem -Path $logDir -Filter '*.log' -ErrorAction SilentlyContinue) {
        foreach ($pattern in $patterns) {
            Select-String -Path $copied.FullName -Pattern $pattern -SimpleMatch -ErrorAction SilentlyContinue |
                ForEach-Object { "{0}`t{1}`t{2}" -f $copied.Name, $_.LineNumber, $_.Line } |
                Out-File -FilePath $extract -Encoding UTF8 -Append
        }
    }
    if (Test-Path $extract) { Add-Artifact $extract }
}

# Section: App presence and uninstall registry evidence
# Purpose: Validate whether app is installed, partially installed, or absent.
# Expected output: CSV/JSON export of app matches from uninstall registry keys.
Invoke-CollectionStep -StepName 'AppRegistryEvidence' -Description 'Collect uninstall registry entries matching target app.' -Action {
    $cfgDir = Join-Path $script:Summary.OutputFolder 'Config'
    $paths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    $apps = foreach ($path in $paths) {
        try {
            Get-ItemProperty -Path $path -ErrorAction Stop |
                Where-Object { $_.DisplayName -and $_.DisplayName -like "*$AppName*" } |
                Select-Object PSPath, DisplayName, DisplayVersion, Publisher, InstallDate, UninstallString
        } catch {
            Write-Log -Level 'WARN' -StepName 'AppRegistryEvidence' -Message "Failed query path $path : $($_.Exception.Message)"
            Add-Skipped "Registry path query failed: $path"
        }
    }

    $csv = Join-Path $cfgDir 'app_registry_matches.csv'
    $json = Join-Path $cfgDir 'app_registry_matches.json'
    $apps | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
    $apps | ConvertTo-Json -Depth 4 | Out-File -FilePath $json -Encoding UTF8
    Add-Artifact $csv
    Add-Artifact $json
}

# Section: Event logs tied to deployment and login symptoms
# Purpose: Gather event evidence for install failures and login/profile delays.
# Expected output: CSV files for each event source.
Invoke-CollectionStep -StepName 'EventLogs' -Description 'Collect MSI, GroupPolicy, User Profile, and DeviceManagement events.' -Action {
    $logDir = Join-Path $script:Summary.OutputFolder 'Logs'

    $queries = @(
        @{ Name = 'Application_MsiInstaller'; LogName = 'Application'; ProviderName = 'MsiInstaller'; Ids = @(11707, 11708, 1033) },
        @{ Name = 'GroupPolicy_Operational'; LogName = 'Microsoft-Windows-GroupPolicy/Operational'; ProviderName = $null; Ids = @(1129, 5312, 5317, 5326) },
        @{ Name = 'UserProfileService_Application'; LogName = 'Application'; ProviderName = 'User Profile Service'; Ids = @(1511, 1515, 1530, 1534) },
        @{ Name = 'DeviceManagement_Admin'; LogName = 'Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin'; ProviderName = $null; Ids = @(404, 409, 814, 1819) }
    )

    foreach ($q in $queries) {
        try {
            $fh = @{ LogName = $q.LogName; StartTime = $startTime; Id = $q.Ids }
            if ($q.ProviderName) { $fh.ProviderName = $q.ProviderName }
            $events = Get-WinEvent -FilterHashtable $fh -ErrorAction Stop |
                Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, MachineName, Message

            $out = Join-Path $logDir ("{0}.csv" -f $q.Name)
            $events | Export-Csv -Path $out -NoTypeInformation -Encoding UTF8
            Add-Artifact $out
        } catch {
            Write-Log -Level 'WARN' -StepName 'EventLogs' -Message "Could not collect $($q.Name): $($_.Exception.Message)"
            Add-Skipped "Event log unavailable: $($q.Name)"
        }
    }
}

# Section: Policy and startup diagnostics
# Purpose: Collect policy results and startup entries that might affect logon performance.
# Expected output: GPResult and startup inventory files.
Invoke-CollectionStep -StepName 'PolicyStartupDiagnostics' -Description 'Collect gpresult and startup item inventory.' -Action {
    $diagDir = Join-Path $script:Summary.OutputFolder 'Diagnostics'

    gpresult /R /SCOPE COMPUTER | Out-File -FilePath (Join-Path $diagDir 'gpresult_computer.txt') -Encoding UTF8
    Add-Artifact (Join-Path $diagDir 'gpresult_computer.txt')

    gpresult /R /SCOPE USER | Out-File -FilePath (Join-Path $diagDir 'gpresult_user.txt') -Encoding UTF8
    Add-Artifact (Join-Path $diagDir 'gpresult_user.txt')

    $startup = @()
    $startup += Get-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run' -ErrorAction SilentlyContinue |
        Select-Object *
    $startup += Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -ErrorAction SilentlyContinue |
        Select-Object *

    $startup | ConvertTo-Json -Depth 4 | Out-File -FilePath (Join-Path $diagDir 'startup_run_keys.json') -Encoding UTF8
    Add-Artifact (Join-Path $diagDir 'startup_run_keys.json')

    Get-ScheduledTask -ErrorAction SilentlyContinue |
        Where-Object { $_.TaskName -like "*$AppName*" -or $_.TaskPath -like "*$AppName*" } |
        Select-Object TaskName, TaskPath, State, Author, Description |
        Export-Csv -Path (Join-Path $diagDir 'scheduled_tasks_related.csv') -NoTypeInformation -Encoding UTF8
    Add-Artifact (Join-Path $diagDir 'scheduled_tasks_related.csv')
}

# Section: Service inventory for target app
# Purpose: Identify service-level dependencies introduced by deployment.
# Expected output: CSV list of services matching app keyword.
Invoke-CollectionStep -StepName 'ServiceEvidence' -Description 'Collect services matching app name pattern.' -Action {
    $cfgDir = Join-Path $script:Summary.OutputFolder 'Config'
    Get-Service |
        Where-Object { $_.Name -like "*$AppName*" -or $_.DisplayName -like "*$AppName*" } |
        Select-Object Name, DisplayName, Status, StartType |
        Export-Csv -Path (Join-Path $cfgDir 'services_related.csv') -NoTypeInformation -Encoding UTF8
    Add-Artifact (Join-Path $cfgDir 'services_related.csv')
}

# Section: Build package manifest and archive
# Purpose: Provide a structured, portable package for peer investigation.
# Expected output: JSON summary, CSV step report, and ZIP archive.
Invoke-CollectionStep -StepName 'PackageOutput' -Description 'Write summary artifacts and compress evidence folder.' -Action {
    $sumDir = Join-Path $script:Summary.OutputFolder 'Summary'

    $stepsCsv = Join-Path $sumDir 'collection_steps.csv'
    $script:Summary.Steps | Export-Csv -Path $stepsCsv -NoTypeInformation -Encoding UTF8
    Add-Artifact $stepsCsv

    $summaryJson = Join-Path $sumDir 'summary.json'
    $summaryTxt = Join-Path $sumDir 'summary.txt'

    $script:Summary.EndTime = Get-Date
    $script:Summary.DurationMinutes = [math]::Round((New-TimeSpan -Start $script:Summary.StartTime -End $script:Summary.EndTime).TotalMinutes, 2)
    $script:Summary.Status = if ($script:Summary.Errors.Count -gt 0) { 'CompletedWithErrors' } else { 'Completed' }

    $script:Summary | ConvertTo-Json -Depth 6 | Out-File -FilePath $summaryJson -Encoding UTF8
    Add-Artifact $summaryJson

    @(
        "Collection Status : $($script:Summary.Status)",
        "Computer Name     : $($script:Summary.ComputerName)",
        "Start Time        : $($script:Summary.StartTime)",
        "End Time          : $($script:Summary.EndTime)",
        "Duration (min)    : $($script:Summary.DurationMinutes)",
        "Artifacts         : $($script:Summary.Artifacts.Count)",
        "Skipped Items     : $($script:Summary.SkippedItems.Count)",
        "Errors            : $($script:Summary.Errors.Count)",
        "Output Folder     : $($script:Summary.OutputFolder)",
        "Log File          : $($script:Summary.LogFile)"
    ) | Out-File -FilePath $summaryTxt -Encoding UTF8
    Add-Artifact $summaryTxt

    $zipPath = "{0}.zip" -f $script:Summary.OutputFolder
    Compress-Archive -Path (Join-Path $script:Summary.OutputFolder '*') -DestinationPath $zipPath -Force
    Add-Artifact $zipPath
}

# Section: End-of-run summary output
# Purpose: Provide actionable handoff details to next engineer.
# Expected output: Console summary with statuses, errors, and key artifacts.
if ($DryRun) {
    $script:Summary.Status = 'DryRunOnly'
    $script:Summary.EndTime = Get-Date
    $script:Summary.DurationMinutes = [math]::Round((New-TimeSpan -Start $script:Summary.StartTime -End $script:Summary.EndTime).TotalMinutes, 2)
}

Write-Host ''
Write-Host '================ Evidence Collection Summary ================'
Write-Host ("Status         : {0}" -f $script:Summary.Status)
Write-Host ("Computer       : {0}" -f $script:Summary.ComputerName)
Write-Host ("Dry Run        : {0}" -f $script:Summary.DryRun)
Write-Host ("Output Folder  : {0}" -f $script:Summary.OutputFolder)
Write-Host ("Artifacts      : {0}" -f $script:Summary.Artifacts.Count)
Write-Host ("Skipped        : {0}" -f $script:Summary.SkippedItems.Count)
Write-Host ("Errors         : {0}" -f $script:Summary.Errors.Count)
Write-Host '------------------------------------------------------------'

if ($script:Summary.Artifacts.Count -gt 0) {
    Write-Host 'Collected artifacts:'
    $script:Summary.Artifacts | ForEach-Object { Write-Host " - $_" }
}

if ($script:Summary.SkippedItems.Count -gt 0) {
    Write-Host 'Skipped items:'
    $script:Summary.SkippedItems | ForEach-Object { Write-Host " - $_" }
}

if ($script:Summary.Errors.Count -gt 0) {
    Write-Host 'Errors encountered:'
    $script:Summary.Errors | ForEach-Object { Write-Host " - $_" }
}

Write-Host '============================================================'
