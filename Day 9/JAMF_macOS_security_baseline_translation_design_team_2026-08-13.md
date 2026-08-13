# JAMF Translation of macOS Security Baseline (DWP)

Date: 2026-08-13  
Platform: macOS (Design team fleet, 25 devices)

## Scope and intent
This document translates the requested macOS security baseline into JAMF configuration profile settings for controlled implementation.

- Fleet size target: 25 Design team devices
- Deployment model: pilot first, then staged ring rollout
- Reporting objective: reduce false positives while preserving strict baseline posture
- Where JAMF control names can vary by version or workflow, naming drift is explicitly flagged.

## Verification discipline note (same approach as Day 6 Intune labs)
JAMF Pro UI labels, payload names, and control locations can change between versions, tenant feature flags, and legacy vs modern profile workflows.

- Do not trust an exact label from this document without confirming it in your own JAMF instance.
- Validate payload names during implementation and record screenshots in CAB/change evidence.
- Re-check labels after JAMF upgrades.

## Recommended UI path (latest known)
Use one of the following paths, depending on tenant experience and JAMF version:

1. Computers
2. Configuration Profiles
3. New
4. Select platform and payload set
5. Configure baseline controls
6. Scope to pilot smart/static group

Alternative path in some interfaces:

1. Devices
2. Configuration Profiles
3. Create profile
4. Add payloads (Security & Privacy, Restrictions, Login Window, Software Updates)

Flag: exact menu labels and payload names can vary; verify in your tenant.

## Baseline-to-Profile mapping

### Prerequisite navigation (use once)

1. Open JAMF Pro.
2. Navigate to configuration profiles for macOS devices.
3. Create a new profile for the Design fleet baseline.
4. Set distribution method and target scope (pilot group first).
5. Continue to payload configuration.

### Requirement 1: FileVault disk encryption must be enabled

- Payload type: Security & Privacy (FileVault section), or dedicated FileVault control area in newer UI.
- Value: Enable FileVault and escrow recovery key to JAMF (institutional and/or personal recovery key per policy).
- Effect: Encrypts data at rest so local storage is unreadable without authorized unlock.
- False-positive risk: Device reports noncompliant while encryption is still in progress; escrow status delayed until next inventory/check-in; user has not completed required logout/restart.
- Verify label warning: FileVault control placement varies notably across JAMF versions; verify exact payload location before rollout.
- Recommendation: Enforce escrow and add help text for user reboot/logout timing to reduce unnecessary incident tickets.

Steps:

1. Add the payload that manages FileVault settings.
2. Enable FileVault for targeted users/devices.
3. Configure recovery key escrow to JAMF.
4. Save and scope to pilot devices.

### Requirement 2: Gatekeeper must be enabled (identified developers only)

- Payload type: Restrictions (or Security controls subsection where Gatekeeper policy is exposed).
- Value: Allow apps from App Store and identified developers only.
- Effect: Prevents untrusted or unsigned applications from launching by default.
- False-positive risk: Internal signed apps lacking notarization can appear blocked; temporary local override actions can create reporting mismatch; inventory lag can show stale compliance.
- Verify label warning: Gatekeeper controls can appear under different payload names and sometimes depend on macOS generation; verify actual control text in tenant.
- Recommendation: Maintain exception workflow with expiry for business-critical internal tools pending notarization.

Steps:

1. Add the Restrictions payload.
2. Locate the app execution/Gatekeeper control.
3. Set policy to identified developers only.
4. Save and validate with a known unsigned test app.

### Requirement 3: Minimum macOS version must be current stable minus one point release

- Payload type: Managed Software Updates or Restrictions/software compliance controls, depending on JAMF workflow.
- Value: Set minimum accepted macOS version to N-1 point release from current stable.
- Effect: Keeps devices in a supported patch window while allowing controlled operational lag.
- False-positive risk: Stale inventory data, delayed check-ins, update deferral windows, or staged Apple rollout visibility can show healthy devices as outdated.
- Verify label warning: This is one of the most version-sensitive areas in JAMF; verify exact payload and DDM workflow labels in your instance.
- Recommendation: Record the chosen minimum version in change record and add monthly review to advance N-1 target.

Steps:

