---
name: pii-redaction
description: Redact common personal identifiers before text is sent to an agent.
---

# PII redaction

Run `scripts/redact.py` against input text before passing it to another agent or tool.

## Rules

- Return redacted text and counts by identifier type.
- Never echo an original identifier in logs or output.
- Treat detection as risk reduction, not a compliance guarantee.
- Escalate documents with regulated or highly sensitive data to the approved DLP workflow.