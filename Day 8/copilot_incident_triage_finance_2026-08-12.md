# Copilot Incident Triage - Finance Tickets (Day 8)

Date: 2026-08-12  
Team: DWP Engineering  
Triage Rule: Default to non-Copilot causes unless evidence strongly indicates product fault.

Allowed cause categories used below:
1. permissions/access boundary
2. data indexing lag
3. sensitivity label restriction
4. license/client prerequisite issue
5. guest/external sharing limitation
6. genuine Copilot fault (last resort)

## Ticket-by-Ticket Triage

### 1) Finance lead: "Copilot won't summarise the Q3 board pack in SharePoint. 'It's right there, I can see it myself.'"

Likely cause (ranked):
1. permissions/access boundary
2. sensitivity label restriction
3. data indexing lag
4. license/client prerequisite issue
5. genuine Copilot fault

Fastest check:
- Confirm the board pack file's library/folder permissions and whether the same user has at least View rights directly on the file (not only via a link path).

Is this actually a Copilot bug?
- Unclear. Most likely access or protection policy scope mismatch rather than product fault.

---

### 2) New hire (started yesterday): "Copilot in Outlook seems to know nothing about my recent emails."

Likely cause (ranked):
1. data indexing lag
2. license/client prerequisite issue
3. permissions/access boundary
4. genuine Copilot fault

Fastest check:
- Verify Copilot add-on is assigned and active for the user account first.

Is this actually a Copilot bug?
- No (most likely). Day-1/day-2 profile and mailbox indexing delay is common.

---

### 3) HR manager: Asked Copilot in Word to pull data from a sensitive salary review spreadsheet, got "I don't have access to that content."

Likely cause (ranked):
1. permissions/access boundary
2. sensitivity label restriction
3. data indexing lag
4. genuine Copilot fault

Fastest check:
- Open the spreadsheet as the same HR manager identity and confirm direct file permissions (not delegated/assumed access).

Is this actually a Copilot bug?
- No (most likely). The message indicates an access boundary or protection-policy restriction.

---

### 4) Sales rep: Copilot in Teams can't find a client contract that was shared with her via a guest link from another org.

Likely cause (ranked):
1. guest/external sharing limitation
2. permissions/access boundary
3. data indexing lag
4. genuine Copilot fault

Fastest check:
- Confirm whether the contract resides in another tenant and is only available through guest/external sharing.

Is this actually a Copilot bug?
- No (most likely). Cross-tenant guest sharing scope is the leading explanation.

---

### 5) IT admin: Copilot suddenly stopped working for the whole Finance team this morning, was fine yesterday.

Likely cause (ranked):
1. license/client prerequisite issue
2. permissions/access boundary
3. genuine Copilot fault

Fastest check:
- Check one affected user's Copilot add-on assignment and service health/tenant advisories at tenant level.

Is this actually a Copilot bug?
- Unclear. A broad same-day outage pattern may be tenant config/licensing/service-health related; only call product fault after tenant/service checks fail.

---

### 6) Manager: Copilot found and summarised a file I don't remember ever opening, from a folder I forgot I had access to.

Likely cause (ranked):
1. permissions/access boundary
2. data indexing lag
3. genuine Copilot fault

Fastest check:
- Validate current effective permissions for that folder and user; confirm inherited access path.

Is this actually a Copilot bug?
- No (most likely). This is a classic oversharing/access hygiene issue, not Copilot bypassing permissions.

---

### 7) Analyst: Copilot gives generic answers, doesn't seem to use any of our internal SharePoint content at all.

Likely cause (ranked):
1. license/client prerequisite issue
2. permissions/access boundary
3. data indexing lag
4. sensitivity label restriction
5. genuine Copilot fault

Fastest check:
- Verify the analyst has Copilot add-on assigned and is on supported Microsoft 365 Apps/Teams client versions.

Is this actually a Copilot bug?
- Unclear. Usually entitlement/client readiness or content access scope issues first.

---

### 8) Executive assistant: Copilot in Outlook can't see a shared mailbox's calendar that I manage on behalf of my director.

Likely cause (ranked):
1. permissions/access boundary
2. guest/external sharing limitation
3. license/client prerequisite issue
4. genuine Copilot fault

Fastest check:
- Confirm delegated/shared mailbox calendar permissions are explicitly granted and that scenario is supported for Copilot context.

Is this actually a Copilot bug?
- No (most likely). Delegated/shared mailbox boundaries are the primary suspect.

## Escalation Rule for "Genuine Copilot Fault"

Escalate as potential product fault only after:
- Access boundary checks pass.
- Licensing/client prerequisite checks pass.
- Label/policy restrictions are ruled out.
- Reasonable indexing delay window has passed.
- Issue is reproducible across multiple properly configured users.
