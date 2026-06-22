# Conductor E2E Lifecycle Example Scenario Walkthrough

> [!NOTE] This contrived test walkthrough stress-tests the full operational
> lifecycle of Conductor ADR and glossary capabilities without waiting
> for organic project drift.

--------------------------------------------------------------------------------

## The Sandbox Scenario: `example-shop`

**Setting:** You drop into a contrived e-commerce checkout service. The repo has
basic Conductor files (`product.md`, `tech-stack.md`), but predates the ADR
system. It has **no** `conductor/adr/` folder and **no** `terms.md`.

Buried inside `tech-stack.md` is this legacy sentence:

> *"Session state is cached in Redis, and relational transactions are committed
> to Cloud Spanner."*

--------------------------------------------------------------------------------

## Act I: Preflight Interceptor Trap (Brownfield Backfill)

**Action:** You initiate a routine track.

```text
/conductor_newTrack "Add one-click Apple Pay checkout"
```

**Execution Flow:**

1.  `conductor_protocol.md` §6 evaluates prior to `newTrack` protocol
    initialization. It detects `conductor/adr/` does not exist.
2.  Execution pauses. The universal interceptor sweeps `tech-stack.md` and
    isolates the Redis/Spanner assertion.

**Expected UI Prompt:**

> *Hold up. I swept your existing documentation and noticed foundational
> architectural choices that predate our decision records. Let's get these
> locked down before planning new work.*
>
> *Found in `tech-stack.md`: **"Relational transactions are committed to Cloud
> Spanner."*** *Qualifies for an ADR (hard to reverse × real trade-off).
> Formalize as ADR-0001?* 1. **Yes, backfill ADR-0001** *(Recommended)* 2. Yes +
> define 'Spanner' in terms.md 3. No, leave in prose

**Asserted Outcome:** You select `1`. The agent immediately writes
`conductor/adr/0001-cloud-spanner-transactions.md` and initializes a sparse
`terms.md`. The primary `/conductor_newTrack` command resumes seamlessly.

--------------------------------------------------------------------------------

## Act II: Inline Gating & Vocabulary Capture

**Action:** You answer the standard reconnaissance questions for the Apple Pay
track until hitting **Step 7 (Design Decision Elicitation)**.

The agent asks: *"How should Apple Pay merchant validation tokens be verified?"*
You respond: *"Client-side via WebKit JS bridge."*

**Execution Flow:**

1.  The agent evaluates the 3-part gate: Hard to reverse? Yes. Surprising? Yes
    (server validation is standard). Real trade-off? Yes.
2.  Gate fires inline.

**Expected UI Prompt:**

> *Worth preserving? An ADR would help future-you understand why
> client-side verification was chosen over server-side.* 1. **Record as ADR**
> *(Recommended)* 2. Keep in spec only 3. Skip ADR prompts for this track

**Asserted Outcome:** You select `1`. The agent writes
`conductor/adr/0002-apple-pay-client-token-validation.md`.

Immediately after, **Glossary Interception** fires:

> *New vocab: **'Merchant Validation Token'**. Worth defining in
> terms.md for team consistency?* 1. **Yes, auto-define** *(Recommended)* 2.
> Yes, I'll write the definition 3. Skip

You select `1`. `terms.md` gains its second entry.

--------------------------------------------------------------------------------

## Act III: The Verification Bridge

**Action:** You approve the spec and reach **Step 13 (Interactive Plan
Generation)**.

Inside the newly written `0002-apple-pay-client-token-validation.md`, the agent
proactively included:

```md
## Confirmation

- [ ] Usability test: WebKit token handshake completes under 150ms on iOS Safari
```

**Execution Flow:** The Step 13 Verification Bridge scans active ADRs. It
extracts the confirmation checkbox from ADR-0002 and injects it into the
execution plan.

**Expected Output (`plan.md` review diff):**

```diff
  ## Phase 2: Core Handshake Implementation
  - [ ] Implement WebKit JS bridge event listener
+ - [ ] Verify ADR-0002: WebKit token handshake completes under 150ms on iOS Safari
  - [ ] Checkpoint: Phase 2 automated test suite
```

**Asserted Outcome:** Architectural decisions recorded in prose automatically
materialize as verifiable engineering tasks in `plan.md`.

--------------------------------------------------------------------------------

## Act IV: Review Compliance Trap (Drift Detection)

**Action:** You simulate lazy developer muscle memory. During
`/conductor_implement`, you edit `checkout.ts` to verify the Apple Pay token on
the *Python backend* instead of the *WebKit JS bridge* (violating ADR-0002). You
mark the plan complete and run:

```text
/conductor_review
```

**Execution Flow:** `conductor_review` §2.4 loads active ADRs and cross-checks
the code diff against ADR-0002. It catches the spatial contradiction.

**Expected Output:**

```markdown
## Verification Checks
- Intent vs Spec: [Pass]
- ADR Compliance: [Fail] ⚠️
- Style Compliance: [Pass]

## Findings

### High Severity (ADR Drift)
- **ADR-0002 Contradiction**: `src/checkout.ts` posts validation payload to `/api/v1/validate` on L88. ADR-0002 explicitly mandates client-side WebKit JS bridge verification.
```

> *ADR-0002 mandated WebKit bridge verification, but
> implementation diverged to backend API calls. Intentional architecture
> evolution?* 1. **Fix the code** *(Revert checkout.ts to use WebKit bridge)* 2.
> **Update ADR-0002** *(Promote backend validation to new Source of Truth)* 3.
> **Acknowledge as Tech Debt** *(Tag Medium finding in review report)*

**Asserted Outcome:** You select `2`. The agent opens
`0002-apple-pay-client-token-validation.md`, rewrites the decision outcome to
reflect backend validation, updates the revision SHA, and signs off on the
review.

--------------------------------------------------------------------------------

## Verification Matrix

| Act     | Trigger               | Target Mechanism       | Verification   |
|         |                       |                        | Assertion      |
| :------ | :-------------------- | :--------------------- | :------------- |
| **I**   | `/conductor_newTrack` | `conductor_protocol.md | Preflight trap |
|         | on legacy repo        | §6`                    | pauses track,  |
|         |                       |                        | sweeps docs,   |
|         |                       |                        | writes         |
|         |                       |                        | ADR-0001       |
| **II**  | Non-standard design   | `newTrack §7`          | 3-part gate    |
|         | choice                |                        | writes         |
|         |                       |                        | ADR-0002;      |
|         |                       |                        | captures       |
|         |                       |                        | domain noun in |
|         |                       |                        | `terms.md`     |
| **III** | `plan.md` generation  | `newTrack §13`         | ADR            |
|         |                       |                        | `Confirmation` |
|         |                       |                        | checkbox       |
|         |                       |                        | injected as    |
|         |                       |                        | Phase task     |
| **IV**  | Code contradicts ADR  | `conductor_review      | Review catches |
|         |                       | §2.4`                  | spatial drift; |
|         |                       |                        | forces code    |
|         |                       |                        | fix or ADR     |
|         |                       |                        | amendment      |
