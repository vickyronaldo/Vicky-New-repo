## Version Header

- Title: Runbook: Finance Team Cannot Access Shared Drives
- Version: 1.0
- Date: 07/08/2026
- Author: Vicky_bePositive
- Reviewed: self
- Status: draft
- Change: initial version from RCA

# Runbook: Finance Team Cannot Access Shared Drives

## 1. Prerequisites
Collect the following before starting:

1. Incident ticket ID and impacted Finance user IDs.
2. Exact share path that fails (example: \\FS01\Finance).
3. Drive letter mapping that fails (example: F:).
4. Exact error text and error code shown to the user.
5. Impact scope (single user, subset of Finance, or all Finance users).
6. User workstation name and IP address.
7. File server name hosting the Finance share.
8. Time the failure started.
9. Confirmation whether this happens on VPN, office network, or both.
10. Access to Active Directory Users and Computers.
11. Access to file server share and NTFS permission settings.
12. Access to DNS tools and file server event logs.

Required permissions:
- [Elevated Permissions Required] Domain rights to view user group membership in Active Directory.
- [Elevated Permissions Required] Local Administrator or delegated rights on file server to review SMB sessions and event logs.
- [Elevated Permissions Required] Rights to edit share permissions and NTFS ACLs if remediation is required.

## 2. Procedure (Ranked by Priority)

Priority 1 - Fast user-impact checks

1. On the affected user PC, open File Explorer > address bar and enter the exact UNC path (example: `\\FS01\Finance`).
Expected result: Either the folder opens, or a specific error appears (for example, `Access is denied` or `The network path was not found`) and is captured in the ticket.

2. On the affected user PC, open Command Prompt and run `whoami /groups`.
Expected result: The required Finance security group (for example, `FIN_Share_Finance_RW`) appears in the output.

3. In the same Command Prompt window, run `klist`.
Expected result: A valid `krbtgt` ticket exists and `End Time` is in the future.

4. In the same Command Prompt window, run `nslookup <fileserver-fqdn>`.
Expected result: `Name` matches the file server FQDN and `Address` matches the expected server IP from CMDB.

5. Open Windows PowerShell on the affected user PC and run `Test-NetConnection <fileserver-fqdn> -Port 445`.
Expected result: `TcpTestSucceeded : True` is returned.

Priority 2 - Access control checks

6. On a management server, open Active Directory Users and Computers > domain > Users (or the team OU) > affected user > Properties > Member Of tab.
Expected result: The user is a member of the required Finance access group.
[Elevated Permissions Required]

7. On the file server, open File Explorer > right-click Finance share folder > Properties > Sharing > Advanced Sharing > Permissions.
Expected result: The required Finance group exists and has the approved share permissions (Read or Change as per standard).
[Elevated Permissions Required]

8. In the same folder properties window, open Security tab > Advanced.
Expected result: The required Finance group has the approved NTFS permissions (Read/Execute or Modify as per standard).
[Elevated Permissions Required]

9. In Active Directory Users and Computers > affected user > Properties > Member Of, click Add and add the required Finance group if it is missing.
Expected result: The required Finance group appears in the user Member Of list.
[Elevated Permissions Required]

10. In folder Properties > Sharing > Advanced Sharing > Permissions, add or correct the Finance group permission entry to match standard.
Expected result: Share permission list exactly matches the approved Finance ACL baseline.
[Elevated Permissions Required]

11. In folder Properties > Security > Advanced, add or correct the Finance group NTFS permission entry to match standard.
Expected result: NTFS permission list exactly matches the approved Finance ACL baseline.
[Elevated Permissions Required]

Priority 3 - Session and mapping refresh

12. On the affected user PC, open Command Prompt as the signed-in user and run `gpupdate /force`.
Expected result: Output shows `User Policy update has completed successfully`.

13. On the affected user PC, sign out from Start menu > profile icon > Sign out.
Expected result: The user returns to the Windows sign-in screen.

14. Sign back in with the same affected user account.
Expected result: Desktop opens normally and a new user token is created.

15. Open Command Prompt and run `net use * /delete /y`.
Expected result: Output confirms mapped network connections were deleted with no error.

