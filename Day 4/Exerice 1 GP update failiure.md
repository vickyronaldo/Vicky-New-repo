# Root Cause Analysis (RCA): Group Policy Update Failure - Floor 3 Win11 Clients

## Incident Summary
- Incident: Group Policy processing failures on multiple Windows 11 clients after morning startup.
- Affected segment: Floor 3 Finance endpoints (3 of 4 observed in scope).
- Unaffected comparison: One peer endpoint in same OU processed Group Policy successfully.
- First observed window: 07:40 startup cycle.
- Confirmed change correlation: Legacy DNS decommissioned overnight, but DHCP scope for Floor 3 still handed out old DNS.
- Resolution applied: DHCP DNS scope corrected and affected clients refreshed.
- Service restoration confirmed: 10:00.

## Business Impact
- Group Policy did not apply on affected clients.
- Domain-dependent startup controls and policy baselines were delayed or missed.
- Users experienced inconsistent domain startup behavior until remediation.

## Scope and Impacted Assets
- Scope: Floor 3 subnet clients receiving deprecated DNS from DHCP.
- Impacted hosts (evidence set): DESKTOP-FB055, DESKTOP-FB056, DESKTOP-FB057 (affected pattern).
- Unaffected host (control): DESKTOP-FB058 / DESKTOP-FB029 pattern (correct DNS path).
- Population impact in collected evidence: 3 of 4 in same OU/subnet pattern.

## Supporting Evidence

### Affected host evidence (example: DESKTOP-FB031)
- 07:40:08 - Netlogon Event 5719 (Error): no domain controller available; DNS query for FINBRIDGE-DC01.finbridge.local returned no response.
- 07:40:09 - GroupPolicy Event 1058 (Error): cannot access SYSVOL gpt.ini path; error 0x3.
- 07:40:10 - GroupPolicy Event 1030 (Warning): cannot query list of GPO objects; error 0x546.
- 07:40:11 - GroupPolicy Event 1058 (Error): repeated SYSVOL access failure.
- 07:40:12 - GroupPolicy Event 1129 (Error): no network connectivity to domain controller for policy processing.
- 07:41:05 - DNS Client Event 1014 (Warning): name resolution timeout; configured DNS servers not responding.
- 07:42:18 - DHCP Client Event 50036 (Information): lease received with DNS server 10.10.3.250 (old/decommissioned).
- 07:44:01 - GroupPolicy Event 1129 (Error): repeated no-DC-connectivity policy failure.

### Unaffected comparison host evidence (DESKTOP-FB029)
- 07:40:05 - DHCP Client Event 50036: DNS assigned 10.10.0.10 (correct new DNS).
- 07:40:11 - GroupPolicy Event 1500 (Information): Group Policy processed successfully.

### DHCP server comparison evidence
- FB055-057 received legacy/decommissioned DNS from Floor 3 scope.
- FB058 received 10.10.0.10 (manually set/correct path) and remained unaffected.
- Evidence conclusion: DHCP scope option mismatch directly aligns with affected/unaffected split.

## Evidence-Based Causal Chain
1. DHCP assigned old DNS to affected clients (Event 50036 at 07:42:18).
2. Clients could not resolve domain controller FQDN (Event 1014 and Event 5719).
3. Without DC resolution, SYSVOL path was unreachable (Event 1058).
4. GPO list and policy processing failed (Event 1030 and Event 1129).
5. Peer device with correct DNS processed GP successfully (Event 1500), confirming dependency on DNS correctness.

