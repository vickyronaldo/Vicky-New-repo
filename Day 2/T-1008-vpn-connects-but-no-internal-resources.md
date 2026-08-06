# T-1008

## Summary
VPN connects, but internal resources are unreachable after a Win11 upgrade.

## Impact
Single user reported so far to-verify; possible wider impact if the issue is linked to the Win11 upgrade or VPN profile; business urgency is to-verify, but potentially high because remote access to internal systems appears blocked.

## Known facts
- The VPN connection itself succeeds.
- Internal resources cannot be reached.
- The issue started after a Win11 upgrade.

## Missing information to gather
- Whether the issue affects one user, one device, or multiple upgraded devices to-verify.
- Whether all internal resources fail or only specific services to-verify.
- Whether the failure affects DNS names, IP addresses, or both to-verify.
- Whether the issue occurs on different home or public networks to-verify.
- Whether other users on the same VPN profile can access the same internal resources to-verify.
- Whether the VPN client, network adapter, or security software changed during or after the Win11 upgrade to-verify.
- Whether the user can reach internal resources by hostname, by IP, or neither to-verify.

## Likely catagory
VPN / network routing / DNS issue.

## First diagnostic step
Check whether the affected device can resolve and reach a known internal resource by both hostname and IP address while connected to VPN, to determine whether the issue is routing related, DNS related, or both.
