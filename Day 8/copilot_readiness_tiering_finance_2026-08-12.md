# Copilot Readiness Tiering - Finance (~200 users)

Date: 2026-08-12  
Source: Day 8 Finance Copilot readiness checklist  
Context: High-sensitivity Finance data (payroll, board packs, M&A, client financial data), inherited SharePoint permissions from 2019 migration, no full audit since.

## Tier 1: MUST Complete Before Rollout (Blocking)

### Permissions and Oversharing Risk Controls (All Priority 0 Items)

- [ ] Inventory all Finance SharePoint/Teams sites and critical OneDrive locations.
- [ ] Identify and remediate legacy inherited permissions from the 2019 migration.
- [ ] Remove broad access groups and unknown nested access paths.
- [ ] Remove/expire risky org-wide or anonymous sharing links.
- [ ] Enforce least-privilege access on high-risk libraries (payroll, board packs, M&A, client data).
- [ ] Clean stale access (movers/leavers/temporary users).
- [ ] Validate access with role-based personas, including non-finance exclusion tests.
- [ ] Confirm sensitive files are not discoverable outside intended audience.
- [ ] Obtain security/governance sign-off on residual risk.

### Core Service Eligibility and Access Baseline

- [ ] Confirm eligible base licensing remains in place for target users (M365 E5).
- [ ] Procure and assign Copilot add-on licenses for the pilot cohort.
- [ ] Verify pilot users can successfully sign in and receive service provisioning.

### Identity Security Baseline

- [ ] Enforce MFA for all in-scope Finance users.
- [ ] Validate Conditional Access baseline for high-risk sign-in scenarios.

### Go/No-Go Governance Gates

- [ ] Gate 1 complete: high-risk permissions/oversharing remediation done.
- [ ] Gate 2 complete: security/governance sign-off recorded.

## Tier 2: SHOULD Complete Before Rollout (High Risk If Skipped)

### Client and Endpoint Readiness

- [ ] Confirm Microsoft 365 Apps update channel/build compliance for in-scope users.
- [ ] Validate signed-in Office app posture (Word/Excel/PowerPoint/Outlook/Teams).
- [ ] Ensure legacy authentication paths are blocked where required.
- [ ] Validate device compliance/health for pilot users.

### Data Protection Controls Maturity

- [ ] Validate sensitivity label taxonomy for Finance classifications.
- [ ] Publish/enforce required label policies.
- [ ] Validate DLP behavior for finance-sensitive patterns and common exfiltration paths.
- [ ] Test labeling and DLP outcomes with representative Finance documents.

### Operational Rollout Safety

- [ ] Define pilot success criteria and rollback/escalation process.
- [ ] Assign line-by-line ownership and target dates for all controls.

## Tier 3: CAN Complete During/After Rollout (Lower Immediate Risk)

### Enablement and Adoption Optimization

- [ ] Expand role-based prompt coaching beyond pilot once core controls are stable.
- [ ] Iterate quick-reference guides using pilot feedback.
- [ ] Scale office hours, support channel workflows, and FAQ content.

### Continuous Governance Enhancements

- [ ] Implement periodic (e.g., monthly) Finance access recertification cadence.
- [ ] Optimize exception register reporting and trend dashboards.
- [ ] Broaden post-rollout monitoring and improvement actions.

## Why Permissions/Oversharing Is MUST (Finance-Specific Rationale)

Permissions and oversharing is the top blocking criterion because it defines Copilot's effective data boundary. Copilot honors existing user access. If access is wrong, Copilot can surface the wrong data faster and more completely than traditional manual search.

In this Finance scenario, the potential impact of mis-scoped access is severe:

- Exposure of payroll data can create legal, regulatory, and employee trust consequences.
- Exposure of board packs or M&A material can trigger market sensitivity and confidentiality breaches.
- Exposure of client financial data can create contractual, reputational, and compliance risk.

The current state increases this risk materially: permissions inherited from a 2019 migration with no full audit imply unknown and potentially over-broad access paths. That is a direct data-governance uncertainty.

By contrast, licensing assignment and client version checks are critical but mostly availability/readiness checks. If missed, users may experience feature failure or degraded experience. If permissions are missed, users may experience unintended data exposure. In risk terms:

- Licensing/client gaps: primarily service enablement risk.
- Permissions/oversharing gaps: data confidentiality and regulatory risk.

Therefore, for Finance, permissions/oversharing must be treated as a hard go/no-go blocker before broad rollout, while licensing/client readiness—though still important—does not carry the same immediate confidentiality impact.