1. Determine current stable macOS point release.
2. Calculate N-1 and document the exact version string.
3. Configure minimum version requirement in update/compliance controls.
4. Apply an enforcement deadline aligned to support windows.

### Requirement 4: Firewall must be enabled

- Payload type: Security & Privacy (Firewall section).
- Value: Enable macOS Application Firewall (and stealth mode if required by policy).
- Effect: Reduces unsolicited inbound connections and network exposure.
- False-positive risk: Third-party endpoint/network agents can cause state mismatch vs local UI; brief out-of-sync periods appear after profile changes or reboot.
- Verify label warning: Firewall setting names are usually stable, but location can shift between legacy/new profile editors.
- Recommendation: Standardize endpoint security stack ownership to avoid conflicting controls.

Steps:

1. Add Security & Privacy payload.
2. Enable Firewall.
3. Configure optional hardening flags such as stealth mode.
4. Scope to pilot and verify profile applies successfully.

### Requirement 5: Login password required after sleep/screen saver

- Payload type: Security & Privacy and/or Login Window (depends on profile template and macOS version).
- Value: Require password immediately after sleep or screen saver starts.
- Effect: Prevents unauthorized access when a device is left unattended.
- False-positive risk: User session state and fast user switching can produce transient mismatches; script audits may query an outdated preference domain.
- Verify label warning: This control can move between payload areas and sometimes appears with different wording for screen lock timing.
- Recommendation: Use immediate lock where business allows; if a grace period is required, keep it minimal and documented.

Steps:

1. Add Security & Privacy and/or Login Window payload as applicable.
2. Locate sleep/screen saver password prompt setting.
3. Set prompt delay to immediate (or lowest approved value).
4. Validate by sleeping a pilot device and testing unlock behavior.

### Requirement 6: Automatic security updates must be enabled

- Payload type: Software Updates / Managed Software Updates payload (legacy and modern workflows differ).
- Value: Enable automatic security updates and Rapid Security Responses where supported.
- Effect: Applies security patches with minimal user intervention and lower exposure windows.
- False-positive risk: Device offline during maintenance window, insufficient free disk, deferred restarts, or update telemetry lag can report temporary noncompliance.
- Verify label warning: Software update payload naming and options frequently change; verify exact wording in your tenant before implementation.
- Recommendation: Pair automatic security updates with reboot communication windows to avoid prolonged pending-install states.

Steps:

1. Add Software Update or Managed Software Updates payload.
2. Enable automatic security update installation.
3. Enable Rapid Security Responses where available.
4. Define enforcement/deadline behavior for pilot scope.

## Compliance signal and false-positive handling guidance

- Use smart groups that include last check-in age to avoid stale-state noise.
- Separate policy violation from remediation timing (for example, FileVault encrypting vs encryption failed).
- Set clear triage criteria for transient states: pending reboot, pending inventory, and pending escrow.
- Require second-check validation before incident escalation on single-point telemetry failures.

## UI-path and label change watchlist
The following controls are the most likely to appear with different names/locations across JAMF versions:

- FileVault control location (Security & Privacy vs dedicated FileVault workflow)
- Gatekeeper control wording under Restrictions/security payloads
- Minimum macOS version controls under Managed Software Updates/DDM paths
- Sleep/screen saver password enforcement location (Security & Privacy vs Login Window)
- Automatic security updates and Rapid Security Response label variations

Recommendation: Confirm labels in tenant UI at implementation time and capture screenshots in CAB documentation.

## Implementation checklist

1. Create macOS baseline profile for Design fleet.
2. Configure all six requirements above.
3. Scope first to pilot group (3-5 devices).
4. Validate settings after reboot/logout cycle and inventory refresh.
5. Review false-positive patterns for one business week.
6. Roll out in rings (pilot, broad design, full design fleet).
7. Re-validate labels and payload paths after every JAMF upgrade.

## Suggested validation evidence (post-deployment)

1. FileVault status report and escrow confirmation per device.
2. Gatekeeper policy validation with signed and unsigned app launch test.
3. macOS version compliance export showing N-1 threshold.
4. Firewall enabled state report.
5. Screen lock/password-after-sleep behavior spot checks.
6. Software update status report including pending vs installed security updates.
