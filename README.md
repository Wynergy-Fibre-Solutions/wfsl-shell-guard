# WFSL Shell Guard (Community Edition)

A lightweight PowerShell safety guard that prevents users from accidentally
pasting console output, error traces, or log text back into an active shell.

## Why this exists

PowerShell users frequently copy terminal output and re-paste it by mistake,
causing cascading errors and confusion.

WFSL Shell Guard blocks that class of failure before it executes.

## What it does

- Detects pasted PowerShell output, not commands
- Stops execution safely
- Explains the mistake clearly
- Zero telemetry
- No network access
- No dependencies

## Intended use

- Education
- Developer hygiene
- Regulated environments
- Support desks
- Training sessions

## Status

Community edition. Free. Stable.

This tool emits no telemetry and performs no tracking.

## Licence

MIT
