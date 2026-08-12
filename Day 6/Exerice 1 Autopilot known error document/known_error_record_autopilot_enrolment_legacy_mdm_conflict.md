Symptom: During Autopilot provisioning, enrolment fails and the device does not complete provisioning. The observed failure includes EnrollmentState Failed, with no policy payload completion (ProfilesApplied: 0 of 4).

Cause: The verified root cause is a pre-existing legacy manual MDM enrolment from 2023-11-04 that conflicts with new Autopilot enrolment. The RCA confirms error 0x80180014 with the message that the device is already enrolled in MDM.

Scope: Affected systems are Windows devices going through Autopilot where a stale legacy manual MDM enrolment state or conflicting management record exists. In this incident record, the scope was a single affected device.

Workaround: Restore service by removing stale Intune/Entra device management records and disconnecting the legacy work or school enrolment on the device, then rebooting and rerunning Autopilot from OOBE. If disconnect fails, reset or wipe the device to return to a clean OOBE state before retry.

Permanent fix: Enforce a pre-Autopilot hygiene gate to detect and clean legacy enrolment conflicts before profile assignment. Standardize the runbook to require stale-record cleanup and block provisioning until checks pass.

How to spot it: Identify Autopilot failures showing the same verified pattern: EnrollmentState Failed, ErrorCode 0x80180014 with the message that the device is already enrolled in MDM, and ProfilesApplied 0 of 4. Cross-check Intune/Autopilot investigation artifacts used in the RCA; no specific event IDs were documented in the verified incident evidence.