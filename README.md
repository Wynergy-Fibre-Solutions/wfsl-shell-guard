## Commercial use requires a WFSL licence. See commercial-wfsl-offerings/HOW-TO-BUY.md.

## 

## \# WFSL Shell Guard

## 

## \## Purpose

## 

## WFSL Shell Guard enforces strict execution boundaries between operators and system-level commands.

## 

## It ensures that only explicitly permitted, structured commands are executed, and that all interactions are auditable and deterministic.

## 

## Shell Guard is designed to prevent accidental, implicit, or unsafe command execution.

## 

## ---

## 

## \## Functional Guarantees

## 

## WFSL Shell Guard provides:

## 

## \- Explicit command allowlisting

## \- Deterministic execution paths

## \- Clear rejection of undefined input

## \- Evidence-referenced execution outcomes

## 

## All permitted actions are intentional and traceable.

## 

## ---

## 

## \## What This Component Does Not Do

## 

## WFSL Shell Guard explicitly does not:

## 

## \- Execute arbitrary shell input

## \- Infer operator intent

## \- Modify system state implicitly

## \- Bypass governance or admission layers

## \- Perform background automation

## 

## It enforces boundaries only.

## 

## ---

## 

## \## Execution Model

## 

## WFSL Shell Guard operates as a controlled execution layer.

## 

## Commands must be:

## 

## \- Explicitly declared

## \- Structurally valid

## \- Context-aware

## \- Deterministically executable

## 

## Invalid or undeclared commands must fail explicitly.

## 

## ---

## 

## \## Role in the WFSL Platform

## 

## WFSL Shell Guard occupies a boundary enforcement tier within the WFSL platform.

## 

## It is used by:

## 

## \- WFSL ProofGate CLI

## \- Operator workflows

## \- Demonstration environments

## \- Controlled execution pipelines

## 

## No system-level action within WFSL should occur without passing through this boundary.

## 

## ---

## 

## \## Classification and Licence

## 

## Classification: WFSL Open  

## Licence: Apache License 2.0

## 

## This repository is open-source and auditable.

## 

## Commercial and production reliance requires a valid WFSL licence.

## 

## ---

## 

## \## Stability

## 

## This repository is considered stable once execution rules and rejection behaviour are fixed.

## 

## Any expansion of permitted command scope requires explicit versioning and documentation.

## 

