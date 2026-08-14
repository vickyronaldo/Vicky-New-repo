## Floor 6 Comms and Command Line

### Plain-language message to Floor 6 users
Hello Floor 6 team, we have identified that the new document management app rollout is linked to this morning's login and desktop issues, and we have paused/rolled back that deployment for affected users while we stabilize service. If you are still unable to sign in or your desktop is not loading correctly, please report it to the service desk with your device name; we will continue updates as we complete checks and will confirm when normal service is fully restored.

### Evidence-checked values from incident artifacts
- App name in deployment evidence: DMS-Client v5.4.2
- Affected ring/pool in incident evidence: POOL-FIN-01
- Unaffected comparison pool in incident evidence: POOL-FIN-02

### Command Set A - Evidence collection from affected Floor 6 endpoint (use script output)
```powershell
# Hand-Corrected script dry run (safe preview, no data write)
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\labuser\Documents\Training\Vicky Project\Powershell script\Floor6_Evidence_Collector_Hand_Corrected.ps1" -DryRun -AppName "DMS-Client" -LookbackDays 7

# Hand-Corrected script actual evidence collection
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\labuser\Documents\Training\Vicky Project\Powershell script\Floor6_Evidence_Collector_Hand_Corrected.ps1" -AppName "DMS-Client" -LookbackDays 7 -OutputRoot "C:\Temp\DWP_Floor6_Evidence"

# Optional comparison run with AI-generated script
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\labuser\Documents\Training\Vicky Project\Powershell script\Floor6_Evidence_Collector_AI_Generated.ps1" -AppName "DMS-Client" -LookbackDays 7 -OutputRoot "C:\Temp\DWP_Floor6_Evidence_AI"

# Quick check of latest evidence folders
Get-ChildItem "C:\Temp\DWP_Floor6_Evidence" -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 3 FullName,LastWriteTime
Get-ChildItem "C:\Temp\DWP_Floor6_Evidence" -Recurse -Filter "run_summary.txt" | Sort-Object LastWriteTime -Descending | Select-Object -First 1 FullName
```

### Command Set B - Pull affected devices/users from POOL-FIN-01 ring
```powershell
Install-Module Microsoft.Graph -Scope CurrentUser -Force
Connect-MgGraph -Scopes "Group.Read.All,Device.Read.All,User.Read.All"

$AFFECTED_RING_NAME = "POOL-FIN-01"
$ring = Get-MgGroup -Filter "displayName eq '$AFFECTED_RING_NAME'"
if (-not $ring) { throw "Group '$AFFECTED_RING_NAME' not found." }

Get-MgGroupMember -GroupId $ring.Id -All |
Select-Object Id,DisplayName,@{N="Type";E={$_.AdditionalProperties.'@odata.type'}},UserPrincipalName,DeviceId |
Export-Csv "C:\Temp\POOL-FIN-01_AffectedMembers.csv" -NoTypeInformation

Get-MgGroupMember -GroupId $ring.Id -All |
Where-Object { $_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.device' } |
Select-Object Id,DisplayName,DeviceId |
Export-Csv "C:\Temp\POOL-FIN-01_AffectedDevices.csv" -NoTypeInformation

Get-MgGroupMember -GroupId $ring.Id -All | Measure-Object
```

### Command Set C - Roll back by removing required app assignment for POOL-FIN-01
```powershell
Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All,Group.Read.All"
Select-MgProfile -Name "beta"

$APP_DISPLAY_NAME = "DMS-Client"
$AFFECTED_RING_NAME = "POOL-FIN-01"

$ring = Get-MgGroup -Filter "displayName eq '$AFFECTED_RING_NAME'"
if (-not $ring) { throw "Group '$AFFECTED_RING_NAME' not found." }

$app = Get-MgBetaDeviceAppManagementMobileApp -All |
Where-Object { $_.DisplayName -like "$APP_DISPLAY_NAME*" } |
Select-Object -First 1
if (-not $app) { throw "App '$APP_DISPLAY_NAME' not found." }

$assignment = Get-MgBetaDeviceAppManagementMobileAppAssignment -MobileAppId $app.Id |
Where-Object {
    $_.Intent -eq "required" -and
    $_.Target.AdditionalProperties.groupId -eq $ring.Id
} |
Select-Object -First 1

if (-not $assignment) { throw "Required assignment for '$AFFECTED_RING_NAME' not found on app '$($app.DisplayName)'." }

Remove-MgBetaDeviceAppManagementMobileAppAssignment -MobileAppId $app.Id -MobileAppAssignmentId $assignment.Id

Get-MgBetaDeviceAppManagementMobileAppAssignment -MobileAppId $app.Id |
Select-Object Id,Intent,@{N="GroupId";E={$_.Target.AdditionalProperties.groupId}},@{N="GroupName";E={(Get-MgGroup -GroupId $_.Target.AdditionalProperties.groupId).DisplayName}}
```

### Command Set D - Alternative rollback: exclude POOL-FIN-01 from required assignment
```powershell
Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All,Group.Read.All"
Select-MgProfile -Name "beta"

$APP_DISPLAY_NAME = "DMS-Client"
$AFFECTED_RING_NAME = "POOL-FIN-01"

$ring = Get-MgGroup -Filter "displayName eq '$AFFECTED_RING_NAME'"
if (-not $ring) { throw "Group '$AFFECTED_RING_NAME' not found." }

$app = Get-MgBetaDeviceAppManagementMobileApp -All |
Where-Object { $_.DisplayName -like "$APP_DISPLAY_NAME*" } |
Select-Object -First 1
if (-not $app) { throw "App '$APP_DISPLAY_NAME' not found." }

$body = @{
  "@odata.type" = "#microsoft.graph.mobileAppAssignment"
  intent = "required"
  target = @{
    "@odata.type" = "#microsoft.graph.exclusionGroupAssignmentTarget"
    groupId = $ring.Id
  }
  settings = @{
    "@odata.type" = "#microsoft.graph.win32LobAppAssignmentSettings"
    notifications = "showAll"
    restartSettings = $null
    installTimeSettings = $null
  }
}

New-MgBetaDeviceAppManagementMobileAppAssignment -MobileAppId $app.Id -BodyParameter $body

Get-MgBetaDeviceAppManagementMobileAppAssignment -MobileAppId $app.Id |
Select-Object Id,Intent,@{N="TargetType";E={$_.Target.OdataType}},@{N="GroupId";E={$_.Target.AdditionalProperties.groupId}}
```