16. In the same Command Prompt window, run `net use F: \\FS01\Finance /persistent:yes` (replace `F:` and path with approved standard if different).
Expected result: Output returns `The command completed successfully`.

17. Open File Explorer > This PC > `F:` drive and create `finance_access_test.txt` if Finance users are expected to have write access.
Expected result: File creation succeeds for read-write users, or is correctly blocked for read-only users.

Priority 4 - Server-side validation

18. On the file server, open Event Viewer > Windows Logs > Security and Applications and Services Logs > Microsoft > Windows > SMBServer > Operational, then filter by time window and `Access Denied` events.
Expected result: You find either zero denied events or identifiable denied events tied to the affected user and time.
[Elevated Permissions Required]

19. On the file server, open Windows PowerShell (Run as Administrator) and run `Get-SmbSession | Where-Object { $_.ClientUserName -like "*<username>*" }`.
Expected result: Session output returns one or more rows with the affected user and session ID.
[Elevated Permissions Required]

20. In the same PowerShell window, run `Close-SmbSession -SessionId <id>` for only the affected user's session.
Expected result: The selected SMB session closes and the user can reconnect to the share without stale-session errors.
[Elevated Permissions Required]

## 3. Verification

1. From three different affected Finance user PCs, open File Explorer > address bar and enter the UNC path.
Pass criteria: All three users open the folder within 10 seconds and no access error dialog appears.

2. From the same three user PCs, open File Explorer > This PC > mapped Finance drive letter.
Pass criteria: All three users can browse folders and perform the expected action (read-only open or read-write create test file).

3. On the file server, review Event Viewer logs for the next 30 minutes in Security and SMBServer Operational.
Pass criteria: No new `Access Denied` events are recorded for the validated users and share path.

4. In the ITSM portal, filter incidents by category `Finance Shared Drive` and time `Last 60 minutes`.
Pass criteria: No new incidents are logged with the same error signature.

## 4. Rollback

Use this rollback only if access becomes worse after permission or mapping changes.

Rollback timing rule:
- Group removal must be completed in under 2 minutes from rollback start time.
- Start a timer before Step 1 and record start and end times in the incident ticket.

1. On a management server, open Active Directory Users and Computers > affected user > Properties > Member Of and remove only the group added during this incident.
Expected result: The removed group is no longer listed in Member Of and the action is completed in under 2 minutes from rollback start.
[Elevated Permissions Required]

2. In the incident ticket, record the exact group removal completion timestamp immediately after clicking Apply and OK.
Expected result: Ticket contains rollback start time, completion time, and confirms group removal duration is under 2 minutes.

3. Restore the previous Share permissions from the pre-change screenshot or change record.
Expected result: Share ACL returns exactly to last known-good state.
[Elevated Permissions Required]

4. Restore the previous NTFS permissions from the pre-change screenshot or change record.
Expected result: NTFS ACL returns exactly to last known-good state.
[Elevated Permissions Required]

5. Disconnect the user's mapped drive with `net use F: /delete`.
Expected result: Problematic mapping is removed from the user session.

6. Recreate the user's mapped drive using the last known-good path and drive letter from the user profile baseline.
Expected result: Mapping behavior returns to baseline state.

7. Close the affected SMB session on the file server if stale locks remain.
Expected result: User reconnect starts with a clean SMB session.
[Elevated Permissions Required]

8. Escalate to Storage and AD teams with captured command outputs and event IDs if rollback does not restore access.
Expected result: Ownership transfers with complete diagnostics and no repeated local trial-and-error.

## 5. Notes

- Edge case: If only one Finance user is impacted, prioritize user token, cached credentials, and personal drive mapping profile.
- Edge case: If all Finance users are impacted at once, prioritize file server availability, DNS, and ACL drift checks.
- Warning: Share and NTFS permissions are cumulative; effective access is the most restrictive combination.
- Warning: Deny entries override allow entries and can break access even when allow is present.
- Warning: Group membership changes usually require user sign-out and sign-in before access token updates.
- Related incidents: known_error_record_avd_black_screen_pool_fin_01_2026-08-06.md, triage_summary_avd_black_screen_pool_fin_01.md.