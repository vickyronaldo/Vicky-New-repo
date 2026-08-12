# Detailed Root Cause Analysis (RCA)
## Autopilot Enrolment Failure – Legacy MDM Conflict

**Date:** 2026-08-11  
**Prepared by:** DWP Analyst  
**Document type:** Detailed RCA (separate Day 6 record)  
**Status:** Final

---

## 1) Executive summary
Autopilot enrolment failed because the device already had an existing legacy manual MDM enrolment record from **2023-11-04**. This stale/conflicting enrolment state blocked new Autopilot-driven MDM enrolment.

**Primary error observed:** `0x80180014` with description: *The device is already enrolled in MDM.*

---

## 2) Incident scope and impact
- **Scope:** Single affected Windows device in this case record.
- **Impact:** Device could not complete Autopilot provisioning and did not receive expected policy payload.
- **User/business effect:** Delayed device readiness and compliance posture establishment.

---

## 3) Supporting evidence (verbatim diagnostic facts)
From MDM diagnostic export:

- `EnrollmentState : Failed`
- `ErrorCode       : 0x80180014`
- `ErrorDescription: The device is already enrolled in MDM.`
- `MDMEnrolled     : Yes (previous enrolment from 2023-11-04)`
- `EnrolmentSource : Legacy manual MDM enrolment`
- `ProfilesApplied : 0 of 4`
- `LastError       : 0x80070005 (Access denied)`
- `AzureADJoined   : Yes`
- `IntuneP1License : Yes`
- `AutopilotLicense: Yes`
- `Network         : All endpoints reachable, no proxy`

### Evidence interpretation matrix
| Evidence | What it proves | Relevance to RCA |
|---|---|---|
| EnrollmentState = Failed | Enrolment did not complete | Confirms incident outcome |
| ErrorCode 0x80180014 + description “already enrolled in MDM” | Existing MDM state conflicts with new enrolment | Direct root-cause indicator |
| MDMEnrolled = Yes (2023-11-04) | Prior enrolment exists | Confirms stale/legacy state |
| EnrolmentSource = Legacy manual MDM enrolment | Enrolment originated outside current Autopilot flow | Explains conflict path |
| ProfilesApplied = 0 of 4 | Policy stage did not progress | Downstream symptom of failed enrolment |
| LastError 0x80070005 (Access denied) | Access failure during processing | Secondary symptom, not primary blocker |
| AzureADJoined = Yes | Join state is present | Rules out missing AAD join as primary cause |
| IntuneP1License = Yes; AutopilotLicense = Yes | Licensing assigned | Rules out licensing gap |
| Network endpoints reachable, no proxy | Network healthy | Rules out connectivity/proxy as primary cause |

---

## 4) Timeline of events
> Note: Exact clock timestamps were not included in the provided export. Timeline below combines known dated evidence with analysis checkpoints.

| Time reference | Event | Evidence source |
|---|---|---|
| 2023-11-04 | Device enrolled through legacy manual MDM process | `MDMEnrolled: Yes (previous enrolment from 2023-11-04)`, `EnrolmentSource` |
| T0 (Autopilot attempt) | Autopilot enrolment initiated | Incident context |
| T0 + short interval | Enrolment failed with existing enrolment conflict | `EnrollmentState: Failed`, `ErrorCode: 0x80180014`, description |
| T0 + short interval | Policy not applied | `ProfilesApplied: 0 of 4` |
| T0 + short interval | Access denied recorded as last error | `LastError: 0x80070005` |
| T0 + analysis | Licensing and network validated healthy | `IntuneP1License/AutopilotLicense: Yes`, `Network: reachable` |
| T0 + conclusion | Root cause confirmed as legacy MDM conflict | Combined evidence analysis |

---

## 5) 5 Whys analysis
### Problem statement
Autopilot enrolment failed for the device.

1. **Why did Autopilot enrolment fail?**  
   Because the process encountered an MDM enrolment conflict (`0x80180014`: device already enrolled in MDM).

2. **Why was there an enrolment conflict?**  
   Because the device already had an active/recorded legacy manual MDM enrolment.

3. **Why was the legacy manual enrolment still present?**  
   Because stale historical enrolment state/records were not removed before re-provisioning with Autopilot.

4. **Why were stale records not removed before Autopilot?**  
   Because the provisioning workflow lacked a mandatory pre-check gate for prior MDM enrolment and duplicate management objects.

5. **Why did the workflow lack that gate?**  
   Because legacy-to-Autopilot migration controls were not fully standardized/enforced in the operational runbook.

### 5-Whys conclusion
The technical trigger was a pre-existing legacy MDM enrolment; the process root cause was missing pre-Autopilot hygiene governance (record cleanup and validation gate).

---

## 6) Confirmed root cause
**Confirmed root cause:** Conflicting stale legacy manual MDM enrolment state (device and/or management records) prevented Autopilot enrolment completion.

---

## 7) Corrective actions taken / required
## A) Admin center remediation (control-plane cleanup)
1. In Intune admin center, locate affected device under **Devices > All devices**.
2. Retire and remove stale managed device record(s) tied to old enrolment.
3. In Entra admin center, remove stale/duplicate device object(s) for same hardware identity.
4. In Intune Autopilot devices list, confirm hardware hash and deployment profile assignment remain correct.

## B) Device-side remediation (endpoint cleanup)
1. On device, disconnect legacy work/school MDM connection if present.
2. Reboot device.
3. If required, reset/wipe to return device to clean OOBE state.
4. Re-run Autopilot provisioning.

---

## 8) Verification criteria (post-remediation)
Success is confirmed when all conditions are true:
- Autopilot enrolment completes without recurrence of `0x80180014`.
- Device appears as a single current Intune managed record (no stale duplicate conflict).
- Policy application progresses beyond `0 of 4` and reaches expected applied state.
- Device retains expected Azure AD join and active Intune management state.

---

## 9) Preventive actions (recurrence prevention)
1. **Pre-Autopilot hygiene gate (mandatory):**
   - Check for existing Intune managed records.
   - Check for duplicate/stale Entra device objects.
   - Check for prior manual/legacy MDM enrolment markers.
   - Block Autopilot assignment until cleanup is complete.

2. **Runbook standardization:**
   - Update provisioning SOP/CAB checklist to include explicit legacy-enrolment cleanup step.
   - Require sign-off before device enters provisioning ring.

3. **Automated detection/reporting:**
   - Schedule periodic reporting for duplicate device identities and devices with historical legacy enrolment.
   - Route flagged devices to pre-remediation queue.

4. **Migration policy control:**
   - Disallow ad-hoc manual legacy MDM onboarding for devices intended for Autopilot lifecycle.

---

## 10) Ownership and tracking
| Action | Owner | Target completion | Status |
|---|---|---|---|
| Cleanup stale records for incident device | Endpoint Admin | Immediate | In progress/Complete per operations |
| Update Autopilot pre-check runbook | Endpoint Engineering | Next CAB cycle | Planned |
| Implement recurring stale-enrolment report | Intune Operations | Next sprint | Planned |
| Enforce provisioning gate in rollout workflow | Service Delivery Lead | Next rollout wave | Planned |

---

## 11) Final statement
This incident was caused by a known conflicting legacy MDM enrolment condition, not by licensing, Azure AD join, or network connectivity. The defined remediation and preventive controls address both the immediate device failure and the underlying process gap.
