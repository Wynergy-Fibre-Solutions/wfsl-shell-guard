\# WFSL Shell Guard — Specification



\## Purpose

WFSL Shell Guard prevents accidental execution of pasted or malformed PowerShell

content by enforcing explicit execution intent.



It is designed to reduce operator error and protect against unintended command

execution in interactive shells.



\## Scope

This tool operates locally within the PowerShell environment.

It does not inspect network traffic, external files, or remote state.



\## Behaviour

\- Detects pasted multi-line console output

\- Detects mixed prompt and command content

\- Blocks implicit execution paths

\- Requires deliberate user correction or confirmation



\## Inputs

\- PowerShell input buffer

\- Clipboard content (local only)



\## Outputs

\- Clear warning messages

\- Explicit block notifications

\- Allow or deny execution signals



\## Determinism

Given identical input content, WFSL Shell Guard produces identical outcomes.



No external state, time, or network resources are consulted.



\## Exit Semantics

\- Exit 0: Safe execution permitted

\- Exit 1: Execution blocked

\- Exit 2: Invalid or ambiguous input detected



\## Guarantees

\- No telemetry

\- No network access

\- No modification of user scripts

\- No persistence of user input



\## Non-Goals

\- Command auditing

\- Logging user behaviour

\- Remote policy enforcement



