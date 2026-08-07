# Exerice 1 End User Comms - GP Update Failure

## Audience 1 - Non-technical executive
Your access and data are safe. This morning, some Floor 3 Windows 11 devices did not receive sign-in settings because an old network address was still in use after an overnight change. We corrected the network setting, refreshed affected devices, and restored service at 10:00. We confirmed settings are now updating and no further issues are reported. No action is needed unless you see this again; if so, restart once and contact the Service Desk.

## Audience 2 - Affected end-user team (10 people, non-technical)
Your access and data are safe. This morning, some Floor 3 Windows 11 devices did not receive sign-in settings because an old network address was still in use after an overnight change. We corrected the network setting, refreshed affected devices, and restored service at 10:00. We confirmed settings are now updating and no further issues are reported. If you see this again, restart your device once; if it continues, contact the Service Desk.

## Audience 3 - Engineer-to-engineer internal note
Access and data remained safe. Incident window began during morning startup after overnight DNS migration activity. Root cause: Floor 3 DHCP scope Option 006 still pointed affected clients to a decommissioned DNS endpoint (old: 10.10.3.250 / legacy floor reference), while correct DNS should be 10.10.0.10. This caused DC resolution failure and downstream GP failures (5719, 1014, 1058, 1030, 1129) on affected hosts; control host with correct DNS showed GP success (1500).

Exact action taken: updated Floor 3 DHCP scope DNS configuration to current values, removed old DNS references, renewed DHCP/DNS state on impacted endpoints, flushed resolver cache, and forced GP refresh.

Verification: service restored at 10:00; affected users confirmed healthy; endpoint GP policies confirmed updated; no ongoing issues reported.

Preventive action required: enforce DNS-decommission dependency gate on DHCP scope validation, add subnet synthetic checks (DC DNS lookup + SYSVOL/GP validation), and implement DHCP Option 006 drift monitoring and cross-team change signoff.
