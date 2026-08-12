# Autopilot Enrolment Failure – Root Cause and Resolution

Date: 2026-08-11  
Status: Finalized

## Incident summary
Autopilot enrolment failed because the device already had an existing legacy MDM enrolment record from **2023-11-04**.  
Confirmed failure context:
- EnrollmentState: Failed
- ErrorCode: 0x80180014
- ErrorDescription: Device already enrolled in MDM
- MDMEnrolled: Yes (legacy manual enrolment)
- AzureADJoined: Yes
- Licenses: Present (Intune P1, Autopilot)
- Network: Healthy

## Confirmed root cause
A stale/conflicting legacy manual MDM enrolment blocked new Autopilot MDM enrolment.

---

## 1) Exact remediation steps

### A. Admin center actions (no device access needed) [ADMIN CENTER ONLY]
1. Go to **Intune admin center > Devices > All devices**.
2. Locate the affected device by serial/device name.
3. Open the stale managed device record and **Retire** it.
4. After retire completes, **Delete** the stale record (per org process).
5. Go to **Entra admin center > Identity > Devices > All devices**.
6. Remove duplicate/stale Entra device object(s) for the same hardware (keep the active/correct object).
7. Go to **Intune admin center > Devices > Windows > Windows enrollment > Devices (Windows Autopilot)**.
8. Confirm Autopilot hardware hash exists and correct deployment profile is assigned.

### B. Device-side actions (physical or remote session required) [DEVICE ACCESS REQUIRED]
1. On device: **Settings > Accounts > Access work or school**.
2. Select legacy work/school connection and click **Disconnect**.
3. Reboot device.
4. If disconnect is blocked/fails: perform **Wipe/Reset** to return device to OOBE.
5. Re-run Autopilot setup from OOBE with target user sign-in.

---

## 2) Correct order of operations
1. **[ADMIN CENTER ONLY]** Retire/delete stale Intune device record(s).  
2. **[ADMIN CENTER ONLY]** Remove stale/duplicate Entra device object(s).  
3. **[ADMIN CENTER ONLY]** Validate Autopilot hash + profile assignment.  
4. **[DEVICE ACCESS REQUIRED]** Disconnect legacy enrolment on device.  
5. **[DEVICE ACCESS REQUIRED]** Reboot or reset to OOBE.  
6. **[DEVICE ACCESS REQUIRED]** Start Autopilot again.  
7. **[ADMIN CENTER ONLY]** Validate successful new enrolment and policy application.

---

## 3) Verification checks (success criteria)
- Intune shows a **single current managed device record** (no stale duplicates).
- New enrolment timestamp reflects post-remediation attempt.
- Autopilot deployment completes without 0x80180014 recurrence.
- Compliance/policy application progresses (not 0 of 4).
- Device shows expected current work/school connection only.

---

## 4) Preventive action for other legacy devices
Implement a **pre-Autopilot hygiene gate**:
1. Before assigning Autopilot profile, check for:
   - Existing Intune managed record
   - Duplicate Entra device object
   - Prior manual/legacy MDM enrolment
2. If found, force cleanup (retire/delete stale records) before provisioning.
3. Add this check as a mandatory step in deployment runbook/CAB.
4. Run scheduled reporting to flag legacy-enrolled devices before they enter Autopilot waves.

---

## Final resolution statement
Root cause is confirmed: **conflicting legacy MDM enrolment state**.  
Cleaning stale management state (admin center + device), then re-running Autopilot from clean OOBE resolves the failure.
