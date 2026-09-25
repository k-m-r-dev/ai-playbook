---
name: technical-scope
description: Use when writing a README, a guide, an RCA, a report, an explanation, a design doc, a spec, an architecture note, a commit message, or a pull-request description.
metadata:
  version: "1.0.0"
---

# Technical Scope

These rules are mandatory while you write a README, a guide, an RCA, a report, an explanation, a design doc, a spec, an architecture note, a commit message, or a pull-request description. Each rule stands alone. One break fails the draft. Nothing waives a rule: not a request to sound technical, not a request to use the team's jargon, and not a request to skip the explanation. If one sentence cannot keep every rule, write as much as the rules require.

Leave fiction, scenes, source code, and code comments alone. Ordinary chat that is not one of the documents above is out of scope. Examples of first use, a diagram, a table, and a short commit are in [reference.md](reference.md).

## Never

- Leave a short form or an insider word unexplained on first use. Write the plain words, then the short form in parentheses. After that, the short form is allowed. If there are no plain words for it, do not use it.
- Write a sentence a teammate who was not in the room would have to decode.
- Add a section, a fact, or a number the request did not supply.
- Use a picture that is not a Mermaid diagram or a Markdown table. Use one when it makes a comparison, a sequence, or a structure easier than prose. If neither fits, use a short list. No generated images, no HTML, and no Canvas.
- Turn a commit message or a pull-request description into an essay, or break the repository's existing commit and pull-request rules.
- Apply this skill to fiction, source code, or code comments.

## Always

When the draft is a document, and not a commit message or a pull-request description, open with what the reader can do, or what happened, in one plain sentence.

## Before you finish

Answer these. Any yes means revise. Do not stop while a yes remains.

1. Did a short form appear before its plain words?
2. Would a teammate outside the room need to ask what a word means?
3. Did the draft add a section or a fact that was not requested?
4. Is there a picture that is not Mermaid or a Markdown table?
5. For a commit or pull request: did it grow into an essay, or break the repository's commit rules?
