# WFSL Shell Guard

**Execution safety guard for PowerShell environments.**

WFSL Shell Guard prevents accidental execution of pasted output, logs, or malformed commands in interactive PowerShell sessions.

It is designed for correctness-first operators working in sensitive or irreversible environments.

---

## What this does

- Detects pasted content that is not valid PowerShell intent
- Blocks execution of logs, transcripts, or copied output
- Reduces operator-induced execution faults
- Provides deterministic pass or fail outcomes

Nothing is inferred. Nothing is silently corrected.

---

## Why this exists

Shell environments are dangerous by default.

WFSL Shell Guard enforces a simple rule:

> **If execution intent is ambiguous, execution is denied.**

This reduces:
- Accidental command execution
- Copy-paste induced outages
- Operator error in high-pressure environments

---

## Relationship to WFSL Core

WFSL Shell Guard implements the governance and verification principles defined in **WFSL Core**.

It does not define its own trust, licence, or reliance model.

---

## Licensing and reliance

This repository is available under the **WFSL Community Edition**.

Source code access, local execution, and experimentation are permitted.

**Production reliance, audit claims, regulatory positioning, or commercial use are not permitted** without a Commercial Reliance Licence.

Verification artefacts demonstrate observed behaviour only and do not grant permission to rely.

See the canonical framework:

- `WFSL-LICENSING-AND-RELIANCE.md`

For commercial licensing enquiries:

licensing@wfsl.uk

---

## Status

- Governance aligned: yes
- Licence boundary enforced: yes
- Runtime guarantees: none implied
- Behaviour: unchanged

This tool is intentionally conservative.
