# Windows 11 Intune Compliance Policy Translation (DWP)

Date: 2026-08-10  
Platform: Windows 10 and later (applies to Windows 11)

## Scope and intent
This document translates the requested Windows 11 security baseline into Microsoft Intune compliance policy settings.

- Grace period target: 7 days for all compliance failures
- Where an exact direct compliance setting does not exist, the gap is flagged with a compensating control recommendation.

## Recommended UI path (latest known)
UI locations in Intune have shifted over time. As of Microsoft Learn content updated July 2026, use this path:

1. Intune admin center
2. Endpoint security
3. Device compliance
4. Policies
5. Create Policy
6. Platform: Windows 10 and later

Alternative path still seen in some tenants:

1. Intune admin center
2. Devices
3. Compliance policies
4. Policies
5. Create policy

Flag: UI path can vary by tenant flighting, role, and portal updates.

## Baseline-to-Policy mapping

### Prerequisite navigation (use once)

1. Open Intune admin center.
2. Go to Endpoint security > Device compliance > Policies.
3. Select Create Policy.
4. Set Platform to Windows 10 and later.
5. Continue to the Settings page.

### Requirement 1: BitLocker must be enabled on the OS drive

- Settings name: Require BitLocker
- Value: Require
- UI path: Compliance settings > Device health > Require BitLocker
- Effect: Device is noncompliant unless BitLocker is enabled and reported through Windows Health Attestation.
- False-positive risk: Status can lag until reboot after encryption finishes; DHA/TPM attestation delays; unsupported or legacy TPM hardware can misreport.
- Recommendation: Keep Require, include user guidance to reboot after enabling BitLocker, and keep the 7-day remediation window.

Steps:

1. In the policy settings, open Device health.
2. Find Require BitLocker.
3. Set it to Require.
4. Save and continue.

### Requirement 2: Secure Boot must be enabled

- Settings name: Require Secure Boot to be enabled on the device
- Value: Require
- UI path: Compliance settings > Device health > Require Secure Boot to be enabled on the device
- Effect: Device is noncompliant if Secure Boot is off or not attested.
- False-positive risk: Older hardware or firmware, some TPM 1.2/unsupported states, or attestation issues can report noncompliant even when the endpoint is otherwise healthy.
- Recommendation: Keep Require, pre-validate hardware readiness, and keep tightly governed exception groups for approved legacy devices only.

Steps:

1. In Device health, find Require Secure Boot to be enabled on the device.
2. Set it to Require.
3. Save and continue.

### Requirement 3: Minimum OS build N-1 (10.0.22621.2861)

- Settings name: Minimum OS version
- Value: 10.0.22621.2861
- UI path: Compliance settings > Device properties > Operating system version > Minimum OS version
- Effect: Devices running lower builds are marked noncompliant.
- False-positive risk: Stale check-in data can delay compliant state updates; a formatting mistake can fail many devices.
- Recommendation: Use exact four-part version format and peer-review the value before assignment. Consider Valid operating system builds for ring-level precision.

Steps:

1. In Device properties, open Operating system version.
2. Find Minimum OS version.
3. Enter 10.0.22621.2861.
4. Save and continue.

### Requirement 4: Windows Defender real-time protection must be on

- Settings name: Real-time protection
- Value: Require
- UI path: Compliance settings > System security > Defender > Real-time protection
- Effect: Device is noncompliant when real-time malware scanning is disabled.
- False-positive risk: Third-party AV coexistence, passive mode transitions, or service startup timing after reboot can briefly report unhealthy.
- Recommendation: Keep Require and standardize the endpoint protection model to reduce transient reporting drift.

Steps:

1. In System security > Defender, find Real-time protection.
2. Set it to Require.
3. Save and continue.

### Requirement 5: Firewall must be enabled for all profiles

- Settings name: Firewall
- Value: Require
- UI path: Compliance settings > System security > Device security > Firewall
- Effect: Requires Windows Firewall enabled and prevents user-driven disablement from remaining compliant.
- False-positive risk: Conflicting GPO or other management channels can override firewall posture; immediate post-boot sync can briefly show error.
- Recommendation: Keep Require, remove conflicting legacy GPOs, and re-sync before triaging as incident.

Steps:

1. In System security > Device security, find Firewall.
2. Set it to Require.
3. Save and continue.

### Requirement 6: A PIN or password must be configured

- Settings name: Require a password to unlock mobile devices
- Value: Require
- UI path: Compliance settings > System security > Password > Require a password to unlock mobile devices
- Effect: Users must have a device unlock credential configured to remain compliant.
- False-positive risk: The label is mobile-oriented, and kiosk or shared endpoints may be intentionally configured differently.
- Recommendation: Keep Require for user endpoints and place shared or kiosk devices in a separate scoped policy with approved exceptions.

Steps:

1. In System security > Password, find Require a password to unlock mobile devices.
2. Set it to Require.
3. Save and continue.

### Requirement 7: Device must not be jailbroken or rooted

- Settings name: No direct Windows compliance setting (not applicable on Windows compliance profile)
- Value: N/A
- UI path: Not available in Windows 10 and later compliance profile
- Effect: Windows compliance policies do not expose a jailbroken or rooted toggle like mobile platforms.
- False-positive risk: Audits can treat this as missing if platform applicability is not documented.
- Recommendation: Mark as platform N/A and use compensating controls: Require Secure Boot, Require BitLocker, Real-time protection, and optional Defender for Endpoint risk rule.

Steps:

1. Record this requirement as platform N/A in the standard.
2. Link compensating controls in the same policy set.
3. Include rationale in CAB or audit evidence.

## Grace period configuration (applies to all above settings)
Configure this in the policy action, not in each individual rule.

- UI path: Actions for noncompliance > Mark device noncompliant > Schedule (days after noncompliance)
- Section: Actions for noncompliance
- Action: Mark device noncompliant
- Schedule (days after noncompliance): 7

Effect: Devices get 7 days to remediate any failed compliance rule before being formally marked noncompliant for downstream controls such as Conditional Access.

False-positive consideration: A longer grace can temporarily allow access for at-risk devices if Conditional Access relies only on final noncompliant state.

Recommendation: Keep 7 days per requirement, but pair with risk-based Conditional Access controls (for example, Defender for Endpoint device risk) for urgent threat containment.

## UI-path and label change watchlist
The following entries are most likely to appear with different wording or section placement across tenants:

- Endpoint security > Device compliance vs Devices > Compliance policies
- Real-time protection under System security > Defender
- Require a password to unlock mobile devices label (wording may look mobile-first but is used in Windows profile)
- Valid operating system builds availability/placement (depends on profile version and tenant rollout)

Recommendation: When implementing, confirm labels in your tenant UI and capture screenshots in the CAB/change record.

## Implementation checklist

1. Create Windows 10 and later compliance policy.
2. Configure the seven mapped controls above (with Requirement 7 documented as platform N/A + compensating controls).
3. Set noncompliance action schedule to 7 days.
4. Assign to pilot device group.
5. Validate compliance reports after at least one reboot cycle on pilot devices.
6. Roll out in rings (pilot, broad, all) with weekly review of false-positive trends.
