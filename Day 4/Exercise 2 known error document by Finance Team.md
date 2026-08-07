Symptom: Finance users cannot access shared drives at login/startup, and mapped drive letter S: is missing on DESKTOP-FB* devices.

Cause: Drive mapping workflow was migrated from GPO logon script (USER context) to Intune PowerShell script (SYSTEM context) without context-aware redesign. SYSTEM context could not access `\\finbridge-fs01\Finance` at execution time, so mapping failed.

Scope: OU=Finance endpoints, with broad team impact (45 users) in the observed incident.

How to spot it:
- Intune Management Extension / ScriptRunner logs:
  - Executing `Map-FinBridgeDrives.ps1`
  - Script context: SYSTEM account
  - Warning path not accessible: `\\finbridge-fs01\Finance`
  - Error: exit code 1, "Network name cannot be found"
  - No retry configured
- System log indicators:
  - Service Control Manager Event 7036 (Workstation running)
  - GroupPolicy Event 1500 success (rules out GP failure)
  - Ntfs Event 98 warning (S: not assigned)

Workaround:
- Trigger mapping in active user context for impacted user session.
- Confirm network access to `\\finbridge-fs01\Finance` from user context.
- Re-run mapping workflow after user session is established.

Permanent fix:
- Use user-session-compatible mapping deployment pattern for credentialed UNC shares.
- Add retry and post-mapping validation checks.
- Add migration gate requiring context-impact testing before moving USER scripts to SYSTEM execution.
