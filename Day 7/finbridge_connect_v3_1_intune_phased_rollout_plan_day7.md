# FinBridge Connect v3.1 Intune Phased Rollout Plan (10,000 Win11 Endpoints)

## 1. RING STRUCTURE

### Ring 1 (Pilot)
- Size: 500 devices/users total.
- Duration: 3 calendar days minimum active deployment + 2 days monitoring (5 days total).
- Who to include:
  - 200 IT and digital workplace engineering users (high feedback quality).
  - 150 cross-business non-Finance users across typical device models.
  - 100 Finance users (priority path).
  - 50 known at-risk older hardware devices (4GB RAM) explicitly tagged.
- Purpose:
  - Validate install, detection, uninstall, and baseline app stability in production-like conditions.
  - Validate behavior on at-risk 4GB RAM endpoints before larger exposure.
  - Build a known-issues list and support runbook before scale-out.
- Intune assignment group type:
  - Use **Required** assignment to Azure AD group `APP_FINBRIDGE_V31_RING1_REQUIRED`.
  - Create a separate dynamic/static subgroup `APP_FINBRIDGE_V31_RING1_4GB_REQUIRED` for focused hardware reporting.

### Ring 2 (Early)
- Size: 2,500 devices/users total (cumulative 3,000 including Ring 1).
- Duration: 4 calendar days deployment + 2 days monitoring (6 days total).
- Who to include:
  - Remaining Finance users not in Ring 1 (target total Finance completion by end of week 1).
  - Operationally critical teams with normal hardware profile.
  - A controlled sample of each major device model and site.
- Purpose:
  - Confirm deployment reliability at larger scale.
  - Validate support load and performance impact under higher concurrency.
  - Confirm no hidden issues from scale, networking, or policy timing.
- Intune assignment group type:
  - Use **Required** assignment to `APP_FINBRIDGE_V31_RING2_REQUIRED`.
  - Keep 4GB devices excluded unless they met Ring 1 hardware criteria.

### Ring 3 (Broad)
- Size: Remaining 7,000 devices/users (cumulative 10,000).
- Duration: 8 calendar days deployment + 2 days final monitoring (10 days total).
- Who to include:
  - All remaining eligible Win11 endpoints.
  - Include previously deferred cohorts once criteria are met.
- Purpose:
  - Complete fleet-wide deployment within 3-week deadline.
  - Maintain service continuity with staged monitoring checkpoints.
- Intune assignment group type:
  - Use **Required** assignment to `APP_FINBRIDGE_V31_RING3_REQUIRED`.
  - Maintain explicit exclusion group `APP_FINBRIDGE_V31_EXCLUSION_HIGH_RISK` for temporarily isolated devices.

## 2. ADVANCE CRITERIA

### Ring 1 to Ring 2 (must meet all)
- Install success rate:
  - Minimum **97.0% Installed** among in-scope Ring 1 targets.
  - Measured from Intune **Device install status** for FinBridge v3.1.
- Error rate threshold:
  - Maximum **2.0% Failed** in Ring 1 during monitoring window.
- User-reported issues threshold:
  - Maximum **1.5 tickets per 100 deployed users per 24 hours** for app-related incidents (service desk category tagged `FINBRIDGE_V31`).
- Monitoring period:
  - Minimum **48 hours** after last Ring 1 assignment sync before go/no-go review.

### Ring 2 to Ring 3 (must meet all)
- Install success rate:
  - Minimum **98.0% Installed** among cumulative Ring 1+2 targets.
- Error rate threshold:
  - Maximum **1.5% Failed** in cumulative Ring 1+2 window.
- User-reported issues threshold:
  - Maximum **1.0 ticket per 100 deployed users per 24 hours** for app-related incidents over 2 consecutive days.
- Monitoring period:
  - Minimum **72 hours** after last Ring 2 assignment sync before go/no-go review.

### Hold Condition (pause without full rollback)
- Trigger:
  - If **Failed status is between 2.1% and 4.9%** in the active ring for more than **12 continuous hours**, pause advancement.
- Action on hold:
  - Stop adding new devices to next ring.
  - Keep current ring active while engineering triages root cause.
- Specific example:
  - Ring 2 reaches 3.2% failures due to detection mismatch on one hardware model; rollout is paused, detection rule corrected, impacted subgroup retried, then metrics re-evaluated.

## 3. ROLLBACK TRIGGERS

### Trigger A: Install failure rate automatic halt
- Condition:
  - **>=5.0% Failed** in any active ring within a rolling **6-hour** window.
- Effect:
  - Automatic rollout halt and rollback decision meeting.
