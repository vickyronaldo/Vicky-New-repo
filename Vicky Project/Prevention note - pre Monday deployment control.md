# Prevention Note: Pre-Monday Control

## Specific process change
Implement a mandatory **Monday Readiness Gate (MRG)** for all Friday afternoon endpoint rollouts to business-critical user groups.

## What this control is (concrete)
The Monday Readiness Gate is a formal release checkpoint that must be passed before Friday deployment can remain active into Monday business hours.

Required gate checks (single control package):
1. Pilot cohort check: 10 to 15 users from the exact target group complete next-business-day sign-in validation.
2. Login health threshold: no material increase in login failures/slowness versus baseline (threshold pre-defined in change ticket).
3. App health threshold: install success and detection status meet agreed minimum pass rate.
4. Service desk signal check: no high-severity spike tied to the rollout cohort.

If any gate check fails, the rollout is automatically paused for the target group before Monday 08:00.

## Why this would have caught this incident
This incident pattern (Friday rollout, Monday sign-in disruption in the same cohort) would have been detected during the gate validation window, and the automatic pause would have prevented broad Monday morning impact.

## Ownership and evidence
- Owner: Endpoint Change Manager + Service Desk Duty Lead
- Evidence required in change record: pilot results, threshold outcomes, go/no-go decision, and timestamped approver sign-off
