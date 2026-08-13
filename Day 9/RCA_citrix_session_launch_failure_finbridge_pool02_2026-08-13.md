# RCA - Citrix Session Launch Failure (FinBridge-VDI-Pool-02)

## Document Control
- Date: 2026-08-13
- Incident type: VDI session launch failure
- Scope: FinBridge-VDI-Pool-02 only
- Affected users: 22 of 30
- Unaffected comparator: FinBridge-VDI-Pool-01

## Executive Summary
A major partial outage impacted session launches for users assigned to `FinBridge-VDI-Pool-02`. Broker logs show launch failures after registration timeout, ending with `error 1030` and `No machines available in the desktop group`. Supporting controller and catalog telemetry indicates widespread VDA unregistration in Pool-02 and a stopped `Citrix Broker Service` on `dc-vdi-02`. Pool-01 remained healthy via `dc-vdi-01`.

## Final Root Cause Statement
The immediate technical cause of launch failure was loss of broker availability on `dc-vdi-02` (`Citrix Broker Service` stopped), which prevented most Pool-02 VDAs from registering and left insufficient registered capacity for brokered session launch.

## Supporting Evidence
1. Citrix Session Broker log:
   - `Affected : 22 of 30 users on FinBridge-VDI-Pool-02`
   - `Timeout waiting for machine registration response (30000ms exceeded)`
   - `Session launch FAILED: error 1030 'No machines available in the desktop group'`
2. Catalog registration status:
   - Pool-02: 25 provisioned, 3 registered, 22 unregistered, maintenance mode 0
   - Pool-01: 20 provisioned, 19 registered, 1 unregistered
3. Unregistered machine samples (Pool-02):
   - `Unable to contact Delivery Controller`
   - `dc-vdi-02.finbridge.local:80 - connection refused`
4. Controller health:
   - `dc-vdi-02`: `Citrix Broker Service STOPPED`
   - `dc-vdi-01`: `Citrix Broker Service RUNNING`, uptime 14 days
5. Change-state context:
   - On `dc-vdi-02`, Windows Update installed at 00:15; reboot-required flag set; host not rebooted.

## Timeline (from provided data)
- 00:15: Windows Update installed on `dc-vdi-02`; reboot required flag set; host not rebooted.
- 06:15:22: `VDI-P02-014` last registration attempt failed (unable to contact controller; connection refused to dc-vdi-02:80).
- 06:16:01: `VDI-P02-017` last registration attempt failed (same pattern).
- 08:58:03: User `jsmith` session launch requested on Pool-02.
- 08:58:04: Broker queried available machines in Pool-02.
- 08:58:34: Broker timed out waiting for machine registration (30000ms exceeded).
- 08:58:34: Session launch failed with `error 1030`, `No machines available in the desktop group`.
- At investigation time: `Citrix Broker Service` on `dc-vdi-02` observed as stopped; last known running at 23:40 previous day.

## 5 Whys Analysis
1. Why did users fail to launch sessions in Pool-02?
   - Because broker could not allocate a machine and returned `No machines available in the desktop group`.
2. Why were no machines available to allocate?
   - Because only 3 of 25 Pool-02 machines were registered; 22 were unregistered.
3. Why were 22 Pool-02 machines unregistered?
   - Because many VDAs could not contact their Delivery Controller endpoint (`dc-vdi-02:80`, connection refused).
4. Why was the controller endpoint refusing connection?
   - Because `Citrix Broker Service` was stopped on `dc-vdi-02`.
5. Why was broker service stopped and not recovered quickly?
   - Controller had post-update reboot pending and lacked sufficient guardrail controls (mandatory reboot SLA, proactive stopped-service alerting, and synthetic launch/registration probes) to prevent prolonged degraded state.

## Remediation Executed / Required (Operational Runbook)
1. Initiate controlled recovery window and notify impacted stakeholders.
2. Reboot `dc-vdi-02` (pending reboot condition).
3. Verify `Citrix Broker Service` post-boot state is `Running` and startup type `Automatic`.
4. If needed, manually start broker service and resolve startup errors from logs.
5. Trigger/refresh VDA registration for Pool-02 machines where stale.
6. Monitor catalog until registration recovers and launch attempts succeed.
7. Validate user session launch restoration across impacted cohort sample.

## Verification of Resolution
A resolution is confirmed only when all of the following are true:
1. `dc-vdi-02` broker service remains continuously `Running`.
2. Pool-02 registration materially recovers from 3/25 toward normal operating level.
3. No new `Timeout waiting for machine registration (30000ms exceeded)` for Pool-02 launch attempts.
4. No new `connection refused` observations to `dc-vdi-02:80` from Pool-02 VDAs.
5. User validation confirms successful session launch for representative affected users.

## Preventive Actions
1. Patch governance:
   - Enforce Delivery Controller post-patch reboot SLA in approved maintenance windows.
2. Service observability:
   - Configure immediate critical alert for `Citrix Broker Service` stopped state on any controller.
3. Synthetic health checks:
   - Add scheduled pool-level synthetic registration and launch tests with threshold-based alerting.
4. Resilience/failover posture:
   - Validate VDA controller lists and failover behavior at least monthly.
5. Operational readiness:
   - Maintain and drill a controller recovery runbook quarterly.

## Residual Risk
If preventive controls are not implemented, similar partial outages can recur after patching, service interruptions, or controller-specific failures.

## Appendix: Extracted Scope Facts
- Affected: 22/30 users on FinBridge-VDI-Pool-02.
- Unaffected: FinBridge-VDI-Pool-01.
- Broker failure: `error 1030`, `No machines available in the desktop group`.
- Pool-02 catalog: 25 provisioned, 3 registered, 22 unregistered.
- Pool-01 catalog: 20 provisioned, 19 registered, 1 unregistered.
- dc-vdi-02: Broker Service stopped.
- dc-vdi-01: Broker Service running.
