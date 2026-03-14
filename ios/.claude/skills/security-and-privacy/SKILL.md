---
name: security-and-privacy
description: >
  Security and privacy guidance for native mobile projects. Use for secrets,
  storage, logging, permissions, validation, and sensitive-data handling.
---

# Security And Privacy

## Core Rules

- Never hardcode secrets, credentials, tokens, or certificate material
- Never log raw personal data, auth payloads, or sensitive identifiers
- Validate untrusted input at every boundary: user, local storage, and network
- Keep permissions minimal, explicit, and documented

## Review Focus

- Check storage choices for sensitive data exposure
- Check analytics and logging for leakage
- Check network and persistence code for unsafe defaults