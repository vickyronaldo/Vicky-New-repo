# End-User Communications: Login Incident (cthompson)

## Shared Facts (used in all versions)
- Impact was limited to one user account: cthompson.
- Issue began around 08:40.
- Cause was repeated sign-in attempts using outdated/incorrect saved credentials from more than one source, which triggered account lockout.
- Actions taken: password reset, account unlock, and cleanup of stale saved credentials.
- Resolution was confirmed at 09:09.
- Verification: successful host login and no further issues reported.
- No evidence of data impact.

## Audience 1 - Non-Technical Executive
Your access is restored and your data is safe. This morning, one user account (cthompson) could not sign in from about 08:40 after old saved sign-in details from more than one source repeatedly used the wrong password and locked the account. We reset the password, unlocked the account, and cleared old saved sign-in details. Service was confirmed restored at 09:09 with successful login and no further issues. No action is required unless the issue returns.

## Audience 2 - Affected End-User Team (10 People)
Quick update: this morning, one user account (cthompson) had a sign-in issue from about 08:40 because old saved sign-in details on more than one source kept trying the wrong password, which locked the account. We fixed this by resetting the password, unlocking the account, and clearing old saved sign-in details; access was confirmed restored at 09:09, with successful login and no further issues, and there is no evidence of data impact. If you see the same problem, stop retrying sign-in and contact the DWP Service Desk immediately.

## Audience 3 - Engineer-to-Engineer Internal Note
Incident: single-user auth failure (FINBRIDGE\\cthompson), started ~08:40, resolved 09:09.

Root cause:
- Repeated bad-auth attempts from more than one source using stale/incorrect saved credentials caused AD lockout.

Supporting signal:
- Lockout sequence and repeated wrong-password pattern in security logs.
- Multi-source behavior observed (primary workstation plus secondary source), consistent with cached credential replay.
- No evidence of data impact.

Exact action taken:
1. Reset cthompson password to known-good temporary value.
2. Unlocked account in AD.
3. Enforced password change at next successful sign-in.
4. Cleared/updated stale saved credentials on involved sources.
5. Performed controlled login test on host.

Config/detail:
- Account: FINBRIDGE\\cthompson.
- Scope: one user only.
- Secondary source presence confirmed during incident analysis (indicating non-single-endpoint credential replay path).

Verification step:
- Service confirmed restored at 09:09.
- User successfully logged in to host.
- No further issues reported post-fix.

Preventive action needed:
1. Standardize post-password-change credential hygiene across all user devices/apps.
2. For lockout incidents, require source mapping and stale credential cleanup before closure.
3. Add alerting for rapid bad-password-to-lockout sequences and repeat failures from secondary sources.
