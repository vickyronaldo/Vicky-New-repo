# L2/L3 Knowledge Base: Diagnose Finance Shared Drive Access Failure From Scratch

## Version Header
- Version: v 1.0
- Date: 07/08/2026
- Status: Draft
- Source: runbook_finance_shared_drives_pool_fin_01_2026-08-07.md

## Purpose
Use this KB when a DWP engineer needs to diagnose Finance shared drive access issues with no prior incident context.

## Scope
- In scope: Finance users cannot open the Finance network folder or mapped drive.
- Out of scope: non-Finance folders, OneDrive/SharePoint sync issues, endpoint disk failures.

## Systems Used
- User workstation (Command Prompt, PowerShell, File Explorer)
- Active Directory Users and Computers (ADUC)
- File server hosting Finance share
- Event Viewer on file server
- ITSM ticketing portal
- CMDB (expected file server DNS/IP and ACL baseline)

## Required Access
- [Elevated Permissions Required] AD read/write access for user group membership.
- [Elevated Permissions Required] File server admin or delegated rights for share and NTFS ACL review.
- [Elevated Permissions Required] Permission to close SMB sessions on file server.

## Intake Checklist (Do Before Commands)
1. Capture user ID, device name, and location (office or remote).
2. Capture exact share path and mapped drive letter.
3. Capture exact error text and screenshot.
4. Capture impact scope: one user, several Finance users, or all Finance users.
5. Capture incident start time.

## Diagnostic Workflow

### Phase 1: Confirm and classify failure
1. Ask affected user to open the UNC path in File Explorer (`\\FS01\\Finance` or approved production path).
Expected result: You capture one of three outcomes: success, access denied, or path not found.

2. Ask same user to open mapped drive letter in File Explorer.
Expected result: You confirm whether issue is UNC-only, mapped-drive-only, or both.

3. On user device, run `nslookup <fileserver-fqdn>`.
Expected result: Name and IP match CMDB expected values.

4. On user device, run `Test-NetConnection <fileserver-fqdn> -Port 445`.
Expected result: `TcpTestSucceeded : True`.

Decision point:
- If DNS or port test fails, classify as connectivity path issue and escalate to network/server team with command output.
- If DNS and port pass, continue to Phase 2.

### Phase 2: Validate identity and token
5. On user device, run `whoami /groups`.
Expected result: Required Finance access group is present in user token.

6. On user device, run `klist`.
Expected result: Valid `krbtgt` ticket exists and is not expired.

7. In ADUC path `domain > user OU > <user> > Properties > Member Of`, verify required Finance access group.
Expected result: Group membership in AD matches access baseline.
[Elevated Permissions Required]

Decision point:
- If group is missing, go to Remediation Step 1.
- If group is present, continue to Phase 3.

### Phase 3: Validate file server permissions
8. On file server, open folder `Finance` > `Properties > Sharing > Advanced Sharing > Permissions`.
Expected result: Required Finance group exists with approved share-level rights.
[Elevated Permissions Required]

9. On same folder, open `Properties > Security > Advanced`.
Expected result: Required Finance group exists with approved NTFS rights.
[Elevated Permissions Required]

Decision point:
- If either ACL deviates from baseline, go to Remediation Step 2.
- If ACLs match baseline, continue to Phase 4.

### Phase 4: Validate live SMB behavior
10. On file server Event Viewer path `Windows Logs > Security` and `Applications and Services Logs > Microsoft > Windows > SMBServer > Operational`, filter incident window for Access Denied.
Expected result: Either no new denied events or denied events tied to known cause.
[Elevated Permissions Required]

11. On file server PowerShell (Admin), run:
`Get-SmbSession | Where-Object { $_.ClientUserName -like "*<username>*" }`
Expected result: Active SMB session for user is displayed with SessionId.
[Elevated Permissions Required]

12. If stale session exists, run:
`Close-SmbSession -SessionId <id>`
Expected result: Session closes and user can reconnect cleanly.
[Elevated Permissions Required]

## Remediation

### Step 1: Identity fix (group missing)
1. Add missing Finance group in ADUC Member Of.
Expected result: Group is present in AD user object.
[Elevated Permissions Required]

2. On user device, run `gpupdate /force`.
Expected result: User policy update completes successfully.

3. User signs out and signs in again.
Expected result: New token includes updated group.

4. Clear old mappings: `net use * /delete /y`.
Expected result: Previous network mappings removed.

5. Remap drive: `net use F: \\FS01\\Finance /persistent:yes` (replace with approved values).
Expected result: `The command completed successfully`.

### Step 2: ACL fix (share/NTFS mismatch)
1. Correct Share permissions to baseline.
Expected result: Share ACL matches approved baseline exactly.
[Elevated Permissions Required]

2. Correct NTFS permissions to baseline.
Expected result: NTFS ACL matches approved baseline exactly.
[Elevated Permissions Required]

3. Close affected SMB session.
Expected result: User reconnect starts with clean server session state.
[Elevated Permissions Required]

4. Ask user to reconnect and retest UNC path.
Expected result: Folder opens without error.

## Verification Before Closure
1. Test with 3 affected Finance users on UNC path.
Pass criteria: All 3 open Finance folder in under 10 seconds.

2. Test with same 3 users on mapped drive.
Pass criteria: All 3 can browse and perform expected read/write behavior.

3. Monitor file server logs for 30 minutes.
Pass criteria: No new Access Denied events for validated users and path.

4. Check ITSM queue after 60 minutes.
Pass criteria: No new Finance shared-drive incidents with same error signature.

## Rollback (If Change Worsens Access)
Rollback timing rule:
- Group removal must complete in under 2 minutes from rollback start.

1. Start timer and record rollback start timestamp in ticket.
Expected result: Start time is documented.

2. In ADUC Member Of, remove only the group added during this incident.
Expected result: Group removed and completion time is under 2 minutes.
[Elevated Permissions Required]

3. Record rollback completion timestamp in ticket.
Expected result: Ticket shows measured duration under 2 minutes.

4. Restore previous Share ACL from pre-change record.
Expected result: Share ACL returns to known-good state.
[Elevated Permissions Required]

5. Restore previous NTFS ACL from pre-change record.
Expected result: NTFS ACL returns to known-good state.
[Elevated Permissions Required]

6. Remove user mapping: `net use F: /delete`.
Expected result: Problem mapping removed.

7. Recreate last known-good mapping from baseline.
Expected result: Mapping state restored.

8. Escalate to AD and Storage owners with logs, command output, and timestamps.
Expected result: Escalation accepted with complete evidence.

## Evidence to Attach to Ticket
- User error screenshot
- Output of `nslookup`, `Test-NetConnection`, `whoami /groups`, `klist`
- AD group membership before/after screenshot
- Share and NTFS ACL before/after screenshot
- SMB session output and closed SessionId
- Rollback timer evidence if rollback executed
