# DWP Step-by-Step Guide: Add a Windows App to Intune Catalog (Pre-Phased Rollout)

## Purpose
This guide explains how to add a Windows application to the Intune app catalog before any phased rollout begins. It is written for engineers with no prior Intune app deployment experience.

Worked example used throughout:
- Application: **FinBridge Connect v3.1**
- Package type: **Windows LOB app packaged as `.intunewin`**
- Install command: `FinBridgeConnect_Setup.exe /silent`
- Uninstall command: `FinBridgeConnect_Setup.exe /uninstall /silent`
- Detection method: Registry key/value
- Detection path/value: `HKLM\SOFTWARE\FinBridge\Connect\Version = 3.1`

## Important UI Label Warning
Intune UI labels and menu placement can vary by tenant version, licensing, and portal updates.
- At every navigation step below, verify labels in your live tenant.
- If labels differ, follow the closest equivalent path and confirm with portal help text.

## 1. Add the App in Intune

1. Sign in to Microsoft Intune admin center.
2. Go to the app management area.
   - Typical path: **Apps > All apps > Add**.
   - UI label warning: This path may appear as **Apps > Windows** or **Apps > Add app** in some tenants. Verify in your own tenant.
3. In **Select app type**, choose the app type matching your package source:
   - For FinBridge Connect `.intunewin`: choose **Windows app (Win32)** (this is the Intune option used for `.intunewin` packages).
   - For Microsoft Store packaged apps: choose **Microsoft Store app (new)**.
   - For URL shortcuts/portals: choose **Web link**.
4. Select **Create** to start the app wizard.

## 2. Complete Required Fields for a Windows LOB/Win32 App

1. Upload package.
   - In the app package step, upload the `.intunewin` package file for FinBridge Connect.
   - UI label warning: The step may be named **App package file**, **Package file**, or similar.

2. Enter app information.
   - Name: `FinBridge Connect v3.1`
   - Description: Example: `FinBridge secure connectivity client for managed Windows endpoints.`
   - Publisher: `FinBridge`
   - Version: `3.1`
   - Why this matters: These fields are shown in Company Portal and reports, and are used by engineers for support tracking.

3. Configure program settings.
   - Install command: `FinBridgeConnect_Setup.exe /silent`
   - Uninstall command: `FinBridgeConnect_Setup.exe /uninstall /silent`
   - Install behavior/context:
     - Choose **System** when the app must install for all users on the device or requires elevated machine-level changes.
     - Choose **User** only when the app should install in user context and does not require machine-wide admin context.
   - Recommended for this example: **System**.
   - UI label warning: The field may be shown as **Install behavior**, **Device context**, or **User context** options.

4. Configure requirements.
   - OS architecture: select what the app supports (for most modern estates, `64-bit`; include `32-bit` only if validated).
   - Minimum OS version: set the lowest supported version (for example, Windows 10 22H2 or Windows 11 baseline per DWP policy).
   - Why this matters: Incorrect requirements cause **Not applicable** results and prevent intended installs.

5. Configure detection rules (how Intune confirms install success).
   - Select detection type: **Registry**.
   - Set:
     - Key path: `HKLM\SOFTWARE\FinBridge\Connect`
     - Value name: `Version`
     - Detection method/operator: equals
     - Expected value: `3.1`
   - Alternative detection options you may use for other apps:
     - MSI product code
     - File path/file version
   - UI label warning: Detection editor wording can vary between **Rules format**, **Manually configure detection rules**, or equivalent.

6. Configure return codes.
   - Ensure success and failure exit codes are correctly mapped.
   - Typical defaults:
     - `0` = Success
     - `3010` = Soft reboot required (often treated as success with restart required)
     - `1641` = Hard reboot initiated
     - Other unknown non-zero codes = Failure unless explicitly mapped
   - Why this matters: Wrong return code mapping causes false failure or false success reporting.

7. Review and create.
   - Check summary values carefully, then select **Create**.
   - UI label warning: Button may appear as **Create**, **Add**, or **Save** depending on experience/version.

## 3. Assignment Basics (Pilot First)

1. Open the app you created and go to assignments.
   - Typical path: **Apps > All apps > FinBridge Connect v3.1 > Assignments**.
   - UI label warning: Assignment section could appear as a tab or side panel item.

2. Understand assignment types.
   - **Required**: App installs automatically on targeted devices/users.
   - **Available for enrolled devices**: App is optional; user installs from Company Portal.
   - **Uninstall**: App is removed from targeted devices/users.

3. Assign to a small pilot group first.
   - Create/use a controlled pilot Azure AD group (for example 20-50 devices/users representing key hardware and user profiles).
   - Do **not** target the full 10,000-device fleet initially.
   - Why pilot-first is mandatory:
     - Validates detection logic, command lines, and return code handling.
     - Identifies performance or compatibility issues before broad impact.
     - Reduces blast radius and rollback complexity.

4. Save assignment changes and confirm targeted group membership.

## 4. Verification Steps

1. Confirm the app appears correctly in Intune catalog.
   - Go to **Apps > All apps** and verify:
     - App name displays as `FinBridge Connect v3.1`
     - Publisher and version are correct
     - Platform/type matches Win32 package

2. Confirm assignment is active for pilot group.
   - In app **Assignments**, verify group is present under intended type (Required/Available/Uninstall).
   - Validate no accidental broad assignment (for example All devices) unless explicitly approved.

3. Check install status from Intune.
   - Go to app monitoring view.
   - Typical path: **Apps > All apps > FinBridge Connect v3.1 > Monitor > Device install status**.
   - UI label warning: This may appear as **Device status**, **Installation status**, or similar.

4. Validate on a pilot test device.
   - Sync the device with Intune (Company Portal sync or Windows Settings work/school sync).
   - For **Required** assignment, verify app installs automatically.
   - For **Available** assignment, verify app appears in Company Portal and installs when selected.

5. Interpret key statuses.
   - **Installed**: Intune detection rule succeeded; app is considered successfully installed.
   - **Failed**: Install command ran but returned/mapped to failure, or detection rule did not validate expected installed state.
   - **Not applicable**: Device does not meet requirements (OS/version/architecture) or assignment/filter excludes it.

6. Troubleshoot quickly if status is not Installed.
   - Failed:
     - Re-check install/uninstall command syntax.
     - Re-check return code mapping.
     - Review endpoint logs and Intune management extension logs.
   - Not applicable:
     - Re-check requirement rules (architecture/min OS).
     - Confirm the test device is actually in the assigned group and not excluded.

## 5. Pre-Rollout Gate Checklist (Before Any Phased Rollout)

1. App metadata is accurate and user-friendly.
2. Install/uninstall commands are validated on pilot devices.
3. Detection rule confirms the real installed state (`HKLM\SOFTWARE\FinBridge\Connect\Version = 3.1`).
4. Return code behavior is confirmed (including reboot-related codes).
5. Pilot assignment completed with expected install outcomes.
6. No unexplained Failed or Not applicable states remain for in-scope pilot devices.
7. Evidence captured in change record (screenshots/status export/test notes).

When all checklist items pass, proceed to phased rollout waves rather than immediate full-fleet targeting.
