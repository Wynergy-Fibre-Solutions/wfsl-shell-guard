\# WFSL Shell Guard — Governance



\## Purpose

This document defines governance, change control, and stewardship rules for

WFSL Shell Guard.



The intent is to preserve safety, determinism, and operator trust over time.



\## Authority Binding

WFSL Shell Guard is governed under WFSL Pro Authority principles.



Released behaviour is authoritative once tagged and published.



\## Change Control



\### Permitted Changes

The following may occur without a major version change:

\- Documentation clarifications

\- Internal refactoring with no behavioural change

\- Performance improvements with identical outcomes



\### Restricted Changes

The following REQUIRE a major version increment:

\- Detection logic changes

\- Execution blocking semantics changes

\- Exit code changes

\- Any change that alters safety guarantees



\### Forbidden Changes

\- Telemetry or data collection

\- Network access

\- Silent execution behaviour changes

\- Retroactive modification of released tags

\- Bypassing branch protections



\## Versioning

Strict semantic versioning applies.



Released tags are immutable and authoritative.



\## Stewardship

WFSL Shell Guard prioritises:

\- Safety over convenience

\- Explicit intent over automation

\- Predictable behaviour over flexibility



This tool is stewarded for long-term reliability and trust.



