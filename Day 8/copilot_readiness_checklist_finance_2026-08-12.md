# Microsoft 365 Copilot Readiness Checklist - Finance (Day 8)

Date: 2026-08-12  
Department: Finance (~200 users)  
Data Sensitivity: High (payroll, board packs, M&A, client financial data)  
Licensing Baseline: Microsoft 365 E5 confirmed; Copilot add-on not yet assigned

## Priority 0 (Blocker): Permissions and Oversharing Risk Controls

> This section is the highest priority and must be completed before broad Copilot enablement.

### SharePoint and OneDrive Access Review

- [ ] Inventory all Finance SharePoint sites, Teams-connected sites, and critical OneDrive locations used for payroll, board packs, M&A, and client financial data.
- [ ] Identify sites/libraries with legacy inherited permissions from the 2019 migration.
- [ ] Identify broad access groups (for example: Everyone except external users, large legacy AD synced groups, nested groups with unclear ownership).
- [ ] Flag anonymous/anyone links and broad org-wide sharing links that expose Finance content.
- [ ] Validate access for high-risk libraries is least privilege (need-to-know only).

### Oversharing Remediation

- [ ] Remove or replace overshared groups with role-based least-privilege groups.
- [ ] Break inheritance where required for sensitive libraries/folders that should not follow parent access.
- [ ] Remove stale users from Finance-sensitive locations (movers/leavers/temporary project users).
- [ ] Clean up and expire risky sharing links.
- [ ] Confirm site ownership is assigned and active for every Finance site.
- [ ] Document all exceptions with approved risk owner and target remediation date.

### Validation Before Copilot Assignment

- [ ] Run targeted access tests using sample user personas (payroll analyst, finance manager, exec support, non-finance user).
- [ ] Confirm non-finance personas cannot discover or access Finance-restricted content.
- [ ] Confirm sensitive documents do not appear in inappropriate search scopes.
- [ ] Obtain security/governance sign-off that oversharing risk is at an acceptable level.

## Priority 1: Licensing and Service Prerequisites

- [ ] Confirm 200/200 Finance users have eligible base licensing (M365 E5).
- [ ] Procure/allocate 200 Copilot for Microsoft 365 add-on licenses.
- [ ] Define pilot cohort (for example 20-30 users across Finance functions) before full assignment.
- [ ] Assign Copilot add-on licenses to pilot cohort first.
- [ ] Validate Copilot service plan provisioning and sign-in success for pilot users.

## Priority 2: Microsoft 365 Apps and Endpoint Readiness

- [ ] Confirm Microsoft 365 Apps are on supported update channel and minimum build required for Copilot features.
- [ ] Verify signed-in Office desktop apps (Word, Excel, PowerPoint, Outlook, Teams) for pilot users.
- [ ] Ensure modern authentication is enabled and legacy auth paths are blocked where applicable.
- [ ] Validate Teams desktop/web client currency for Copilot experiences in Teams.
- [ ] Check device compliance posture for pilot users (managed, patched, healthy).

## Priority 3: Identity and MFA Readiness

- [ ] Confirm MFA is enforced for all Finance users.
- [ ] Review Conditional Access for Finance personas and high-risk sign-in conditions.
- [ ] Ensure break-glass/admin accounts are excluded from user assignment scope and monitored separately.
- [ ] Confirm guest/external account controls align with Finance data handling policy.
- [ ] Validate account lifecycle hygiene (joiner/mover/leaver process) to prevent stale access.

## Priority 4: Data Protection and Sensitivity Labelling

- [ ] Define/validate sensitivity labels for Finance data classes (Public/Internal/Confidential/Highly Confidential Finance).
- [ ] Publish label policies to Finance users and required locations.
- [ ] Apply default labels or mandatory labeling where policy requires.
- [ ] Configure encryption and usage restrictions for highly sensitive classes (board packs, M&A, payroll).
- [ ] Validate DLP policies for key finance data patterns and exfiltration paths.
- [ ] Test label and DLP behavior with representative finance files before broad rollout.

## Priority 5: End-User Communications and Enablement

- [ ] Publish a Finance-specific Copilot launch communication (scope, timelines, support path, acceptable use).
- [ ] Explain clearly that Copilot respects existing user permissions; oversharing remediation is underway/complete.
- [ ] Deliver short role-based training for pilot users (prompting, data handling, validation of AI outputs).
- [ ] Provide a "do/don't" quick guide for sensitive finance scenarios.
- [ ] Establish feedback loop (service desk tag, Teams channel, office hours) for first 30 days.

## Go/No-Go Decision Gates

- [ ] Gate 1: Oversharing and permissions remediation complete for all high-risk locations.
- [ ] Gate 2: Security/governance sign-off recorded.
- [ ] Gate 3: Pilot success criteria met (adoption, no major data exposure incidents, acceptable support volume).
- [ ] Gate 4: Executive approval for phased expansion from pilot to all Finance users.

## Suggested Rollout Sequence

- [ ] Phase A: 20-30 user pilot (2-3 weeks) with weekly risk review.
- [ ] Phase B: Expand to 75-100 users after successful pilot and control validation.
- [ ] Phase C: Full 200-user enablement with continued monitoring and monthly access recertification.

## Ownership and Tracking

- [ ] Assign owner for each checklist line (IT, Security, Compliance, Finance Ops).
- [ ] Set target completion dates and status (Not Started/In Progress/Done).
- [ ] Review progress twice weekly until all Gate criteria are complete.
