# T-1007

## Summary
OneDrive is stuck “processing changes” since migration and files are missing locally.

## Impact
Single user reported so far to-verify; possible wider impact if the migration affected more than one profile or device; business urgency is to-verify, but potentially high where users cannot access required files locally.

## Known facts
- The issue started after a migration.
- OneDrive is stuck on “processing changes”.
- Some files are missing locally.

## Missing information to gather
- Which migration took place to-verify.
- Whether the issue affects one device, one user profile, or multiple users/devices to-verify.
- Whether the missing files are still present in OneDrive on the web to-verify.
- Whether the issue affects personal OneDrive folders, known folders, or shared libraries to-verify.
- Whether OneDrive shows any sync errors, warnings, or paused status to-verify.
- Whether the user recently changed account sign-in, folder locations, or Files On-Demand settings to-verify.
- Whether the device has enough disk space and stable network connectivity to complete sync to-verify.

## Likely catagory
OneDrive sync / migration issue.

## First diagnostic step
Compare the user’s local OneDrive folder with OneDrive on the web and check the current OneDrive sync status to confirm whether the files are present in the cloud and the issue is local sync related.
