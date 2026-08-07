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

1. Open Event Viewer on a domain controller and navigate to Windows Logs > Security.  
Expected result: The Security log is visible and loaded with current events.

2. Click Filter Current Log and enter Event IDs 4625, 4740, 4771, 4776.  
Expected result: The event list refreshes and shows only those four IDs.

3. Enter FINBRIDGE\\cthompson in Find (Ctrl+F) and search within filtered events.  
Expected result: At least one event row for FINBRIDGE\\cthompson is highlighted.

4. Open the most recent Event 4740 and record Caller Computer Name and Time Created in the ticket notes.  
Expected result: Ticket notes contain an exact lockout timestamp and caller host value.

5. Open a recent Event 4776 or 4771 and confirm failure code 0xC000006A (4776) or 0x18 (4771).  
Expected result: Wrong-password failure code is visible in event details.

6. Build a source list from event details by recording each unique caller host and source IP.  
Expected result: Source list includes DESKTOP-FB022 and 10.10.8.112 when present.

7. Open the DHCP/NAC/inventory console and search for IP 10.10.8.112.  
Expected result: The IP resolves to a single asset record with hostname and owner.  
Permission: [Elevated permissions required]

8. Open Active Directory Users and Computers (dsa.msc), browse to user FINBRIDGE\\cthompson, and open Properties.  
Expected result: User properties window opens for FINBRIDGE\\cthompson.  
Permission: [Elevated permissions required]

9. Right-click FINBRIDGE\\cthompson in ADUC and select Reset Password.  
Expected result: Reset Password dialog opens.  
Permission: [Elevated permissions required]

10. Enter a temporary strong password in Reset Password and click OK.  
Expected result: ADUC shows a success confirmation for password reset.  
Permission: [Elevated permissions required]

11. In Reset Password dialog, tick User must change password at next logon before clicking OK.  
Expected result: The user object now has change-at-next-logon enforced.  
Permission: [Elevated permissions required]

12. In ADUC user Properties > Account tab, clear Account is locked out and click Apply.  
Expected result: Lockout checkbox clears and remains cleared after Apply.  
Permission: [Elevated permissions required]

13. Open Microsoft Entra admin center > Users > All users > cthompson > Revoke sessions.  
Expected result: Portal shows confirmation that sessions/tokens were revoked.  
Permission: [Elevated permissions required]

14. On DESKTOP-FB022, open Control Panel > Credential Manager > Windows Credentials.  
Expected result: Saved Windows credential entries list is visible.  
Permission: [Elevated permissions required]

15. Remove each credential entry containing FINBRIDGE, DESKTOP-FB022, file share paths, or MicrosoftOffice targets for cthompson.  
Expected result: Those specific stale entries no longer appear in Windows Credentials.  
Permission: [Elevated permissions required]

16. On DESKTOP-FB022, sign out from Outlook, Teams, and OneDrive via each app profile/account menu.  
Expected result: Each app returns to its sign-in screen.

17. Sign in to Outlook, Teams, and OneDrive on DESKTOP-FB022 using FINBRIDGE\\cthompson and temporary password.  
Expected result: All three apps show connected status with no password error.

18. On the secondary source asset, open Control Panel > Credential Manager > Windows Credentials.  
Expected result: Saved Windows credential entries list is visible on that asset.  
Permission: [Elevated permissions required]

19. Remove each FINBRIDGE or cthompson-related saved credential from Windows Credentials on the secondary asset.  
Expected result: No FINBRIDGE or cthompson credential entry remains on that asset.  
Permission: [Elevated permissions required]

20. On the secondary source asset, open Task Scheduler > Task Scheduler Library and update stored password for each task running as FINBRIDGE\\cthompson.  
Expected result: Task properties save successfully and Last Run Result does not show credential failure code.  
Permission: [Elevated permissions required]

21. On the secondary source asset, open Services.msc and update Log On password for each service configured as FINBRIDGE\\cthompson.  
Expected result: Service properties save without "logon failure" validation error.  
Permission: [Elevated permissions required]

22. On DESKTOP-FB022, disconnect and reconnect mapped drives from File Explorer > This PC using the temporary password when prompted.  
Expected result: Drive icons show connected and open folder contents without access denied.

23. Instruct cthompson to sign in interactively on DESKTOP-FB022 once using the temporary password.  
Expected result: User reaches desktop without "account locked" or "bad password" message.

24. Instruct cthompson to complete the mandatory password-change prompt at first sign-in.  
Expected result: Password change completes and Windows session remains active.

