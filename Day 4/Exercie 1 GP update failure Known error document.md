Symptom: On affected Floor 3 Windows 11 devices, Group Policy does not process at startup because the device cannot reach a domain controller. Users experience inconsistent domain startup behavior until remediation.

Cause: The Floor 3 DHCP scope retained a decommissioned DNS server after overnight migration. This stale DNS assignment prevented domain controller name resolution and caused Group Policy processing failures.

Scope: Affected systems were Floor 3 Finance subnet clients receiving deprecated DNS from DHCP, with 3 of 4 observed endpoints impacted in the incident evidence set. A peer endpoint in the same OU with correct DNS assignment was unaffected.

Workaround: Temporarily set affected clients to the correct DNS path, then refresh client network and policy state by renewing DHCP/DNS and forcing Group Policy update. This restores domain controller resolution and policy application while the DHCP scope fix is being applied.

Permanent fix: Update DHCP scope Option 006 on Floor 3 to the correct DNS server values and remove old DNS references. Propagate the corrected configuration to clients and validate successful Group Policy processing.

How to spot it: Look for startup sequences containing Netlogon Event 5719, DNS Client Event 1014, GroupPolicy Events 1058/1030/1129, and DHCP Client Event 50036 showing legacy DNS assignment (for example 10.10.3.250). Confirm the pattern by comparison with a healthy device showing DHCP Event 50036 with 10.10.0.10 and GroupPolicy Event 1500 success.
