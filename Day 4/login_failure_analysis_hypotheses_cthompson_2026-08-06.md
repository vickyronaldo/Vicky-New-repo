# Runbook: Resolve Single-User AD Login Lockout from Stale Credentials

Date: 2026-08-06  
Incident reference: FINBRIDGE\\cthompson login failure  
Confirmed pattern: Wrong-password attempts (Events 4776/4771) followed by lockout (Event 4740)

## 1. Prerequisites

Before starting, confirm all items below are available.

1. Access to Active Directory Users and Computers (ADUC) for FINBRIDGE domain administration.  
Expected result: You can open the cthompson user object in ADUC.  
Permission: [Elevated permissions required]

2. Access to a domain controller Security Event Log (or SIEM view of DC security events).  
Expected result: You can query Events 4625, 4740, 4771, and 4776 for FINBRIDGE\\cthompson.  
Permission: [Elevated permissions required]

3. Access to DHCP/NAC/asset inventory for IP-to-device lookup.  
Expected result: You can resolve source IP 10.10.8.112 to an owned asset.  
Permission: [Elevated permissions required]

4. Access to endpoint administration tools for DESKTOP-FB022 and the secondary source asset.  
Expected result: You can sign in locally or remotely to both endpoints with admin rights.  
Permission: [Elevated permissions required]

5. Approved temporary password handoff method (for example, service desk verified phone process).  
Expected result: You have a secure channel ready to deliver temporary credentials to the user.

6. User availability for one controlled sign-in test.  
Expected result: User cthompson confirms they can perform a test sign-in during the change window.

## 2. Procedure

Perform each step in order.

1. Query the DC Security log for FINBRIDGE\\cthompson covering the last 60 minutes.  
Expected result: You capture a timeline including failure and lockout events.

2. Confirm presence of Event 4740 for FINBRIDGE\\cthompson.  
Expected result: Lockout state is verified from event evidence.

3. Confirm presence of Event 4776 with error 0xC000006A or Event 4771 with failure code 0x18.  
Expected result: Wrong-password mechanism is verified.

4. Identify all unique source hosts/IPs from the failure events.  
Expected result: You have a list that includes DESKTOP-FB022 and any additional source such as 10.10.8.112.

5. Resolve each source IP to an asset owner record using DHCP/NAC/inventory.  
Expected result: Each source in the list is mapped to a device record.  
Permission: [Elevated permissions required]

6. Reset FINBRIDGE\\cthompson password to a temporary strong value in ADUC.  
Expected result: Password reset completes successfully.  
Permission: [Elevated permissions required]

7. Unlock FINBRIDGE\\cthompson account in ADUC.  
Expected result: Account status changes to unlocked.  
Permission: [Elevated permissions required]

8. Set "User must change password at next logon" on FINBRIDGE\\cthompson.  
Expected result: Flag is enabled on the user object.  
Permission: [Elevated permissions required]

9. Revoke active cloud sessions for cthompson in Entra/M365 admin portal.  
Expected result: Existing tokens/sessions are invalidated.  
Permission: [Elevated permissions required]

10. Remove stored FINBRIDGE credentials from Windows Credential Manager on DESKTOP-FB022.  
Expected result: Stale credential entries for user resources are deleted.  
Permission: [Elevated permissions required]

11. Sign out all Microsoft 365 desktop apps on DESKTOP-FB022.  
Expected result: App sessions are disconnected.

12. Sign in to Microsoft 365 desktop apps on DESKTOP-FB022 using the temporary password.  
Expected result: Apps authenticate successfully with current credentials.

13. Remove stored FINBRIDGE credentials from Windows Credential Manager on the secondary source asset (mapped from 10.10.8.112).  
Expected result: Stale credential entries are deleted on the secondary source.  
Permission: [Elevated permissions required]

14. Update any scheduled task on the secondary source that runs as cthompson with the temporary password.  
Expected result: Task credentials save successfully and task status remains ready.  
Permission: [Elevated permissions required]