25. Return to DC Event Viewer Security log and re-run Find for FINBRIDGE\\cthompson.  
Expected result: No newer Event 4740 exists after the successful sign-in time.

26. Keep Security log filtered and observe for 15 minutes for FINBRIDGE\\cthompson.  
Expected result: No new Events 4625, 4771 (0x18), or 4776 (0xC000006A) appear in that window.

## 3. Verification

Confirm all verification checks before closure.

1. Ask cthompson to sign out from Windows on DESKTOP-FB022 and sign back in with the new permanent password.  
Expected result: Sign-in succeeds on first attempt and no lockout/bad-password message appears.

2. Open Outlook on DESKTOP-FB022 and send a test email to self.  
Expected result: Mail sends successfully and appears in Sent Items within 60 seconds.

3. Open Teams on DESKTOP-FB022 and place a test call to voicemail or test contact.  
Expected result: Call connects and audio path is established.

4. Open OneDrive on DESKTOP-FB022 and create a test file in synced folder.  
Expected result: OneDrive status changes to syncing, then returns to Up to date.

5. Open each mapped drive in File Explorer > This PC.  
Expected result: Folder content loads without password prompt or access denied.

6. In Event Viewer on DC, filter Security log for Event ID 4740 and search FINBRIDGE\\cthompson for the last 15 minutes.  
Expected result: Zero matching 4740 events are returned in that time window.

7. In Event Viewer on DC, filter Security log for Event IDs 4771 and 4776 and search FINBRIDGE\\cthompson for the last 15 minutes.  
Expected result: Zero new 4771 (0x18) or 4776 (0xC000006A) events are returned.

8. Add closure evidence to the ticket including timestamp of successful login and screenshots or exports of final event queries.  
Expected result: Ticket contains enough evidence for another engineer to audit and reproduce closure logic.

## 4. Rollback

Use this emergency rollback if remediation causes relockout or broader auth impact. Complete the sequence below in under 3 minutes.

1. Start a 3-minute timer in your phone clock app.  
Expected result: Countdown timer is running and visible.

2. Open Active Directory Users and Computers (`dsa.msc`) and select FINBRIDGE\\cthompson.  
Expected result: The cthompson user object is highlighted in ADUC.  
Permission: [Elevated permissions required]

3. Right-click FINBRIDGE\\cthompson, select Reset Password, enter a new temporary password, tick User must change password at next logon, and click OK.  
Expected result: ADUC displays password reset success confirmation.  
Permission: [Elevated permissions required]

4. In ADUC, open FINBRIDGE\\cthompson Properties > Account, clear Account is locked out, and click Apply.  
Expected result: Lockout checkbox is cleared and stays cleared.  
Permission: [Elevated permissions required]

5. Open Microsoft Entra admin center > Users > All users > cthompson and click Revoke sessions.  
Expected result: Portal confirmation shows sessions/tokens revoked.  
Permission: [Elevated permissions required]

6. Open NAC/switch management portal, locate the secondary source asset IP (10.10.8.112), and apply Quarantine or Disable Port action.  
Expected result: The asset status changes to quarantined/blocked and stops sending auth attempts.  
Permission: [Elevated permissions required]

7. On DESKTOP-FB022, ask cthompson to sign in once with the temporary password.  
Expected result: User reaches desktop without account lockout or bad-password error.

8. If step 7 fails, page Identity/AD on-call and attach latest Event IDs 4625, 4740, 4771, and 4776 from Event Viewer > Windows Logs > Security.  
Expected result: Escalation is accepted with complete event evidence.

## 5. Notes

- Edge case: If failure events continue from an unknown IP, treat as an unmanaged device or stale mobile client and block source at network edge pending identification.
- Edge case: If cthompson is used as a service account anywhere, coordinate with application owner before password reset to avoid wider service interruption.
- Warning: Do not perform repeated unlock attempts before removing stale credential sources; this will immediately relock the account.
- Warning: Keep temporary passwords short-lived and force user password change at first successful interactive sign-in.
- Related event pattern for this incident: 4776/4625 sequence, then 4740 lockout, followed by 4771 from secondary source (10.10.8.112).
- Related incidents: [RCA_login_failure_cthompson_2026-08-06.md](Day%204/RCA_login_failure_cthompson_2026-08-06.md), [known_error_record_login_failure_cthompson_2026-08-06.md](Day%204/known_error_record_login_failure_cthompson_2026-08-06.md), [closure_note_login_failure_cthompson_2026-08-06.md](Day%204/closure_note_login_failure_cthompson_2026-08-06.md).