- Decision owner:
  - Change Manager (chair) + DWP Endpoint Lead (technical owner) + Service Owner approval.
- Decision window:
  - **Within 60 minutes** of threshold breach alert.
- Exact Intune rollback action:
  - Remove/disable **Required** assignment for v3.1 ring group(s) currently in flight.
  - Add same devices/users to `APP_FINBRIDGE_V30_REQUIRED` (v3.0 app Required assignment).
  - Add v3.1 **Uninstall** assignment to affected ring group only if uninstall path validated and approved.

### Trigger B: Application crash rate rollback consideration
- Condition:
  - App crash telemetry (Endpoint Analytics/App reliability or SIEM feed) shows **>=3 crashes per 100 active app devices per 24 hours** for **2 consecutive 24-hour periods**.
- Effect:
  - Mandatory rollback assessment.
- Decision owner:
  - DWP Endpoint Lead + Problem Manager; Service Owner final decision.
- Decision window:
  - **Within 4 hours** after second breach window closes.
- Exact Intune action if rollback approved:
  - Freeze all v3.1 new assignments.
  - Reassign affected groups to `APP_FINBRIDGE_V30_REQUIRED`.
  - Keep v3.1 only on unaffected pilot subgroup if explicitly approved for hotfix validation.

### Trigger C: Business-critical failure immediate rollback
- Condition (immediate):
  - Finance users cannot complete payment/batch-critical workflow because FinBridge v3.1 authentication/session function fails in production.
- Effect:
  - Immediate rollback regardless of percentage affected.
- Decision owner:
  - Incident Manager (Major Incident) with Finance service owner confirmation.
- Decision window:
  - **Immediate**, target action start within **30 minutes** of confirmation.
- Exact Intune action:
  - Remove v3.1 Required assignments from Finance-targeted groups.
  - Assign Finance groups to `APP_FINBRIDGE_V30_REQUIRED`.
  - If necessary, assign v3.1 **Uninstall** to Finance group once rollback comms approved.

### Trigger D: 4GB RAM at-risk cohort ring isolation
- Condition:
  - In devices tagged 4GB RAM, **>=8.0% Failed** or **>=10.0% severe performance tickets** within **24 hours** of assignment.
- Effect:
  - Isolate hardware cohort; continue broader rollout only for non-impacted cohorts if safe.
- Decision owner:
  - DWP Endpoint Engineering Lead.
- Decision window:
  - **Within 2 hours** of threshold breach.
- Exact Intune action:
  - Move 4GB devices into `APP_FINBRIDGE_V31_EXCLUSION_HIGH_RISK`.
  - Remove their v3.1 Required assignment.
  - Assign isolated cohort to `APP_FINBRIDGE_V30_REQUIRED`.
  - Continue rings for standard hardware only after CAB notification.

## 4. FINANCE DEADLINE RESOLUTION

### Option A: Compress pilot so Finance enters Ring 2 by end of week 1
- Minimum safe pilot duration:
  - **72 hours total** (48 hours active + 24 hours observation) is the shortest acceptable window.
- Risk introduced:
  - Reduced time to detect low-frequency defects (for example overnight token/session renewals or day-2 startup behavior).
- Compensating control:
  - Increase pilot telemetry checks to every 4 hours, and require explicit Finance workflow test sign-off before advancing.

### Option B: Create Finance priority Ring 0 before main pilot
- Ring 0 structure:
  - Size: 150 Finance users (30% of Finance population), mixed offices and device models, include at least 20 known 4GB devices if present in Finance.
  - Duration: 3 days total (2 deployment + 1 monitoring).
  - Assignment: **Required** via `APP_FINBRIDGE_V31_RING0_FINANCE_REQUIRED`.
- Ring 0 advance conditions:
  - >=97.5% Installed, <=1.5% Failed, <=1 ticket per 100 users per 24 hours, minimum 24h monitoring after last sync.
- Ring 0 rollback plan:
  - If >=4% failures in 6 hours or any payment-critical outage, remove Ring 0 v3.1 Required assignment and immediately assign `APP_FINBRIDGE_V30_REQUIRED` to Ring 0.

### Recommendation (single clear choice)
- **Recommend Option B (Finance Ring 0) as the safer and more controllable approach.**
- Justification:
  - Meets Finance deadline by prioritizing their deployment path without weakening quality gates for the full fleet.
  - Preserves a standard Ring 1 pilot for non-Finance patterns, avoiding schedule pressure that can hide defects.
  - Provides clearer blast-radius control and cleaner rollback boundaries for the highest-priority business unit.
  - Better aligns with the known 4GB RAM risk by allowing early targeted observation inside Finance before broad rollout.
