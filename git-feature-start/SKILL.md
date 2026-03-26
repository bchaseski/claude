---
name: git-feature-start
description: >
  Start a new feature branch the right way. Use this skill whenever someone says
  "start a feature", "create a branch", "I want to work on something new", "begin
  a task", or anything that implies starting fresh work. Always use this skill
  before any new coding task — it ensures the user is on a clean, up-to-date
  branch instead of accidentally working on main.
---

# git-feature-start

Guides a newcomer through safely starting a new feature branch from an up-to-date main.

## Goal
Get the user onto a clean `feature/<description>` branch that is branched off the latest `main`, with zero risk of committing directly to main.

---

## Steps

### 1. Check current state
Run these and surface any issues before doing anything:
```bash
git status
git branch --show-current
```

- If there are **uncommitted changes**, stop and tell the user:
  > "You have unsaved changes. Let's checkpoint those first before starting a new feature."
  > Then invoke the `git-checkpoint` skill (or walk them through committing/stashing).
- If they are already **on a feature branch** (not `main`), confirm they really want a new branch.

### 2. Switch to main and pull latest
```bash
git checkout main
git pull origin main
```

If `git pull` has conflicts or errors, explain what happened in plain English and guide them to resolve it before continuing.

### 3. Ask for a feature description
Ask the user:
> "What's a short description of what you're building? (e.g. `user-profile-page`, `fix-login-bug`, `add-export-button`)"

Use their answer to form the branch name: `feature/<their-description>`
- Lowercase only
- Replace spaces with hyphens
- Remove special characters
- Keep it short (2–5 words ideal)

Show them the proposed branch name and confirm before creating it.

### 4. Create and switch to the branch
```bash
git checkout -b feature/<description>
```

### 5. Confirm success
Run:
```bash
git branch --show-current
```

Tell the user:
> "✅ You're now on `feature/<description>`, branched off the latest main. You're ready to start building!"

Remind them:
> "When you're ready to save your work, just say **'save my work'** or **'commit my changes'**."

---

## Error handling

| Situation | What to say |
|---|---|
| `git pull` fails with merge conflict | Explain the conflict in plain English; offer to walk through resolving it |
| Branch name already exists | Suggest appending `-v2` or ask them to pick a different name |
| Not in a git repo | Say: "This folder isn't a Git repo yet. Do you want me to initialize one, or should we navigate to the right project folder first?" |
| `main` doesn't exist (only `master`) | Silently use `master` instead |
