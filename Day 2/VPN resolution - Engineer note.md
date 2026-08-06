Engineer note:

Root cause: Win11 upgrade removed the legacy VPN client and Intune did not re-deploy the new client due to a detection-rule gap. No data loss.

Exact action taken: Manually removed stale VPN registry entries under `HKLM\SOFTWARE\<vendor>`, force-triggered Intune sync, new client deployed, split-tunnel config applied.

Config detail: Stale VPN registry entries were present under `HKLM\SOFTWARE\<vendor>`. Split-tunnel config applied on the newly deployed client.

Verification step: Connectivity confirmed to all internal subnets.

Preventive action needed: Fix the detection rule so the Win11 upgrade triggers Intune re-deployment of the new VPN client.
