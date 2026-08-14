# L2 Technical Knowledge Article: Floor 6 Deployment Ring Rollback

## Purpose
Provide a repeatable engineering procedure for incidents where `DMS-Client` deployment to the Capstone Floor 6 ring correlates with login failure/slowness.

## Trigger Conditions
- Floor 6 users report login failures or severe login delay.
- Incident timing aligns with recent app assignment changes.
- Comparable non-impacted ring appears unaffected (to confirm).

## Required Inputs
- App display name prefix: `DMS-Client`
- Affected ring display name: `CAPSTONE-FLOOR6`
- Graph scopes: `DeviceManagementApps.ReadWrite.All`, `Group.Read.All`, `Device.Read.All`, `User.Read.All`

## Evidence-First Workflow
1. Execute hand-corrected evidence collector dry run.
```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\labuser\Documents\Training\Vicky Project\Powershell script\Floor6_Evidence_Collector_Hand_Corrected.ps1" -DryRun -AppName "DMS-Client" -LookbackDays 7
```
Expected result: No artifacts written; planned actions confirmed.

2. Execute hand-corrected evidence collector actual.
```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\labuser\Documents\Training\Vicky Project\Powershell script\Floor6_Evidence_Collector_Hand_Corrected.ps1" -AppName "DMS-Client" -LookbackDays 7 -OutputRoot "C:\Temp\DWP_Floor6_Evidence"
```
Expected result: Evidence package created with summary and logs.

## Ring Scope Export
```powershell
Install-Module Microsoft.Graph -Scope CurrentUser -Force
Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All,Group.Read.All,Device.Read.All,User.Read.All"
Select-MgProfile -Name "beta"

$AFFECTED_RING_NAME = "CAPSTONE-FLOOR6"
$ring = Get-MgGroup -Filter "displayName eq '$AFFECTED_RING_NAME'"
if (-not $ring) { throw "Group '$AFFECTED_RING_NAME' not found." }

Get-MgGroupMember -GroupId $ring.Id -All |
Select-Object Id,DisplayName,@{N="Type";E={$_.AdditionalProperties.'@odata.type'}},UserPrincipalName,DeviceId |
Export-Csv "C:\Temp\CAPSTONE-FLOOR6_AffectedMembers.csv" -NoTypeInformation
```
Expected result: Affected ring member export is available for impact tracking.

## Primary Fix: Remove Required Assignment
```powershell
$APP_DISPLAY_NAME = "DMS-Client"
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
if (-not $assignment) { throw "Required assignment not found for CAPSTONE-FLOOR6." }


Remove-MgBetaDeviceAppManagementMobileAppAssignment -MobileAppId $app.Id -MobileAppAssignmentId $assignment.Id
```
Expected result: Assignment no longer targets CAPSTONE-FLOOR6 as required.

## Verification
```powershell
Get-MgBetaDeviceAppManagementMobileAppAssignment -MobileAppId $app.Id |
Select-Object Id,Intent,@{N="GroupId";E={$_.Target.AdditionalProperties.groupId}},@{N="GroupName";E={(Get-MgGroup -GroupId $_.Target.AdditionalProperties.groupId).DisplayName}}
```
Expected result: No required assignment remains for CAPSTONE-FLOOR6.

## Alternate Mitigation
If direct removal is blocked by policy, add exclusion assignment for CAPSTONE-FLOOR6 (to confirm governance acceptance).

## Rollback of Fix
Recreate required assignment for CAPSTONE-FLOOR6 if scope was removed in error.
```powershell
$body = @{
  "@odata.type" = "#microsoft.graph.mobileAppAssignment"
  intent = "required"
  target = @{
    "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
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
```
Expected result: Required targeting to CAPSTONE-FLOOR6 is restored.

## Handoff Checklist
1. Attach evidence ZIP path from collector output.
2. Attach ring member CSV exports.
3. Attach pre/post assignment verification output.
4. Document user impact trend after change window.
5. Mark unresolved points as to confirm.
