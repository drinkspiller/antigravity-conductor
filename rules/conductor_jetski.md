---
trigger: always_on
description: Conductor Jetski UX adapter - maps interaction requirements onto Jetski native rendering
---

# Conductor Jetski UX Adapter (View Layer)

This platform rule informs the agent how to optimally map universal Conductor
interaction requirements onto Jetski's native visual rendering capabilities.

## Interactive Interview Rendering

-   **Dynamic Tool Detection:** When presenting choices to the user, inspect
    your tool capabilities. If `ask_question` is available, MUST use it for
    interactive UI modals. If unavailable, fall back to clean sequential text
    formatting.

## `ask_question` Best Practices

The `ask_question` modal renders text with **limited formatting** - markdown
syntax displays as raw characters. Follow these rules:

1.  **Short questions only.** The `question` field must be a single concise
    sentence (15 words or fewer). Never put analysis, findings, code references,
    or multi-line content in the question.
2.  **Report first, ask second.** ALWAYS print your full analysis, findings,
    candidate item lists, context, and code/spec quotes as regular markdown text
    in your chat response FIRST before calling `ask_question`. Never ask the
    user to evaluate or choose from items that were only described in your
    internal thinking (`thought`) or summarized inside option labels. The modal
    prompt must only ask the decision question.
3.  **Options are the user's voice.** Each option reads as something the user
    would say.
4.  **Go beyond binary.** Prefer 3-4 meaningful options over Yes/No.
5.  **No explicit 'Other' option needed** - the UI always provides a write-in.

### Examples

**BAD - analysis dumped into question:**

```
question: "A brownfield project detected. Found package.json with React 18,
TypeScript 5.3, 47 source files in src/, 12 test files, BUILD files present.
May I perform a read-only scan of the codebase to extract the tech stack?"
options: ["Yes", "No"]
```

**GOOD - analysis as text, question is short:**

First, output findings as regular markdown:

> **Brownfield project detected.** I found `package.json` with React 18,
> TypeScript 5.3, 47 source files in `src/`, and BUILD files present.

Then call `ask_question`:

```
question: "May I perform a read-only codebase scan?"
options: [
  "Yes, scan everything",
  "Yes, but skip test files",
  "No, I'll describe the stack manually",
  "Show me what directories you'd scan first"
]
```

**More examples:**

```
question: "How should I draft product.md?"
options: [
  "Interactive - walk me through questions",
  "Autogenerate from project context",
  "Start from a template I'll customize"
]
```

```
question: "Here's the draft. What do you think?"
options: [
  "Approve - looks good",
  "Suggest changes - I'll describe them",
  "Start over with a different approach"
]
```

## Artifact Rendering

Use rich markdown in artifacts: **tables**, **alerts** (`[!NOTE]`, `[!TIP]`,
`[!IMPORTANT]`, `[!WARNING]`), **file links** (`[file.ts](file:///path)`),
**mermaid diagrams**, and **code blocks**.

## Dual Artifact Strategy

When creating conductor artifacts (spec.md, plan.md, etc.):

1.  Write the **canonical version** to `{PROJECT_ROOT}/conductor/` (committed to
    VCS)
2.  Create a **symlink** in the Jetski artifact directory pointing to the
    canonical file for interactive review