15. Update any Windows service on the secondary source that runs as cthompson with the temporary password.  
Expected result: Service logon credentials update without validation error.  
Permission: [Elevated permissions required]

16. Reconnect mapped drives on DESKTOP-FB022 using the temporary password when prompted.  
Expected result: Mapped resources reconnect without access denied.

17. Ask cthompson to perform one interactive sign-in to DESKTOP-FB022.  
Expected result: User signs in successfully and reaches desktop.

18. Require cthompson to change the temporary password immediately at first sign-in prompt.  
Expected result: Password change completes and session remains active.

19. Re-run DC Security log query for FINBRIDGE\\cthompson after sign-in.  
Expected result: No new lockout event (4740) appears.

20. Monitor for 15 minutes for new Events 4625, 4771 (0x18), or 4776 (0xC000006A) for FINBRIDGE\\cthompson.  
Expected result: No new wrong-password failures are recorded.

## 3. Verification

Confirm all verification checks before closure.

1. Validate cthompson can sign out and sign back in again on DESKTOP-FB022.  
Expected result: Second sign-in succeeds.

2. Validate business-critical resources (mailbox, Teams, OneDrive, mapped drives) open successfully for cthompson.  
Expected result: All listed resources authenticate without credential prompts.

3. Validate no new Event 4740 for FINBRIDGE\\cthompson in the previous 15 minutes.  
Expected result: No relockout event is present.

4. Validate no new Event 4771 (0x18) or 4776 (0xC000006A) for FINBRIDGE\\cthompson in the previous 15 minutes.  
Expected result: No continuing stale-credential source is present.

5. Record closure note with exact verification timestamps and checked event IDs.  
Expected result: Ticket contains auditable proof of recovery.

## 4. Rollback

Use this section immediately if the procedure worsens the incident (for example, repeated relockout, broad auth disruption, or user unable to access critical services).

1. Stop further user sign-in attempts for cthompson on all devices.  
Expected result: New bad-password attempts cease.

2. Disable network connectivity on the identified offending secondary source asset (for example, disconnect NIC or block switch port).  
Expected result: Bad-auth traffic from that source stops.  
Permission: [Elevated permissions required]

3. Reset FINBRIDGE\\cthompson password to a new temporary value in ADUC.  
Expected result: Previous temporary credential is invalidated.  
Permission: [Elevated permissions required]

4. Unlock FINBRIDGE\\cthompson account in ADUC again.  
Expected result: Account returns to unlocked state.  
Permission: [Elevated permissions required]

5. Force sign-out/revoke sessions again in Entra/M365 for cthompson.  
Expected result: Old tokens are removed to prevent replay attempts.  
Permission: [Elevated permissions required]

6. Perform one sign-in test only on DESKTOP-FB022 after confirming no fresh 4625/4771/4776 events for 5 minutes.  
Expected result: Controlled login either succeeds cleanly or reproduces issue in isolation.

7. Escalate to Identity/AD on-call with event exports if controlled login still fails.  
Expected result: Incident ownership transfers with complete technical evidence.

## 5. Notes

- Edge case: If failure events continue from an unknown IP, treat as an unmanaged device or stale mobile client and block source at network edge pending identification.
- Edge case: If cthompson is used as a service account anywhere, coordinate with application owner before password reset to avoid wider service interruption.
- Warning: Do not perform repeated unlock attempts before removing stale credential sources; this will immediately relock the account.
- Warning: Keep temporary passwords short-lived and force user password change at first successful interactive sign-in.
- Related event pattern for this incident: 4776/4625 sequence, then 4740 lockout, followed by 4771 from secondary source (10.10.8.112).
- Related incidents: [RCA_login_failure_cthompson_2026-08-06.md](Day%204/RCA_login_failure_cthompson_2026-08-06.md), [known_error_record_login_failure_cthompson_2026-08-06.md](Day%204/known_error_record_login_failure_cthompson_2026-08-06.md), [closure_note_login_failure_cthompson_2026-08-06.md](Day%204/closure_note_login_failure_cthompson_2026-08-06.md).
