# Root Cause Analysis (RCA): User Account Lockout - jsmith

## Incident Summary
- **User:** `jsmith`
- **System involved:** `DESKTOP-FB001`
- **Observation window:** `08:02:14` to `08:23:44` (approx. 21 minutes of captured activity)
- **Impact:** User could not access workstation due to account lockout until administrative intervention.

## Event ID Explanations

### Event ID 4625 - Failed logon attempt
Records a failed sign-in attempt to an account. In this incident it appears with:
- **Failure reason:** Unknown username or bad password (initial attempts)
- **Failure reason:** Account locked out (later attempt)
- **Source:** `DESKTOP-FB001`
- **Logon Type 2:** Interactive logon (user typing credentials at local console)
- **Logon Type 7:** Unlock attempt (user trying to unlock an existing session)

### Event ID 4740 - Account locked out
Records that an account has been locked due to lockout policy thresholds being reached.
- Confirms lockout occurred for `jsmith`
- Includes caller/source computer: `DESKTOP-FB001`

### Event ID 4722 - Account enabled
Records that an account was enabled by an administrator.
- In this case performed by `FINBRIDGE\helpdesk-admin`
- Indicates direct support/admin intervention occurred before successful return to access.

### Event ID 4624 - Successful logon
Records a successful authentication event.
- Here it confirms that after intervention, `jsmith` successfully signed in
- **Logon Type 2:** Interactive local logon

## Reconstructed Sequence of Events (Plain English)
1. At `08:02:14`, `jsmith` tried to sign in at `DESKTOP-FB001` using an incorrect credential (or incorrect username/password combination), resulting in Event `4625` (failed interactive logon).
2. At `08:04:22`, a second failed interactive sign-in occurred with the same failure reason (`4625`).
3. At `08:06:01`, the account hit lockout threshold and was locked (`4740`), called from `DESKTOP-FB001`.
4. At `08:07:45`, `jsmith` attempted to unlock/sign in again, but authentication failed because the account was already locked (`4625`, Logon Type `7` unlock).
5. At `08:22:10`, helpdesk administrator `FINBRIDGE\helpdesk-admin` enabled the account (`4722`).
6. At `08:23:44`, `jsmith` successfully signed in interactively (`4624`, Logon Type `2`).

## Most Likely Cause of Lockout (with Evidence)

### Likely cause
Repeated incorrect password entry by the user at the local workstation (`DESKTOP-FB001`) triggered account lockout policy.

### Evidence supporting this conclusion
- Multiple pre-lockout failed interactive logons (`4625`) with reason **Unknown username or bad password** at `08:02:14` and `08:04:22`.
- Lockout event (`4740`) occurred shortly after repeated failures and identifies the same source machine (`DESKTOP-FB001`).
- Post-lockout failure (`4625`, reason **Account locked out**, Logon Type `7`) confirms account state rather than ongoing credential mismatch at that point.
- Successful logon (`4624`) immediately after admin enablement (`4722`) strongly indicates credentials were either corrected/reset or access restored by account state change, not a persistent system/network authentication fault.

## 5 Whys Analysis

### Problem statement
`jsmith` was locked out and unable to access their machine.

1. **Why was `jsmith` unable to access the machine?**  
   Because the account became locked and authentication attempts were denied.

2. **Why did the account become locked?**  
   Because multiple failed logon attempts met/exceeded the account lockout threshold.

3. **Why were there multiple failed logon attempts?**  
   The entered credentials were invalid during interactive sign-in attempts (bad password/username mismatch).

4. **Why were invalid credentials entered repeatedly?**  
   Most likely user password error, stale remembered password, or confusion following a recent password change.

5. **Why did this escalate to service disruption instead of quick recovery?**  
   There was no immediate self-service correction before threshold breach, requiring helpdesk-admin intervention to re-enable the account.

## Root Cause
Primary root cause is **repeated invalid interactive credentials entered at `DESKTOP-FB001`**, resulting in policy-driven account lockout.

## Contributing Factors
- Account lockout threshold policy (working as designed) converted repeated entry errors into hard lockout.
- No successful authentication before threshold reached.
- Dependence on helpdesk intervention to restore account usability.

## Corrective and Preventive Actions (CAPA)

### Immediate corrective actions
- Confirm account status and unlock/enable through approved support workflow.
- Validate user can sign in successfully post-remediation.

### Preventive actions
- Reinforce end-user guidance for password change and credential update process.
- Encourage lock-screen password verification practices before multiple retries.
- Review whether endpoint has stale cached credentials in mapped drives/apps causing repeated prompts.
- Ensure account lockout monitoring alerts are tuned for rapid triage.
- Consider enabling/advertising self-service password reset (if policy permits).

## Confidence and Data Limits
- **Confidence:** High for lockout-by-bad-credential-attempts scenario.
- **Limitations:** Provided excerpt does not include full lockout policy values, password reset events, or external authentication source logs (AD/DC detailed fields). Additional domain controller logs could further validate exact threshold count and mechanism.