## Detailed Timeline
1. 02:00 - Legacy DNS service decommissioned in migration wave.
2. Overnight to morning - Floor 3 DHCP scope remains configured with old DNS option.
3. 07:40:02 - NLA service running (Event 7036), startup proceeds.
4. 07:40:08 - Netlogon fails to establish secure channel due to DC resolution failure (Event 5719).
5. 07:40:09 to 07:40:12 - GroupPolicy errors 1058/1030/1129 recorded.
6. 07:41:05 - DNS timeout confirms resolver path failure (Event 1014).
7. 07:42:18 - DHCP lease confirms wrong DNS assignment (Event 50036).
8. 07:44:01 - Repeat GroupPolicy 1129 confirms persistent state.
9. Triage/remediation window - DHCP scope DNS corrected to new server values; clients renewed DNS/DHCP and policy refresh executed.
10. 10:00 - Incident resolved; affected users confirmed healthy, Group Policy updated, and no ongoing issues reported.

## Root Cause
Primary root cause was stale DHCP scope configuration on the Floor 3 subnet, which continued to assign a decommissioned DNS server after overnight migration. This prevented affected clients from resolving domain controllers and caused Group Policy processing failures.

## Contributing Factors
- Change dependency gap between DNS decommission and DHCP option validation.
- Lack of pre-business-hour synthetic validation from each subnet for DC resolution and GPO fetch.
- Partial manual pre-configuration on one endpoint masked breadth of DHCP misconfiguration.

## 5 Whys Analysis

### Problem statement
Why did three Floor 3 Win11 endpoints fail Group Policy processing at startup?

1. Why did Group Policy fail?
Because clients could not contact a domain controller during policy processing.

2. Why could clients not contact a domain controller?
Because DNS resolution for FINBRIDGE-DC01.finbridge.local timed out/failed.

3. Why did DNS resolution fail on those clients?
Because DHCP assigned an old, decommissioned DNS server to the affected subnet clients.

4. Why was DHCP assigning decommissioned DNS?
Because the Floor 3 DHCP scope Option 006 was not updated during the DNS migration change.

5. Why was the scope update missed?
Because migration governance did not enforce a hard dependency gate requiring DHCP scope verification before DNS decommission completion.

## Resolution Actions Taken
1. Corrected Floor 3 DHCP scope Option 006 to the new DNS server (10.10.0.10 and approved secondary as applicable).
2. Removed old DNS references from scope and related templates.
3. Renewed DHCP leases and DNS settings on affected clients.
4. Flushed resolver cache and forced Group Policy refresh on affected devices.
5. Validated DC name resolution and successful Group Policy processing events.

## Verification of Recovery
- Recovery confirmation time: 10:00.
- User validation: affected users reported normal operation; no further issues reported.
- Technical validation:
  - Client DNS now reflects current DNS server values.
  - DC FQDN lookups succeed from impacted subnet.
  - Group Policy processing succeeds (Event 1500 pattern) with no recurrence of 5719/1014/1058/1030/1129 in post-fix checks.

## Corrective and Preventive Actions (CAPA)

### Corrective actions completed
- DHCP scope corrected and propagated.
- Affected endpoints refreshed and validated.
- Service stability confirmed by 10:00.

### Preventive actions
1. Add migration gate: DHCP DNS scope validation must be complete before DNS server decommission signoff.
2. Implement subnet-based synthetic checks post-change:
   - DC DNS lookup.
   - SYSVOL path accessibility.
   - Group Policy refresh and success-event validation.
3. Add automated compliance audit for DHCP Option 006 against approved DNS inventory.
4. Require change checklist dual-approval across Network and EUC teams for DNS/DHCP coupled changes.
5. Establish alert for startup bursts of Event 5719 plus GroupPolicy 1058/1129 across same subnet.
6. Maintain rollback plan to reintroduce temporary valid DNS path if policy/auth failures exceed threshold.

## Residual Risk and Follow-up
- Residual risk: Low after fix, with medium risk of recurrence if change governance remains manual.
- Follow-up actions:
  - Review next business-day startup telemetry for Floor 3.
  - Confirm no drift in DHCP DNS options across all subnets.
  - Close incident record with attached event evidence and verification timestamps.

## Final Status
- Incident state: Resolved.
- Resolved at: 10:00.
- Current service state: Group Policy updates confirmed on user devices; no active issues reported.
