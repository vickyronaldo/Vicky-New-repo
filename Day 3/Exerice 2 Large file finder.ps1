<#
.SYNOPSIS
    Large File Finder Script for DWP engineers (PowerShell 5.1)

.DESCRIPTION
    Strictly read-only script that scans one or more paths and reports files larger than
    a configurable threshold.

    Key behavior:
    - No delete, move, rename, or write operations are performed
    - Threshold is user input in MB (default: 100 MB)
    - Default scan scope is all fixed local drives if no path is provided

.PARAMETER ThresholdMB
    File size threshold in MB. Files with size greater than or equal to this value are reported.
    Default: 100

.PARAMETER ScanPaths
    Optional path list to scan. If omitted, all fixed local drives are scanned.

.EXAMPLE
    .\Exerice 2 Large file finder.ps1

.EXAMPLE
    .\Exerice 2 Large file finder.ps1 -ThresholdMB 250

.EXAMPLE
    .\Exerice 2 Large file finder.ps1 -ThresholdMB 500 -ScanPaths "C:\Users","D:\Data"
#>

[CmdletBinding()]
param(
    [ValidateRange(1, [int]::MaxValue)]
    [int]$ThresholdMB = 100,

    [string[]]$ScanPaths
)

$ErrorActionPreference = 'Stop'

function Write-Section {
    <#
    Section purpose:
    Print a section header to make report output easier to read.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title
    )

    Write-Host ''
    Write-Host ('=' * 72)
    Write-Host $Title
    Write-Host ('=' * 72)
}

function Convert-BytesToMB {
    <#
    Section purpose:
    Convert bytes to MB for human-readable reporting.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [Int64]$Bytes
    )

    return [math]::Round(($Bytes / 1MB), 2)
}

function Convert-BytesToGB {
    <#
    Section purpose:
    Convert bytes to GB for human-readable reporting.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [Int64]$Bytes
    )

    return [math]::Round(($Bytes / 1GB), 2)
}

# SECTION 1: INPUT VALIDATION
# Description: Validate threshold and resolve scan paths.
Write-Section -Title '1. Input validation and scan scope'

$thresholdBytes = [int64]$ThresholdMB * 1MB
Write-Host ("Threshold: {0} MB" -f $ThresholdMB)

if (-not $PSBoundParameters.ContainsKey('ScanPaths') -or -not $ScanPaths) {
    # [VERIFY BEFORE RUNNING]: Default behavior scans all fixed local drives and may take time.
    $ScanPaths = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType = 3" |
        Select-Object -ExpandProperty DeviceID |
        ForEach-Object { "{0}\" -f $_ }
}

$validScanPaths = @()
foreach ($path in $ScanPaths) {
    if (Test-Path -Path $path) {
        $validScanPaths += $path
    }
    else {
        Write-Warning ("Path not found and will be skipped: {0}" -f $path)
    }
}

if (-not $validScanPaths -or $validScanPaths.Count -eq 0) {
    throw 'No valid scan paths found. Provide at least one existing path via -ScanPaths.'
}

Write-Host 'Scan paths:'
$validScanPaths | ForEach-Object { Write-Host (" - {0}" -f $_) }

# SECTION 2: FILE DISCOVERY (READ-ONLY)
# Description: Recursively list files and filter those at or above the threshold.
# [VERIFY BEFORE RUNNING]: Recursive scans of broad roots (for example C:\) can be lengthy.
Write-Section -Title '2. Read-only scan for large files'

$results = @()
foreach ($scanPath in $validScanPaths) {
    Write-Host ("Scanning: {0}" -f $scanPath)

    try {
        $largeFiles = Get-ChildItem -Path $scanPath -File -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.Length -ge $thresholdBytes } |
            ForEach-Object {
                [PSCustomObject]@{
                    FileName      = $_.Name
                    FullPath      = $_.FullName
                    SizeMB        = Convert-BytesToMB -Bytes $_.Length
                    SizeGB        = Convert-BytesToGB -Bytes $_.Length
                    LastWriteTime = $_.LastWriteTime
                }
            }

        if ($largeFiles) {
            $results += $largeFiles
        }
    }
    catch {
        Write-Warning ("Scan error on path '{0}': {1}" -f $scanPath, $_.Exception.Message)
    }
}

# SECTION 3: REPORT OUTPUT
# Description: Display summary and detailed report of large files found.
Write-Section -Title '3. Large file report'

if (-not $results -or $results.Count -eq 0) {
    Write-Host ("No files found at or above {0} MB." -f $ThresholdMB)
}
else {
    $sortedResults = $results | Sort-Object -Property SizeMB -Descending

    Write-Host ("Total files found: {0}" -f $sortedResults.Count)

    # Top 20 quick-view table for immediate triage
    $sortedResults |
        Select-Object -First 20 FileName, SizeMB, SizeGB, LastWriteTime, FullPath |
        Format-Table -AutoSize -Wrap

    # Full detail list for complete audit review
    Write-Section -Title '4. Full result list (all matches)'
    $sortedResults |
        Select-Object FileName, SizeMB, SizeGB, LastWriteTime, FullPath |
        Format-List
}

# SECTION 5: END OF RUN
# Description: End marker confirming the script is strictly read-only.
Write-Host ''
Write-Host ('=' * 72)
Write-Host 'END OF LARGE FILE FINDER REPORT'
Write-Host ('=' * 72)
Write-Host 'Read-only run complete. No system changes were made.' -ForegroundColor Green
