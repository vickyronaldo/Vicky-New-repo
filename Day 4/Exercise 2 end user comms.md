# Exercise 2 End User Comms - Finance Shared Drive Access Issue

## Audience 1 - Non-technical executive
Finance shared drive access has been restored. Earlier today, users were unable to access the shared drive because a startup mapping task was running under a system context that could not reliably use user network access at login time. This was a script deployment behavior issue, not a security breach and not a Group Policy failure. We corrected the deployment approach and validated that users can access shared drives again.

## Audience 2 - Affected end-user team (Finance)
Your shared drive access is now restored. The issue was caused by how the startup mapping script ran during sign-in, which prevented S: from being mapped for some sessions. We have corrected this and verified access. If you still cannot open the Finance shared drive, restart once and contact the Service Desk with your device name (DESKTOP-FBxxx).

## Audience 3 - Engineer-to-engineer internal note
Incident affected 45 Finance users on DESKTOP-FB* endpoints in OU=Finance. Intune Management Extension log confirms `Map-FinBridgeDrives.ps1` ran under SYSTEM and failed UNC access to `\\finbridge-fs01\Finance` (exit code 1, no retry). System log on DESKTOP-FB041 shows Workstation service start, GP success (Event 1500), and NTFS mapping warning for S:, confirming this is not a GP processing issue.

Action taken: moved mapping workflow to user-session-compatible execution, updated deployment targeting, added mapping validation and retry strategy. Recovery verified by successful drive mapping and user confirmation.
