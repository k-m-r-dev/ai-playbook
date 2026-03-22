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

## Design System Colors

Use the centralized design system (`<App>/DesignSystem/Colors.swift`) for all UI colors. Do not hardcode hex values or raw `Color(red:green:blue:)` in views.

**Use AppColors and gradient presets:**

```swift
// Brand colours
.foregroundStyle(AppColors.Brand.Primary.<appBrandColor>.value)
.background(AppColors.Brand.Secondary.slate.value)

// Semantic labels and backgrounds
.foregroundStyle(AppColors.Label.primary.value)
.background(AppColors.SystemBackground.primary.value)

// System colours (errors, links)
.foregroundStyle(AppColors.Default.systemRed.value)

// Gradients (splash, headers)
.background(LinearGradient.brandPrimaryVertical)
```

**Avoid:** `Color(hex: "872323")`, `Color(red: 0.53, green: 0.14, blue: 0.14)`, or magic hex strings in view code. Centralizing colors reduces inconsistency and makes future design updates safer.