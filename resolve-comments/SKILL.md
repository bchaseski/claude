---
name: resolve-comments
description: >
  Resolves open PR review comments on the current branch. Fetches unresolved
  comments via the GitHub CLI, implements fixes, runs stack-appropriate
  lint/build/tests, and commits only on a clean pass. Repeats up to 3 rounds,
  waiting 5 minutes between rounds to catch newly posted comments. Supports
  TypeScript/NestJS, Python, and Java projects via auto-detected stack modules.
  Use when asked to "resolve comments", "address review feedback", "fix PR
  comments", or "respond to review".
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# Resolve PR Review Comments

Autonomously fetch, address, verify, and commit resolutions for all open review
comments on the current branch's pull request. Runs up to **3 rounds**, waiting
5 minutes between rounds to catch newly posted comments.

---

## Step 0 — Load Stack Module

**Do this before any other phase.**

1. Read `references/detect-stack.md` and follow its instructions to identify the stack
2. Based on the result, read the appropriate stack module:
   - TypeScript / NestJS → `references/nestjs.md`
   - Python → `references/python.md`
   - Java → `references/java.md`
   - Unknown → proceed with base skill only; note stack is unrecognised in final summary
3. Keep the stack module in mind throughout — it governs Phase 2.3 and Phase 4

---

## Prerequisites Check

Before starting, verify the environment:

```bash
# Confirm gh CLI is authenticated
gh auth status

# Confirm we're on a feature branch (not main/master/develop)
git branch --show-current

# Confirm a PR exists for this branch
gh pr view --json number,title,url
```

If any of these fail, stop and report the problem clearly. Do not proceed without
a valid PR.

---

## Phase 1 — Fetch Open Comments

### 1.1 Get All Unresolved Review Comments

```bash
PR_NUMBER=$(gh pr view --json number --jq '.number')

# Inline diff comments
gh api \
  "repos/{owner}/{repo}/pulls/${PR_NUMBER}/comments" \
  --paginate \
  --jq '[.[] | {
    id: .id,
    path: .path,
    line: .line,
    original_line: .original_line,
    side: .side,
    body: .body,
    author: .user.login,
    created_at: .created_at,
    in_reply_to_id: .in_reply_to_id,
    diff_hunk: .diff_hunk
  }]'

# Top-level PR comments (not inline)
gh api \
  "repos/{owner}/{repo}/issues/${PR_NUMBER}/comments" \
  --paginate \
  --jq '[.[] | {id: .id, body: .body, author: .user.login, created_at: .created_at}]'

# Review threads — used to filter already-resolved ones
gh api graphql -f query='
  query($owner: String!, $repo: String!, $number: Int!) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $number) {
        reviewThreads(first: 100) {
          nodes {
            id
            isResolved
            isOutdated
            comments(first: 10) {
              nodes {
                id
                databaseId
                body
                path
                line
                author { login }
              }
            }
          }
        }
      }
    }
  }
' -f owner="{owner}" -f repo="{repo}" -F number="${PR_NUMBER}"
```

### 1.2 Snapshot Already-Seen Comment IDs

```bash
SNAPSHOT_FILE=$(mktemp /tmp/pr-comments-round-XXXX.json)
# Write fetched comment IDs into $SNAPSHOT_FILE for diffing in later rounds
```

---

## Phase 2 — Analyse & Plan Resolutions

### 2.1 Triage Each Comment

| Category | Action |
|---|---|
| **Code change required** | Implement the fix |
| **Question / clarification** | Post a reply explaining the decision; no code change |
| **Nit / style** | Apply if quick; note if intentionally skipped |
| **Architectural disagreement** | Post a reply with rationale; flag for human decision if blocking |
| **Already fixed by prior commit** | Verify and mark as resolved |

### 2.2 Read Full Context Before Editing

1. Read the **full file** at the commented path — never edit based on the diff hunk alone
2. Check if other comments touch the **same file** — batch all changes to a file together
3. Check for related tests using the pattern from your loaded stack module
4. Check for imports that may need updating after the change

### 2.3 Stack-Specific Guidance

**Apply the guidance from your loaded stack module here.** This covers framework
conventions, common pitfalls, and things to double-check when resolving comments
in this codebase. If no stack module was loaded (unknown stack), proceed with
general good judgement.

---

## Phase 3 — Implement Changes

### 3.1 Apply Changes File by File

1. Read the full current file contents
2. Apply **all** comment resolutions for that file in a single edit pass
3. Do not introduce unrelated changes
4. Preserve existing code style (spacing, quote style, import ordering)

### 3.2 Reply to Comments

```bash
# Code change made
gh api \
  "repos/{owner}/{repo}/pulls/${PR_NUMBER}/comments/${COMMENT_ID}/replies" \
  -X POST \
  -f body="Fixed — <one line description of what changed>"

# Intentional no-change
gh api \
  "repos/{owner}/{repo}/pulls/${PR_NUMBER}/comments/${COMMENT_ID}/replies" \
  -X POST \
  -f body="Intentionally kept as-is — <rationale>"
```

### 3.3 Resolve Threads via GraphQL

```bash
gh api graphql -f query='
  mutation($threadId: ID!) {
    resolveReviewThread(input: { threadId: $threadId }) {
      thread { isResolved }
    }
  }
' -f threadId="<THREAD_NODE_ID>"
```

---

## Phase 4 — Verify: Lint, Build, Tests

**Run the verification commands from your loaded stack module.** Stop at the
first failure and fix before continuing. The stack module defines the exact
commands and the order to run them.

General rule that applies to all stacks: if any check fails, fix the failure
before proceeding. Do not skip or suppress checks to force a pass.

---

## Phase 5 — Commit & Push

Only proceed here if all verification from Phase 4 passed.

```bash
git add -p   # review what you're staging; do not stage unrelated changes

git commit -m "fix: resolve PR review comments (round N/3)

$(gh pr view --json number --jq '"Addresses comments on PR #" + (.number | tostring)')

Changes:
- <file>: <what was fixed and why>
- <file>: <what was fixed and why>"

git push origin HEAD
```

---

## Phase 6 — Wait & Re-check (Rounds 2 and 3)

```bash
echo "Round N complete. Waiting 5 minutes before checking for new comments..."
sleep 300
```

Then repeat from **Phase 1**, but:
- Compare fetched comment IDs against `$SNAPSHOT_FILE` to find only **new** comments
- If no new comments exist, exit successfully
- If new comments exist, process only those
- Update `$SNAPSHOT_FILE` before the next round

**Maximum 3 rounds total.** After round 3, stop and print the final summary.

---

## Final Summary

```
=== resolve-comments summary ===

Rounds completed: N / 3
Stack detected: <nestjs|python|java|unknown>
Branch: <branch-name>
PR: #<number> — <title>

Round 1:
  Comments addressed: X
  Files changed: Y
  Verification: PASS | FAIL
  Pushed: yes | no

Round 2:
  New comments found: X
  ...

Remaining unresolved comments: N
  - [COMMENT_ID] <path>:<line> — <first 80 chars of comment body>
    Reason not addressed: <architectural decision / needs human review / etc.>
```

---

## Hard Rules

- **Never force-push** unless the branch is explicitly configured for it
- **Never commit with failing lint, type checks, build, or tests**
- **Never silently skip a comment** — always reply explaining the decision
- **Never modify files outside the scope of the review comments** — no opportunistic refactors
- **Never exceed 3 rounds** — stop and surface remaining items to the developer
- Stack-specific hard rules are defined in each stack module — treat them as equal in weight to these
