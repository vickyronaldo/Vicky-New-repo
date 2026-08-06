# Root Cause Analysis (RCA): User Login Failure - FINBRIDGE\cthompson

## Incident Summary
- Incident: Single-user login failure for FINBRIDGE\cthompson.
- First observed: Approximately 08:40.
- Affected scope: One user only (cthompson).
- Reported change correlation: Nil.
- Service restoration: Resolution actions applied; issue confirmed resolved at 09:09.
- Post-fix verification: User successfully logged in to host; no further issues reported.

## Business Impact
- One user unable to access desktop/host during incident window.
- Short-term productivity impact for affected user.
- No wider team or service outage observed.

## Supporting Evidence

### Security Event Log Evidence (DESKTOP-FB022, incident window 08:44-09:12)
- 08:44:01 - Event 4776 Audit Failure: domain credential validation failed for FINBRIDGE\cthompson, error 0xC000006A (wrong password), source workstation DESKTOP-FB022.
- 08:44:03 - Event 4625 Audit Failure: unknown user name or bad password, logon type 2 (interactive), source DESKTOP-FB022.
- 08:44:28 - Event 4625 Audit Failure: unknown user name or bad password, logon type 2 (interactive), source DESKTOP-FB022.
- 08:44:55 - Event 4625 Audit Failure: unknown user name or bad password, logon type 2 (interactive), source DESKTOP-FB022.
- 08:44:56 - Event 4740 Audit Failure: account FINBRIDGE\cthompson locked out, caller computer DESKTOP-FB022.
- 08:45:10 - Event 4625 Audit Failure: account locked out, logon type 7 (unlock attempt), source DESKTOP-FB022.
- 08:45:44 - Event 4771 Audit Failure: Kerberos pre-authentication failed, failure code 0x18 (wrong password), source IP 10.10.8.112.
- 08:46:01 - Event 4771 Audit Failure: Kerberos pre-authentication failed, failure code 0x18 (wrong password), source IP 10.10.8.112.
- 08:46:33 - Event 4771 Audit Failure: Kerberos pre-authentication failed, failure code 0x18 (wrong password), source IP 10.10.8.112.

### Evidence Interpretation
- Repeated wrong-password attempts are directly evidenced by Event 4776 (0xC000006A) and Event 4771 (0x18).
- Account lockout is directly evidenced by Event 4740.
- Continued wrong-password attempts after initial failures indicate stale or cached credentials from one or more sources.
- Presence of a second source (10.10.8.112) indicates this was not only a single manual mistype on DESKTOP-FB022.

## Timeline
1. ~08:40 - User cthompson reports inability to log in.
2. 08:44:01 - First recorded wrong-password credential validation failure (Event 4776, 0xC000006A).
3. 08:44:03 to 08:44:55 - Repeated interactive bad-password failures from DESKTOP-FB022 (Event 4625).
4. 08:44:56 - Account lockout recorded (Event 4740).
5. 08:45:10 - Unlock attempt fails because account remains locked (Event 4625, logon type 7).
6. 08:45:44 to 08:46:33 - Additional Kerberos wrong-password failures from 10.10.8.112 (Event 4771, 0x18), indicating persistent stale credential attempts from another source.
7. Resolution window - Password reset, account unlock, and stale credential source cleanup actions completed.
8. 09:09 - Service confirmed restored; user verified able to log in to host with no reported issues.

## Root Cause
Primary root cause was repeated use of incorrect/stale credentials for FINBRIDGE\cthompson across at least two sources, which triggered account lockout and blocked successful login until credentials were corrected and lockout state was remediated.

## Why This Root Cause Is High Confidence
- Wrong-password failure codes are explicit and repeated (4776: 0xC000006A; 4771: 0x18).
- Lockout event is explicit (4740) and time-adjacent to repeated failures.
- Multi-source pattern (DESKTOP-FB022 and 10.10.8.112) explains continued failures until full credential hygiene/remediation.
- Successful post-remediation login at 09:09 confirms corrective path addressed the incident mechanism.

## 5 Whys Analysis

### Problem statement
cthompson could not log in during the business morning window.

1. Why could the user not log in?
Because the account entered a locked-out state.

2. Why was the account locked out?
Because repeated authentication attempts used wrong credentials.

3. Why were repeated wrong credentials submitted?
Because stale/cached credentials were still configured in one or more sessions/devices.

4. Why did stale credentials continue after initial failure?
Because at least one additional source (10.10.8.112) continued background/auth attempts.

5. Why was this not prevented before lockout impact?
Because there was no immediate coordinated credential hygiene across all user-associated endpoints/sessions after password mismatch began.

## Resolution Implemented
1. Reset FINBRIDGE\cthompson password to a known-good temporary value.
2. Unlocked account in AD.
3. Required password change at next successful sign-in.
4. Removed/updated stale saved credentials from affected sources.
5. Validated login from primary user host after remediation.
6. Monitored for recurrence indicators during immediate post-fix window.

## Verification of Fix
- Resolution timestamp: 09:09.
- User verification: cthompson successfully logged in to host.
- Service verification: No further issues reported by user.
- Technical verification objective met: no immediate recurrence reported after remediation.

## Corrective and Preventive Actions (CAPA)

### Corrective actions completed
- Restored account access (reset + unlock).
- Removed stale credential sources causing repeated bad-auth attempts.
- Confirmed end-user recovery.

### Preventive actions
1. Enforce post-password-change checklist for users: update credentials on all signed-in devices/apps immediately.
2. Add support runbook step to identify and remediate secondary sources when Event 4771 repeats from non-primary IPs.
3. Add alerting threshold for rapid sequence: 4776/4625 followed by 4740 for same account.
4. Require endpoint credential cache cleanup validation before closing lockout incidents.
5. Capture source-IP-to-asset mapping rapidly (DHCP/NAC/inventory) as standard triage step.

## Residual Risk and Follow-up
- Residual risk: Low, if all stale credential sources were remediated.
- Follow-up checks:
  - Confirm no new 4771 (0x18), 4776 (0xC000006A), or 4740 for cthompson in next business cycle.
  - Confirm no recurring login complaints from cthompson.

## Final Status
- Incident state: Resolved.
- Resolution time: 09:09.
- User impact status: Cleared for cthompson based on successful login verification and no ongoing issues reported.
