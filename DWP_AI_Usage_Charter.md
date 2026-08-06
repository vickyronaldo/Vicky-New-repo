# Personal AI Usage Charter (DWP Engineer – Public AI Assistants)

**Scope:** Day-to-day desktop/endpoint engineering work using public LLM tools (chatbots, code assistants, summarizers).

---

## 1) What I *can* use public AI for

I will use public AI for low-risk productivity tasks where no sensitive data is required, including:

- Drafting PowerShell/Bash snippets for **generic** endpoint tasks (service checks, log parsing, registry queries, package checks).
- Creating first drafts of:
  - troubleshooting runbooks,
  - step-by-step test plans,
  - release notes,
  - user comms/templates.
- Explaining technical concepts (e.g., Intune policy behavior, Windows event logs, patching patterns) at a general level.
- Refactoring or improving scripts **only after sanitizing** names, paths, hostnames, and tenant details.
- Building checklists for common endpoint processes (onboarding, patch validation, rollback readiness).

---

## 2) What I will *not* use public AI for

I will not paste, upload, or describe in identifiable form any DWP-sensitive material, including:

- End-user case data, claimant information, staff personal data, or any production dataset.
- Credentials/secrets: passwords, API keys, tokens, private certs, recovery keys, MFA seeds.
- Internal architecture details that could raise security risk (exact network topology, privileged admin workflow specifics, exploit paths).
- Raw incident logs/tickets containing identifiable users, devices, or security signals.
- Decisions that require formal authority (security acceptance, policy interpretation, production change approval).

---

## 3) Data-handling rule (PII + credentials)

**Non-negotiable rule:**  
If content contains (or may contain) end-user PII or credentials, it does **not** go into a public AI assistant.

I will:

1. **Classify first** (safe / sensitive / unknown).
2. If unknown, treat as sensitive by default.
3. **Sanitize before prompt:** replace real names, IDs, emails, hostnames, IPs, tenant names, ticket refs, and secrets with placeholders.
4. Keep prompts minimal: only the technical pattern needed.
5. Never ask AI to "store," "remember," or process secret material.

---

## 4) Personal "Generate then Verify" rule (scripts/system changes)

I treat AI output as a draft, never as trusted final output.

Before any endpoint/system change, I will:

- **Read and understand** each command, especially anything that edits registry, services, startup, drivers, firewall, encryption, or identity settings.
- **Dry run first** where possible (`-WhatIf`, test mode, lab VM, non-prod device).
- Validate assumptions: paths, permissions, error handling, rollback steps, and idempotency.
- Run with least privilege and scope to one pilot device/group first.
- Capture evidence (before/after state, logs, exit codes).
- Peer-check or manager-check for high-impact/irreversible changes.
- Only then promote to wider deployment.

---

## Personal accountability

I remain accountable for every action taken from AI-generated content.  
If in doubt: stop, sanitize, and escalate to approved internal channels.

---

**Date created:** 2026-08-03  
**Version:** 1.0  
**Last reviewed:** [Update as needed]
