# Login Failure Analysis and Hypotheses

Date: 2026-08-06  
User: cthompson  
Symptom: User cannot log in  
Scope facts used only:
- Impact: cthompson only (single user)
- Since: ~08:40 this morning
- Known change: Nil

## Ranked Most Likely Causes (Most Probable First)

1. Account lockout or bad password state
Why this fits scope facts:
- Single-user impact points to a user-specific identity issue.
- Sudden onset around a specific time is consistent with lockout after repeated failures.
Fastest single check:
- Check cthompson account status in AD/Entra sign-in logs for lockout/disabled state and latest failure reason.

2. Incorrect credentials entered (or stale saved credentials)
Why this fits scope facts:
- Only one affected user is typical for credential mismatch.
- No broader service issue indicated by scope.
Fastest single check:
- Perform one controlled sign-in using known-good credentials (or password reset flow) from a private browser session.

3. Conditional Access or MFA failure for this user
Why this fits scope facts:
- CA/MFA issues can target a single user while others are unaffected.
- Can start at token expiry or auth challenge time without a reported change.
Fastest single check:
- Review cthompson’s most recent Entra sign-in event for CA/MFA failure code (deny, timeout, non-compliance requirement).

4. Account state restriction (disabled, expired, blocked sign-in)
Why this fits scope facts:
- User-object restrictions are inherently single-user impact.
- Time-based expiry/restriction can appear suddenly in the morning with no ticketed change.
Fastest single check:
- Verify enabled/disabled status, account expiry, and sign-in block flags for cthompson.

5. Endpoint/session-specific issue on the user device
Why this fits scope facts:
- If identity status is healthy, single-user symptom often narrows to device/session condition.
- Local cache/token/profile/network path issue can appear abruptly at a specific time.
Fastest single check:
- Attempt login from a known-good alternate device/network; success there isolates the issue to the original endpoint.

## Working Position
- No single root cause is confirmed yet.
- This is a ranked hypothesis list for rapid elimination, not a final diagnosis.

## Event Evidence Added (Incident Window)

Source: Security Event Log on DESKTOP-FB022  
Window: 2024-03-15 08:44-09:12

Key events:
- 08:44:01 - Event 4776 Audit Failure, FINBRIDGE\cthompson, error 0xC000006A (wrong password), source workstation DESKTOP-FB022.
- 08:44:03 - Event 4625 Audit Failure, FINBRIDGE\cthompson, unknown user name or bad password, logon type 2, source DESKTOP-FB022.
- 08:44:28 - Event 4625 Audit Failure, FINBRIDGE\cthompson, unknown user name or bad password, logon type 2, source DESKTOP-FB022.
- 08:44:55 - Event 4625 Audit Failure, FINBRIDGE\cthompson, unknown user name or bad password, logon type 2, source DESKTOP-FB022.
- 08:44:56 - Event 4740 Audit Failure, user account locked out, FINBRIDGE\cthompson, caller computer DESKTOP-FB022.
- 08:45:10 - Event 4625 Audit Failure, FINBRIDGE\cthompson, account locked out, logon type 7 (unlock attempt), source DESKTOP-FB022.
- 08:45:44 - Event 4771 Audit Failure, Kerberos pre-auth failed, FINBRIDGE\cthompson, failure code 0x18 (wrong password), source IP 10.10.8.112.
- 08:46:01 - Event 4771 Audit Failure, Kerberos pre-auth failed, FINBRIDGE\cthompson, failure code 0x18 (wrong password), source IP 10.10.8.112.
- 08:46:33 - Event 4771 Audit Failure, Kerberos pre-auth failed, FINBRIDGE\cthompson, failure code 0x18 (wrong password), source IP 10.10.8.112.

## Evidence Assessment Against Each Hypothesis

1. Account lockout or bad password state  
Judgement: Supports  
Determining events:
- Event 4776 at 08:44:01 (wrong password 0xC000006A).
- Event 4625 at 08:44:03, 08:44:28, 08:44:55 (bad password failures).
- Event 4740 at 08:44:56 (account locked out).
- Event 4625 at 08:45:10 (account locked out).

2. Incorrect credentials entered (or stale saved credentials)  
Judgement: Supports  
Determining events:
- Event 4776 at 08:44:01 (wrong password 0xC000006A).
- Event 4625 at 08:44:03, 08:44:28, 08:44:55 (bad password failures).
- Event 4771 at 08:45:44, 08:46:01, 08:46:33 (wrong password 0x18) from 10.10.8.112, indicating repeated wrong-credential attempts from another source.

3. Conditional Access or MFA failure for this user  
Judgement: Contradicts  
Determining events:
- Event 4776 at 08:44:01 and Event 4771 at 08:45:44/08:46:01/08:46:33 show wrong-password failures.
- Event 4740 at 08:44:56 and Event 4625 at 08:45:10 show lockout outcome.
- No event evidence in this set indicates CA deny or MFA challenge failure as the trigger.

4. Account state restriction (disabled, expired, blocked sign-in)  
Judgement: Neutral  
Determining events:
- Event 4740 at 08:44:56 confirms lockout state did occur.
- Earlier Event 4776 at 08:44:01 and Event 4625 at 08:44:03/08:44:28/08:44:55 show wrong password first.
- This supports lockout as a resulting state, but does not prove disabled/expired/admin block as initial cause.

5. Endpoint/session-specific issue on the user device  
Judgement: Neutral  
Determining events:
- Event 4625 at 08:44:03, 08:44:28, 08:44:55 from DESKTOP-FB022 supports local endpoint involvement.
- Event 4771 at 08:45:44, 08:46:01, 08:46:33 from 10.10.8.112 indicates an additional source, so not endpoint-only.

## Surviving Hypothesis

Incorrect credentials or stale saved credentials (from one or more devices/sessions) caused repeated bad-password attempts, which then triggered account lockout.

Evidence basis:
- Wrong-password failures are explicit (4776 at 08:44:01; 4771 at 08:45:44/08:46:01/08:46:33).
- Lockout is explicit (4740 at 08:44:56).
- Continued attempts after lockout indicate a likely cached or automated credential source.

## Detailed Resolution Steps

1. Restore access safely
- Reset cthompson password to a temporary strong password.
- Unlock the account in AD.
- Require password change at next sign-in.
- Perform one controlled sign-in on the primary workstation.

2. Stop active bad-auth sources
- Pause use of non-primary devices or disconnect them temporarily.
- Revoke active user sessions where applicable.
- Confirm no new 4625/4771/4776 events for several minutes before next test.

3. Identify and remediate secondary source (10.10.8.112)
- Map IP 10.10.8.112 to an asset via DHCP/inventory/NAC.
- Remove or update stale credentials on that asset:
	- Credential Manager entries
	- Outlook/Teams/OneDrive saved auth
	- Mapped drives using old credentials
	- Scheduled tasks running as cthompson
	- Services configured with cthompson account

4. Clean primary endpoint (DESKTOP-FB022)
- Remove stale credentials from Credential Manager.
- Sign out and sign back in to Office/M365 apps.
- Reconnect mapped resources with the current password.
- Reboot once to clear auth cache.

5. Validate and close
- Confirm successful user sign-in.
- Monitor 15-30 minutes for absence of:
	- Event 4771 (0x18)
	- Event 4776 wrong-password
	- Event 4625 for cthompson
	- Event 4740 relockout
- If clean, record root cause as stale/incorrect credentials from secondary source causing lockout.

6. Prevent recurrence
- Document offending device/app and remediation performed.
- Advise user to update credentials on all devices/apps immediately after password changes.
- Review lockout policy threshold/window if recurrence is frequent.
