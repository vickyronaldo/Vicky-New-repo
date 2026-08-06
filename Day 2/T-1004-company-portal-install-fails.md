# T-1004

## Summary
Company app fails to install from Company Portal with error 0x87D1041C.

## Impact
Affected users and device count to-verify; may be a single-user issue or a wider app deployment issue; business urgency to-verify, but potentially high if the application is required for core job tasks.

## Known facts
- The application is being installed from Company Portal.
- The installation fails with error 0x87D1041C.
- The application is a company-managed app.

## Missing information to gather
- Which app is failing to install to-verify.
- Whether the issue affects one user, multiple users, or multiple devices to-verify.
- Whether the device is correctly enrolled in Intune and recently synced to-verify.
- Whether other Company Portal apps install successfully on the same device to-verify.
- Whether the app is available, required, or recently changed in assignment to-verify.
- Whether the device meets the app requirements and has sufficient disk space to-verify.
- Whether there are recent Company Portal, Intune, or device compliance issues to-verify.
- Exact time of the failed install and whether the failure is repeatable to-verify.

## Likely catagory
Intune / Company Portal / app deployment issue.

## First diagnostic step
Check the device record and app deployment status in Intune to confirm the app assignment, last sync, and install status for the affected device, then retry the install from Company Portal.
