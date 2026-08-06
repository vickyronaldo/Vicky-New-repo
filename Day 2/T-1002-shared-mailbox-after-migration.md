# T-1002

## Summary
Finance user cannot open a shared mailbox after migration.

## Impact
Single Finance user reported so far to-verify; possible wider impact if other delegated users lost access after migration; business urgency to-verify, but potentially high if the shared mailbox supports time-critical finance processing.

## Known facts
- The affected user is in Finance.
- The issue is with opening a shared mailbox.
- The problem started after a migration.

## Missing information to gather
- Shared mailbox name/address to-verify.
- Exact error message or symptom to-verify.
- Type of migration completed to-verify.
- Whether the issue occurs in Outlook desktop, Outlook on the web, or both to-verify.
- Whether other authorised users can open the same shared mailbox to-verify.
- Whether the affected user can access their own primary mailbox normally to-verify.
- Whether shared mailbox permissions were checked or re-applied after migration to-verify.
- Device details, Outlook version, and whether the user is on VPN/on-site/off-site to-verify.

## Likely category
Exchange Online / Outlook / shared mailbox access or permissions issue to-verify.

## First diagnostic step
Check whether another authorised user can open the same shared mailbox in Outlook on the web, and capture the exact error text to confirm whether this is a user-specific access issue or a mailbox-wide post-migration issue.
