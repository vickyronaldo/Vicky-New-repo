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

| Requirement | Setting name (exact Intune label) | Value | Effect (plain English) | False-positive risk | Recommendation to reduce false positives without weakening security |
|---|---|---|---|---|---|
| 1. BitLocker must be enabled on the OS drive | Require BitLocker | Require | Device is noncompliant unless BitLocker is enabled and reported through Windows Health Attestation. | Status can lag until reboot after encryption finishes; DHA/TPM attestation delays; unsupported/legacy TPM hardware can misreport. | Keep requirement as Require, but include user guidance to reboot after enabling BitLocker and allow 7-day remediation window. For diagnostics, pair with reporting from encryption posture in Endpoint Security. |
| 2. Secure Boot must be enabled | Require Secure Boot to be enabled on the device | Require | Device is noncompliant if Secure Boot is off or not attested. | Older hardware/firmware, certain TPM 1.2/unsupported states, or attestation issues may show noncompliant even when endpoint is otherwise healthy. | Keep Require. Pre-validate hardware readiness in procurement standards and maintain exclusion groups only for approved legacy exceptions with compensating controls and retirement date. |
| 3. Minimum OS build N-1 (10.0.22621.2861) | Minimum OS version | 10.0.22621.2861 | Blocks devices running lower builds from being compliant. | Devices on supported but newer feature branches can still pass Minimum OS, but temporarily stale inventory/check-in can delay state update; typo in version format can incorrectly fail all devices. | Use exact 4-part version format and peer review the entered value. Consider using Valid operating system builds for ring-based precision while keeping N-1 floor policy intent. |
| 4. Microsoft Defender real-time protection must be on | Real-time protection | Require | Device is noncompliant when real-time malware scanning is disabled. | Third-party AV coexistence or passive mode transitions can briefly report unhealthy; service startup race after reboot may momentarily fail. | Keep Require. Standardize AV stack (single primary endpoint protection model) and monitor transient states before escalating; 7-day grace absorbs short-lived startup/reporting drift. |
| 5. Firewall must be enabled for all profiles | Firewall | Require | Requires Windows Firewall enabled and prevents user disabling through compliance enforcement logic. | Conflicting GPO/device config can override and cause noncompliance despite intended secure config; immediate post-boot sync can return temporary Error state. | Keep Require. Remove conflicting legacy GPOs and manage firewall posture from Intune policy consistently; if error appears right after boot, force re-sync before incident assignment. |
| 6. A PIN or password must be configured | Require a password to unlock mobile devices | Require | User must have a device unlock credential configured to remain compliant. | Label references "mobile devices" but applies in Windows compliance context; shared/kiosk/special-purpose endpoints might intentionally not have interactive unlock patterns. | Keep Require for user endpoints. Scope kiosk/shared-device profiles separately and apply dedicated compliance policy with explicit business exception approval. |
| 7. Device must not be jailbroken or rooted | No direct Windows compliance setting (not applicable on Windows compliance profile) | N/A | Intune Windows compliance does not expose a "jailbroken/rooted" toggle like mobile platforms. | Requirement may appear unmet in audit mapping if treated as mandatory direct setting. | Document as platform N/A. Use compensating controls: Require Secure Boot, Require BitLocker, Defender real-time protection, and optionally Defender for Endpoint risk-level compliance rule. |

## Grace period configuration (applies to all above settings)
Configure this in the policy action, not in each individual rule.

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
