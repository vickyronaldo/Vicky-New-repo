# Exercise 3 RCA - Win11 Floor 3 No Group Policy

## Incident summary
Three Windows 11 devices on Floor 3 failed to apply Group Policy at startup. Systems in OU=Finance reported no secure channel to the domain and could not access SYSVOL paths. One comparable device in the same OU processed policy successfully.

## Impact
- Affected endpoints: 3 out of 4 in the same OU segment.
- User impact: login/session startup risk, missing security and configuration baselines, and potential policy drift.
- Scope: limited to clients receiving outdated DNS from the Floor 3 DHCP scope.

## Timeline (key evidence)
- 07:40:08 `Netlogon 5719`: no domain controller available; DNS query for `FINBRIDGE-DC01.finbridge.local` failed.
- 07:40:09 and 07:40:11 `GroupPolicy 1058`: cannot access `\\FINBRIDGE-DC01\sysvol\...\gpt.ini` (`0x3`).
- 07:40:10 `GroupPolicy 1030`: cannot query GPO list (`0x546`).
- 07:40:12 and 07:44:01 `GroupPolicy 1129`: no network connectivity to domain controller.
- 07:41:05 `DNS Client 1014`: name resolution timeout; configured DNS servers not responding.
- 07:42:18 `DHCP Client 50036`: affected host leased DNS `10.10.3.250` (decommissioned).

## Comparison with unaffected device
- `DESKTOP-FB029` received DHCP DNS `10.10.0.10` (new active DNS).
- Same OU, same startup window, but `GroupPolicy 1500` indicated successful policy processing.
- Confirms endpoint OS and OU are not the primary cause.

## Root cause
DHCP scope for the Floor 3 subnet still referenced the old DNS server after migration. Affected clients were assigned decommissioned DNS (`10.10.3.250` / legacy floor DNS reference), causing DNS resolution failure for domain controllers. Without DC name resolution, secure channel and SYSVOL access failed, which blocked Group Policy processing.

## Why only some machines failed
The unaffected device was manually pre-configured to use the new DNS (`10.10.0.10`) before the migration wave, bypassing the incorrect DHCP scope option.

## Immediate workaround
- Manually set affected clients to the correct DNS server (`10.10.0.10`).
- Run `ipconfig /flushdns`, `ipconfig /renew`, and `gpupdate /force`.
- Validate with `nslookup FINBRIDGE-DC01.finbridge.local` and confirm `GroupPolicy 1500` success event.

## Permanent fix
- Update DHCP scope options for Floor 3 subnet to the new DNS server(s).
- Remove all decommissioned DNS references from DHCP and any static templates.
- Force renewals or reboot cycle for affected clients to consume corrected DHCP options.

## Validation checks
- DHCP server logs show only new DNS values for Floor 3 leases.
- Client `ipconfig /all` shows expected DNS server list.
- Domain controller FQDN resolution succeeds from affected subnet.
- Group Policy events transition from `1058/1030/1129` errors to `1500` success.

## Preventive actions
- Add a migration checklist gate: verify DHCP DNS scope updates before DNS decommission.
- Add post-change synthetic test from each subnet: DNS lookup to DC, SYSVOL access, and `gpupdate`.
- Add rollback trigger if subnet-level authentication or GPO failures exceed threshold during migration window.
