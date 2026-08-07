<#
.SYNOPSIS
	Startup Program Auditor for DWP engineers (PowerShell 5.1).

.DESCRIPTION
	Strictly read-only daily audit that lists startup programs from common registry Run keys
	and Startup folders. This script does not make any changes to system state.

.EXAMPLE
	.\startup_program_auditor.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

function Write-Section {
	<#
	Section purpose:
	Print a clear section header in the console output.
	#>
	param(
		[Parameter(Mandatory = $true)]
		[string]$Title
	)

	Write-Host ""
	Write-Host ('=' * 72)
	Write-Host $Title
	Write-Host ('=' * 72)
}

function Get-RegistryStartupEntries {
	<#
	Section purpose:
	Collect startup entries from registry Run keys.
	Read-only operation: only reads key values.
	#>
	# [VERIFY BEFORE RUNNING]: Confirm these registry paths are the ones your environment wants audited.
	$runLocations = @(
		@{ Scope = 'CurrentUser'; Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'; Source = 'Registry Run (HKCU)' },
		@{ Scope = 'AllUsers'; Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run'; Source = 'Registry Run (HKLM)' },
		@{ Scope = 'AllUsers32'; Path = 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'; Source = 'Registry Run (HKLM Wow6432Node)' }
	)

	$entries = @()

	foreach ($location in $runLocations) {
		if (-not (Test-Path -Path $location.Path)) {
			continue
		}

		$item = Get-ItemProperty -Path $location.Path
		$valueProps = $item.PSObject.Properties | Where-Object {
			$_.Name -notmatch '^PS(.*)'
		}

		foreach ($prop in $valueProps) {
			$entries += [PSCustomObject]@{
				DisplayName = $prop.Name
				Scope       = $location.Scope
				Source      = $location.Source
				Command     = [string]$prop.Value
				Location    = $location.Path
			}
		}
	}

	return $entries
}

function Get-StartupFolderEntries {
	<#
	Section purpose:
	Collect startup entries from Startup folders.
	Read-only operation: only lists files.
	#>
	# [VERIFY BEFORE RUNNING]: Confirm these Startup folder paths are valid for your endpoint baseline.
	$folderLocations = @(
		@{ Scope = 'CurrentUser'; Path = [Environment]::GetFolderPath('Startup'); Source = 'Startup Folder (CurrentUser)' },
		@{ Scope = 'AllUsers'; Path = (Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs\Startup'); Source = 'Startup Folder (AllUsers)' }
	)

	$entries = @()

	foreach ($folder in $folderLocations) {
		if (-not (Test-Path -Path $folder.Path)) {
			continue
		}

		$files = Get-ChildItem -Path $folder.Path -File -ErrorAction SilentlyContinue
		foreach ($file in $files) {
			$entries += [PSCustomObject]@{
				DisplayName = $file.BaseName
				Scope       = $folder.Scope
				Source      = $folder.Source
				Command     = $file.FullName
				Location    = $folder.Path
			}
		}
	}

	return $entries
}

function Get-AllStartupEntries {
	<#
	Section purpose:
	Combine registry-based and folder-based startup entries into one report list.
	#>
	$combined = @()
	$combined += Get-RegistryStartupEntries
	$combined += Get-StartupFolderEntries

	return $combined | Sort-Object Scope, Source, DisplayName
}

# SECTION 1: REPORT HEADER
# Description: Shows metadata about where and when the read-only audit is run.
Write-Host 'Startup Program Auditor (Strictly Read-Only)'
Write-Host ('-' * 72)
Write-Host ("Computer Name: {0}" -f $env:COMPUTERNAME)
Write-Host ("Generated At : {0}" -f (Get-Date))

# SECTION 2: STARTUP INVENTORY COLLECTION
# Description: Reads startup entries from registry and Startup folders.
Write-Section -Title 'Startup program inventory (read-only)'
$startupEntries = Get-AllStartupEntries

# SECTION 3: STARTUP INVENTORY OUTPUT
# Description: Prints the startup inventory in table format for daily audit use.
if (-not $startupEntries -or $startupEntries.Count -eq 0) {
	Write-Host 'No startup entries were found in the audited locations.'
}
else {
	$startupEntries |
		Select-Object DisplayName, Scope, Source, Command, Location |
		Format-Table -AutoSize

	Write-Host ("Total startup entries found: {0}" -f $startupEntries.Count)
}

# SECTION 4: END OF REPORT
# Description: Confirms completion and restates that the script is non-invasive.
Write-Host ''
Write-Host ('=' * 72)
Write-Host 'END OF STARTUP PROGRAM AUDIT'
Write-Host ('=' * 72)
Write-Host 'Read-only run complete. No system changes were made.' -ForegroundColor Green

