# WFSL Shell Guard

**Execution safety guard for PowerShell and shell environments.**

WFSL Shell Guard prevents accidental execution of pasted console output, transcripts, or documentation by enforcing explicit execution boundaries.

It is designed for operators and teams working in hostile, opaque, or error-prone shell environments where intent must be protected.

---

## What this does

WFSL Shell Guard:

- Detects pasted console output and transcript artefacts
- Prevents accidental execution of non-code text
- Forces explicit operator intent before execution
- Reduces destructive copy-paste errors
- Operates locally with no network access

The guard is intentionally simple, deterministic, and non-invasive.

---

## Why this exists

Modern shells do not distinguish clearly between:

- Commands
- Output
- Documentation
- Logs
- Human-readable text

This leads to a common and dangerous failure mode:  
**pasted output being executed as commands**.

WFSL Shell Guard enforces a hard boundary between observation and execution.

---

## Design principles

- No inference
- No heuristics
- No telemetry
- No background services
- Explicit execution only

The guard assumes the platform is unreliable and protects the operator accordingly.

---

## Deterministic verification

This repository includes a deterministic verification harness.

Verification runs:

- Declare execution context explicitly
- Do not rely on shell introspection
- Emit machine-verifiable evidence
- Do not modify system state

Generated artefacts include:

- `environment.json`
- `execution-context.json`
- `run-*.json`

These artefacts demonstrate observed behaviour only.

---

## Intended use

WFSL Shell Guard is suitable for:

- Engineers
- Operators
- Incident response
- Regulated environments
- High-risk production systems

It is intentionally opinionated and conservative.

---

## Licensing and reliance

This repository is available under the **WFSL Community Edition**.

Source code access, local execution, and experimentation are permitted.

**Production reliance, audit claims, or regulatory use are not permitted** without a Commercial Reliance Licence.

Verified tags and verification artefacts demonstrate observed behaviour only and do not grant permission to rely.

See the canonical framework:

- `WFSL-LICENSING-AND-RELIANCE.md`

For commercial licensing enquiries:

licensing@wfsl.uk

---

## Status

- Verification: complete
- Deterministic evidence: emitted
- Network access: none
- Telemetry: none

This repository reflects a verified, non-reliant community release.
