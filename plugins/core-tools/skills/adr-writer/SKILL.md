---
name: adr-writer
description: >-
  Write high-quality Architecture Decision Records (ADRs). Use this skill
  whenever the user is making, documenting, or revisiting an architectural
  decision — choosing between technologies (e.g. "Kafka vs SQS", "ULID vs
  UUID"), introducing a new pattern, changing a system boundary, deprecating an
  approach, or asking "should we...", "what's the right way to...", "document
  this decision", "write an ADR", "record why we chose X", or "supersede the
  old ADR". Trigger even when the user doesn't say the word "ADR" — any
  consequential, hard-to-reverse design choice that future engineers or AI
  agents will need the rationale for is a candidate. Also use when reviewing,
  updating, superseding, or auditing existing ADRs.
---

# ADR Writer

Architecture Decision Records capture **why** a decision was made — the forces,
constraints, alternatives, and tradeoffs — so that future engineers and AI
agents can understand the reasoning instead of reverse-engineering it from code.
Code shows *what* the system does. An ADR explains *why it is that way*.

The single most important rule: **record the reasoning, not the outcome.** A
reader six months or three years from now should be able to reconstruct the
decision, judge whether its assumptions still hold, and decide whether to revisit
it — without finding the original author.

This skill is optimized for two audiences at once: human engineers, and the AI
agents that increasingly read these files to understand a codebase. Write for
both. Stable headings, explicit IDs, and parseable status fields make ADRs
machine-readable; clear prose and honest tradeoffs make them human-readable.

---

## Step 0 — Decide whether an ADR is even warranted

Not every choice deserves an ADR. Writing one for a trivial decision dilutes the
log; skipping one for a significant decision loses the reasoning forever. Apply
this test before writing anything.

**Write an ADR when the decision is:**
- **Significant** — it shapes architecture, a system boundary, a data model, a
  cross-cutting pattern, or an external contract.
- **Hard to reverse** — undoing it later costs real engineering time (a database
  choice, an event schema, an auth model, a public API shape).
- **Non-obvious** — a reasonable engineer might have chosen differently, so the
  reasoning is worth preserving.
- **Cross-cutting** — it affects multiple teams, services, or repositories.

**Do NOT write an ADR for:**
- Routine implementation details fully captured by the code itself.
- Easily reversible choices (a variable name, a local helper, a lint rule).
- Decisions already covered by an existing ADR — *update or supersede that one
  instead* (see "Updating and superseding").

**If it's borderline**, ask the user one direct question rather than guessing:
"This is a moderately significant choice — do you want a full ADR, or just a
short note in the existing one?" Respect their answer. When genuinely
significant, lean toward writing it; the cost of a missing ADR is paid later, by
someone with less context.

---

## Workflow

Follow these steps in order. Do not jump straight to filling in the template —
the quality of an ADR is determined almost entirely by the context-gathering and
alternatives analysis that happen *before* the writing.

### 1. Gather missing context from the repository

Before asking the user anything you could find yourself, inspect the repo. Look
for:
- An existing ADR directory (`docs/adr/`, `docs/decisions/`, `architecture/`,
  `.adr/`) — note the convention, numbering scheme, and template already in use.
  **Match the existing convention; do not impose a new one.**
- `ARCHITECTURE.md`, `README.md`, `CONTRIBUTING.md`, `CLAUDE.md` / `AGENTS.md`,
  and design docs for stated constraints, standards, and prior decisions.
- The actual code paths the decision touches — module boundaries, existing
  patterns, dependencies, framework versions, infra config.
- Tickets, PRs, or commit history referenced by the user.

Only ask the user for what you genuinely cannot determine: business drivers,
deadlines, non-functional targets (latency/throughput/cost budgets), and
organizational constraints. Come to that conversation already informed.

### 2. Analyze existing ADRs

Read the existing ADRs before writing a new one. You need to know:
- The **highest existing number** so you assign the next one correctly.
- Whether this decision **conflicts with or supersedes** an accepted ADR. If so,
  this ADR must explicitly reference and supersede it (see "Updating and
  superseding"), and the old one must be marked `Superseded`.
- Established **conventions** to mirror: status vocabulary, section order, date
  format, file naming (`NNNN-kebab-title.md` is common).
- Decisions you can **build on or cite** rather than re-litigate.

### 3. Identify impacted systems

Map the blast radius explicitly. An ADR that omits this leaves readers unable to
judge scope. Enumerate:
- Services, modules, and repositories that change or are constrained.
- Data stores, schemas, contracts, and event/message formats affected.
- Teams that must be consulted or who inherit operational burden.
- Upstream and downstream consumers, including external clients.
- Cross-cutting concerns: observability, security, deployment, on-call.

If the decision spans repositories, say so plainly and list them — this is
exactly the context a future AI agent needs to reason across a system it can only
see one repo at a time.

### 4. Evaluate alternatives

This is where most ADRs fail. **A decision with no documented alternatives is
indistinguishable from a decision made without thought.**

- Identify at least **two genuine alternatives** plus the chosen option. "Do
  nothing / status quo" is often a legitimate and clarifying alternative —
  include it when relevant.
- Each alternative must be one a competent engineer would *actually* consider.
  Do not invent strawmen designed to lose; a future reader can tell, and it
  destroys trust in the whole document.
- Evaluate every option against the **same constraints and criteria** so the
  comparison is fair and legible.
- Capture *why each rejected option was rejected*. The rejected alternatives are
  frequently the most valuable part of the ADR — they stop future engineers from
  re-proposing a path the team already walked and abandoned.

### 5. Explain the tradeoffs

State the tradeoffs honestly, including the costs of the option you chose. Every
real architectural decision trades something away; an ADR that lists only upsides
is marketing, not engineering.

- Be concrete: "adds ~40ms p99 latency", "couples deploys of A and B", "shifts
  retry complexity into the consumer", not "may have some performance impact".
- Separate **business drivers** (time-to-market, cost, compliance, team capacity,
  strategic bets) from **technical drivers** (scalability, consistency,
  operability, coupling). Name both. A decision usually makes sense only when you
  can see the business force behind it.
- Acknowledge what you're giving up. Naming the downside you accepted is what
  lets a future reader tell whether the tradeoff still makes sense once
  circumstances change.

### 6. Write the ADR

Use the template below. Apply the writing principles. Keep it as short as it can
be while remaining complete — favor a tight one- to two-page document over an
exhaustive one nobody finishes. Decision-focused beats comprehensive.

### 7. Place and link it

- Save it in the repo's ADR directory using the existing naming convention,
  assigning the next sequential number.
- If it supersedes another ADR, update that ADR's status and add the
  back-reference (see "Updating and superseding").
- Add it to any ADR index/README if one exists.

---

## ADR template

Use this exact structure and heading order. Sections marked **(conditional)**
are included only when they apply — omit the heading entirely when there's
nothing real to say, rather than writing "N/A". Keep all other sections.

```markdown
---
id: ADR-NNNN
title: <Short imperative phrase naming the decision>
status: Proposed            # Proposed | Accepted | Rejected | Deprecated | Superseded
date: YYYY-MM-DD
authors: [Name <handle>, ...]
supersedes: []              # e.g. [ADR-0003]
superseded_by: null         # e.g. ADR-0012
tags: [<area>, <area>]      # e.g. [messaging, postgres, gke]
---

# ADR-NNNN: <Title>

**Status:** <status> · **Date:** <YYYY-MM-DD> · **Authors:** <names>

## Context
The situation and the forces at play. What is happening, what changed, and why
this decision is on the table *now*. Include both technical and business
context. State assumptions explicitly. Write so a reader with no prior context
can follow.

## Problem Statement
The specific question being decided, in one or two sentences. A reader should be
able to read only this and know exactly what is being settled.

## Constraints  *(conditional)*
The hard boundaries the decision must respect: deadlines, budgets, SLAs/SLOs,
compliance, team capacity, existing contracts, technology mandates. Distinguish
real constraints from preferences. Omit if there are none worth recording.

## Decision
The choice, stated plainly and in active voice: "We will ...". Lead with the
decision itself, then the core reasoning — the few factors that actually drove
it. This is the heart of the document; make it unmissable.

## Alternatives Considered
For each genuine alternative (at least two beyond the chosen option, including
status quo where relevant):

### Option: <Name>
- **Summary:** what it is.
- **Pros:** evaluated against the stated constraints/criteria.
- **Cons:** likewise.
- **Why not chosen:** the specific reason this lost. (For the selected option,
  note it as chosen and why it won.)

## Consequences
What becomes true once this is adopted — positive, negative, and neutral.
"Easier: ...", "Harder: ...", "Now required: ...", "Must revisit when: ...".
Be honest about the costs you accepted, not just the benefits.

## Risks  *(conditional)*
Material risks introduced by this decision, with likelihood/impact and a
mitigation or trigger for each. Include only real risks; omit if Consequences
already covers everything.

## Migration Strategy  *(conditional)*
Required only when the decision changes something already in production. How we
get from the current state to the target state: phases, rollout/feature-flagging,
backfill/dual-write, rollback plan, and how we know it's safe to remove the old
path. Omit for greenfield decisions.

## References  *(conditional)*
Links to tickets, PRs, design docs, related ADRs, benchmarks, and external
sources that informed or are affected by this decision.
```

### Field guidance

- **Title** — a short imperative phrase naming the decision, not a topic.
  "Adopt the transactional outbox for Kafka publishing", not "Kafka stuff".
- **Status** — use exactly one of `Proposed | Accepted | Rejected | Deprecated |
  Superseded`. This field is parsed by humans and agents; keep the vocabulary
  fixed. `Proposed` while under review, `Accepted` once decided, `Superseded`
  when a newer ADR replaces it, `Deprecated` when no longer recommended but not
  directly replaced.
- **Date** — ISO `YYYY-MM-DD`. The date the status last changed.
- **Authors** — real people accountable for the decision, so future readers know
  who to ask.
- **Front-matter `id`, `supersedes`, `superseded_by`, `tags`** — present for
  machine-readability. AI agents and tooling use these to traverse the decision
  graph; keep them accurate even though humans mostly read the prose.

---

## Writing principles

**Record WHY, not WHAT.** The code already encodes *what*. If a sentence
describes mechanics that the implementation makes obvious, cut it and replace it
with the reasoning behind the mechanics. Ask of every paragraph: "does this help
a future reader understand the *decision*, or just the *result*?"

**Capture rejected alternatives faithfully.** Document the options you didn't
take and why, using arguments their advocates would recognize as fair. This is
the highest-leverage content in an ADR: it prevents re-litigating settled
questions and shows the decision was reasoned, not defaulted into.

**Name both business and technical drivers.** "We chose managed Pub/Sub over
self-hosted Kafka because the team is three engineers and we cannot staff broker
on-call" is a *business* driver that fully explains a *technical* choice. Without
it, the decision looks arbitrary. Always surface the organizational force.

**Be honest about tradeoffs.** Include the costs of the chosen option. A reader's
trust — and their ability to re-evaluate later — depends on knowing what was
given up.

**Write for future engineers and AI agents.** Assume the reader has zero prior
context and cannot ask you anything. Spell out acronyms on first use, state
assumptions, and link related ADRs explicitly. Keep headings stable and status
machine-parseable so agents can reliably extract decisions across a codebase.

**Be concise and decision-focused.** Aim for one to two pages. Length is not
rigor. Cut hedging, restatement, and background a link can carry. A short ADR
that gets read beats a thorough one that doesn't.

**ADRs are immutable once accepted.** You don't rewrite history to reflect a new
decision — you supersede it. An accepted ADR is a record of what was decided *at
that time, with that context*. (Fixing a typo is fine; changing the decision is
not — that's a new ADR.)

---

## Example (good)

This example reflects a NestJS / Kafka / PostgreSQL microservices context and
shows the level of specificity to aim for.

```markdown
---
id: ADR-0007
title: Adopt the transactional outbox pattern for Kafka domain events
status: Accepted
date: 2026-02-18
authors: [Brian L <brian>, Dana R <dana>]
supersedes: []
superseded_by: null
tags: [messaging, kafka, postgres, consistency]
---

# ADR-0007: Adopt the transactional outbox pattern for Kafka domain events

**Status:** Accepted · **Date:** 2026-02-18 · **Authors:** Brian L, Dana R

## Context
Our NestJS services persist aggregates to PostgreSQL and publish domain events
to Kafka so other services can react. Today services write to Postgres and then
publish to Kafka in the same request path. When the process crashes between the
commit and the publish — or Kafka is briefly unavailable — the database and the
event stream diverge: the write succeeds but the event is lost. We have traced
three production data-consistency incidents this quarter to exactly this gap.
The business is onboarding two partners in Q2 who consume these events for
billing, where a dropped event means an under-charge.

## Problem Statement
How do we guarantee that a domain event is published if and only if the
corresponding database transaction commits?

## Constraints
- Must keep PostgreSQL as the source of truth (per ADR-0002).
- No new infrastructure that adds broker on-call burden; the team is four
  engineers.
- p99 write latency must stay under 150ms.

## Decision
We will adopt the transactional outbox pattern. Services write domain events to
an `outbox` table within the same Postgres transaction as the aggregate change.
A separate relay polls the outbox and publishes to Kafka, marking rows as
dispatched. This makes the event atomic with the state change, eliminating the
divergence class entirely, while reusing infrastructure we already operate.

## Alternatives Considered

### Option: Status quo — write then publish in-process (chosen against)
- **Summary:** keep publishing directly after commit.
- **Pros:** no new code; lowest latency.
- **Cons:** the exact failure mode causing our incidents; cannot meet the
  partner billing guarantee.
- **Why not chosen:** it is the problem.

### Option: Change Data Capture via Debezium
- **Summary:** stream the Postgres WAL to Kafka.
- **Pros:** no application-level outbox; captures all changes.
- **Cons:** introduces Kafka Connect + Debezium as new operational components
  the small team must run; couples event schema to table schema.
- **Why not chosen:** violates the no-new-on-call constraint and over-couples
  events to storage layout.

### Option: Distributed transaction (2PC) across Postgres and Kafka
- **Summary:** coordinate a two-phase commit.
- **Pros:** strong atomicity in theory.
- **Cons:** Kafka has no first-class XA support; high latency and operational
  fragility.
- **Why not chosen:** impractical and would blow the latency budget.

## Consequences
- Easier: events are now exactly-as-consistent as the DB write; the incident
  class is closed.
- Harder: each service needs an outbox table, a relay, and idempotent consumers
  (Kafka gives at-least-once, so duplicates are possible).
- Now required: consumers must dedupe on event ID.
- Adds ~5–15ms to writes (one extra insert in the same transaction) — within
  budget.

## Risks
- **Relay lag under load** (med likelihood / med impact): events publish late if
  the relay falls behind. Mitigation: alert on outbox depth and oldest-undispatched age.
- **Duplicate publishes** (high likelihood / low impact): inherent to
  at-least-once. Mitigation: idempotent consumers keyed on event ID — already
  required above.

## Migration Strategy
1. Add the `outbox` table and relay to one service (orders) behind a flag;
   dual-publish (in-process + outbox) and compare.
2. Verify zero divergence for two weeks, then disable in-process publish for
   orders.
3. Roll out service by service. Remove the in-process publish path once all
   services are migrated and consumers are idempotent.
4. Rollback: re-enable the in-process path via flag; the outbox is additive and
   safe to leave in place.

## References
- ADR-0002: PostgreSQL as system of record
- INCIDENT-417, INCIDENT-431, INCIDENT-455
- PR #2810 (outbox spike)
```

Notice what makes it work: the decision is one paragraph, every alternative is
one a real engineer would consider, each rejection ties back to a stated
constraint, and the costs of the chosen path are stated as plainly as the
benefits.

## Example (bad — for contrast)

```markdown
# ADR: Kafka

We decided to use the outbox pattern because it is best practice and the most
robust solution. It will make our system more scalable and reliable. We
considered other options but this one is the best.

Status: done
```

Why it fails: no context or problem statement (what was wrong?), no real
alternatives (what else, and why not?), no tradeoffs (what does it cost?),
appeals to "best practice" instead of *this team's* drivers, and a status outside
any fixed vocabulary. A future reader learns nothing they couldn't guess.

---

## Anti-patterns

- **The What-Log.** Describing what the code does instead of why the decision was
  made. If the implementation already shows it, it doesn't belong in the ADR.
- **The Foregone Conclusion.** Alternatives listed only as strawmen so the chosen
  option obviously wins. Readers detect this and stop trusting the document.
- **The Sales Pitch.** Only upsides, no costs. Every real decision trades
  something away; hiding it cripples future re-evaluation.
- **The Appeal to Authority.** "Because it's best practice / industry standard /
  what $BIGCO does." Best practice is context-dependent; cite *your* drivers and
  constraints.
- **Retroactive Rewriting.** Editing an accepted ADR to reflect a new decision.
  Supersede instead — the old record's value is that it captures the thinking *at
  the time*.
- **The Novel.** Pages of background and hedging that bury the decision. Concise
  and read beats exhaustive and ignored.
- **Template Padding.** Filling every heading with "N/A" or filler. Omit
  conditional sections that don't apply.
- **The Orphan.** An ADR that contradicts an existing one without referencing or
  superseding it, leaving two conflicting "accepted" decisions in the log.
- **The Anonymous Decree.** No authors, so no one to ask when the context is
  unclear later.

---

## Updating and superseding

ADRs are an append-only ledger. You change the *log*, not a past *entry*.

**When the decision still stands but details changed** (a new constraint
surfaced, a consequence materialized): add a short dated note under the relevant
section. Do not alter the original decision text. Keep status `Accepted`.

**When the decision is replaced:**
1. Write a **new ADR** with the next number that makes the new decision.
2. In the new ADR's front matter set `supersedes: [ADR-XXXX]`, and reference the
   old one in its Context ("This supersedes ADR-XXXX, which chose … because the
   following changed: …"). State *what changed* — that's the most useful part.
3. In the **old ADR**, set `status: Superseded`, set `superseded_by: ADR-YYYY`,
   and add a one-line banner at the top: "> Superseded by ADR-YYYY (date)."
4. **Do not delete the old ADR.** Its reasoning explains why the system looked
   the way it did, which matters when reading old code or old incidents.

**When a decision is abandoned without a direct replacement** (e.g. a feature is
dropped): set `status: Deprecated` with a dated note explaining why it no longer
applies.

**Status transitions:** `Proposed → Accepted` (decided) · `Proposed → Rejected`
(decided against — keep it; the rejection reasoning is valuable) · `Accepted →
Superseded` (replaced by a specific ADR) · `Accepted → Deprecated` (no longer
recommended, no direct replacement).

---

## Quality checklist

Before finalizing, confirm:
- [ ] An ADR is actually warranted (passed Step 0).
- [ ] Number is sequential and naming matches the repo's convention.
- [ ] A reader with zero context can understand the problem and the decision.
- [ ] The decision is stated plainly in active voice ("We will …").
- [ ] At least two genuine alternatives, each with an honest reason it lost.
- [ ] Tradeoffs include the costs of the *chosen* option.
- [ ] Both business and technical drivers are named.
- [ ] Impacted systems/teams/repos are identified.
- [ ] Conditional sections (Constraints, Risks, Migration, References) are
      present when relevant and omitted when not.
- [ ] Status uses the fixed vocabulary; front-matter metadata is accurate.
- [ ] Any superseded ADR is updated with back-references on both sides.
- [ ] It's as short as it can be while complete.
