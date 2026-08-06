# T-1001

## Summary
New Win11 laptop is prompting for the BitLocker recovery key on every boot.

## Impact
Single user / single device to-verify; high urgency because the laptop is not reaching a normal usable state and the user is blocked at startup.

## Known facts
- Device is a new Win11 laptop.
- BitLocker recovery key prompt appears every boot.
- Recovery key is being requested before the user can continue.

## Missing information to gather
- Whether this happens on every restart or only after shutdown/sleep to-verify.
- Whether the device is company-managed and where the recovery key is stored to-verify.
- Whether there were recent BIOS/UEFI, TPM, Secure Boot, firmware, or boot-order changes to-verify.
- Whether the device was reimaged, reset, or joined to the domain/Entra before the issue started to-verify.
- Whether the user can successfully retrieve the recovery key to proceed.

## Likely category
BitLocker / device encryption / boot integrity issue.

## First diagnostic step
Confirm the recovery key source and check whether TPM, Secure Boot, and BIOS/UEFI settings match the expected baseline before making any changes.
