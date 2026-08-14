# Runbook: Floor 6 Login/Slowness Fix via Deployment Rollback (Capstone Floor 6 Ring)

Date: 2026-08-14
Incident pattern: Floor 6 login failures/slowness after DMS-Client deployment
Scope: Fix path for suspected deployment assignment/config conflict in the Capstone Floor 6 deployment ring

## 1. Prerequisites

1. Microsoft Graph PowerShell module installed.
Expected result: `Get-Command Connect-MgGraph` returns a command.

2. Engineer has permissions: `DeviceManagementApps.ReadWrite.All`, `Group.Read.All`, `Device.Read.All`, `User.Read.All`.
Expected result: Graph connection succeeds without consent/authorization error.

3. Affected ring display name confirmed as `CAPSTONE-FLOOR6`.
Expected result: Ring group resolves to a valid Group ID.

4. App display name confirmed as `DMS-Client` (or exact current prefix).
Expected result: App query returns one intended target app record.

5. Change approval/CAB notification completed (to confirm process requirement).
Expected result: Ticket/change record includes approval reference.

6. Evidence collector scripts available locally.
Expected result: Both scripts exist and can run in dry-run mode.

## 2. Procedure

1. Run evidence collection dry run on one affected endpoint.
Command:
```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\labuser\Documents\Training\Vicky Project\Powershell script\Floor6_Evidence_Collector_Hand_Corrected.ps1" -DryRun -AppName "DMS-Client" -LookbackDays 7
```
Expected result: Dry-run summary prints planned actions only; no output artifacts are written.

2. Run evidence collection actual on one affected endpoint.
Command:
```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\labuser\Documents\Training\Vicky Project\Powershell script\Floor6_Evidence_Collector_Hand_Corrected.ps1" -AppName "DMS-Client" -LookbackDays 7 -OutputRoot "C:\Temp\DWP_Floor6_Evidence"
```
Expected result: Evidence folder is created with logs, CSV/JSON summaries, and ZIP package.

3. Connect to Microsoft Graph for ring and app actions.
Command:
```powershell
Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All,Group.Read.All,Device.Read.All,User.Read.All"
Select-MgProfile -Name "beta"
```
Expected result: Connected context is established and profile is set to `beta`.

4. Resolve affected ring and export impacted members/devices.
Command:
```powershell
$AFFECTED_RING_NAME = "CAPSTONE-FLOOR6"
$ring = Get-MgGroup -Filter "displayName eq '$AFFECTED_RING_NAME'"
if (-not $ring) { throw "Group '$AFFECTED_RING_NAME' not found." }

Get-MgGroupMember -GroupId $ring.Id -All |
Select-Object Id,DisplayName,@{N="Type";E={$_.AdditionalProperties.'@odata.type'}},UserPrincipalName,DeviceId |
Export-Csv "C:\Temp\CAPSTONE-FLOOR6_AffectedMembers.csv" -NoTypeInformation

Get-MgGroupMember -GroupId $ring.Id -All |
Where-Object { $_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.device' } |
Select-Object Id,DisplayName,DeviceId |
Export-Csv "C:\Temp\CAPSTONE-FLOOR6_AffectedDevices.csv" -NoTypeInformation

```
Expected result: Member and device CSVs are created for the affected ring.

5. Resolve target app and locate required assignment for the affected ring.
Command:
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
if (-not $assignment) { throw "Required assignment for '$AFFECTED_RING_NAME' not found on app '$($app.DisplayName)'." }
```
Expected result: Valid app and assignment objects are identified.

6. Roll back by removing the required assignment from the Capstone Floor 6 ring.
Command:
```powershell
Remove-MgBetaDeviceAppManagementMobileAppAssignment -MobileAppId $app.Id -MobileAppAssignmentId $assignment.Id
```
Expected result: Assignment delete completes without error.

7. Verify assignment state after rollback.
Command:
```powershell
Get-MgBetaDeviceAppManagementMobileAppAssignment -MobileAppId $app.Id |
Select-Object Id,Intent,@{N="GroupId";E={$_.Target.AdditionalProperties.groupId}},@{N="GroupName";E={(Get-MgGroup -GroupId $_.Target.AdditionalProperties.groupId).DisplayName}}
```
Expected result: No `required` assignment remains for `CAPSTONE-FLOOR6`.

8. Trigger controlled user validation on 3 to 5 previously affected users (to confirm count).
Expected result: Login success and materially reduced login time are observed versus incident window.

9. Send Floor 6 communication update.
Expected result: Users receive reassurance and instructions without an unowned ETA.

## 3. Verification

1. Confirm rollback state in Intune/Graph.
Expected result: `CAPSTONE-FLOOR6` is no longer targeted as required for the rolled-back app.

2. Confirm endpoint symptom recovery in sample set.
Expected result: Users can sign in; severe slowness is not reproduced in validation cohort.

3. Confirm no new matching install failure pattern in fresh endpoint evidence (to confirm exact threshold).
Expected result: `InstallState Failed`/`NotDetected` correlation rate drops after rollback.

4. Confirm service desk queue trend improvement.
Expected result: New Floor 6 login/slowness tickets decline after rollback window.

5. Record closure evidence.
Expected result: Ticket includes command outputs, exported CSVs, and evidence package path.

## 4. Rollback (of this fix)

Use this only if removing assignment worsens service or was applied to wrong scope.

1. Recreate the required assignment for the original ring scope (CAPSTONE-FLOOR6).
Command:
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
Expected result: Required assignment is restored for `CAPSTONE-FLOOR6`.

2. Verify restored assignment.
Expected result: Graph assignment list shows required target returned to CAPSTONE-FLOOR6.

3. Re-run evidence collection on one affected endpoint.
Expected result: Fresh package exists for post-rollback comparison.

4. Escalate to endpoint/app engineering with both evidence sets if incident persists.
Expected result: Handoff includes pre-fix and post-fix artifacts for deeper root-cause analysis.
