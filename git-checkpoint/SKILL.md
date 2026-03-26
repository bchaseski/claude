---
name: git-checkpoint
description: >
  Save/commit the user's current work with a clear commit message. Use this skill
  whenever someone says "save my work", "commit my changes", "checkpoint", "save
  progress", "I want to save", or anything implying they want to record what
  they've done. Also trigger this skill proactively if the user is about to switch
  branches or start something new and has uncommitted changes.
---

# git-checkpoint

Helps a newcomer understand, review, and commit their current changes with a
meaningful commit message — without needing to know Git staging mechanics.

## Goal
Stage all changes, generate a clear commit message (with the user's input), and
commit — leaving the user with a clean working tree and a well-described history.

---

## Steps

### 1. Show what changed
Run:
```bash
git status
git diff --stat
```

Summarize the changes in plain English before showing raw output. For example:
> "You've modified 3 files: `LoginPage.jsx`, `styles.css`, and `api/auth.js`. Here's what changed..."

If there is **nothing to commit**, tell the user:
> "Your working tree is clean — there's nothing new to save right now."
> Then stop.

### 2. Review significant changes (optional but helpful)
For any modified files, offer a quick summary:
```bash
git diff
```
Don't dump the raw diff at the user. Instead, translate it:
> "In `LoginPage.jsx` you added a new button and changed the form validation logic."

### 3. Craft a commit message
Ask the user:
> "In one sentence, what did you do? (e.g. 'Added export button to the dashboard')"

Use their answer to write a commit message following this format:
```
<short imperative summary under 72 chars>

- <key change 1>
- <key change 2>
```

Show the message to the user and let them approve or tweak it before committing.

Good commit message examples:
- `Add export button to dashboard`
- `Fix login redirect after password reset`
- `Update nav styles for mobile`

Bad (avoid):
- `changes` / `wip` / `stuff`
- Messages longer than 72 chars on the first line

### 4. Stage and commit
```bash
git add -A
git commit -m "<message>"
```

### 5. Confirm success
```bash
git log --oneline -3
```

Tell the user:
> "✅ Saved! Your commit is: `<message>`"
> "When you're ready to share this with the team, say **'submit a PR'** or **'open a pull request'**."

---

## Error handling

| Situation | What to say |
|---|---|
| Not on a feature branch (on `main`) | Warn: "You're on `main` — it's safer to commit on a feature branch. Want me to move your changes to one?" |
| Commit hooks fail (e.g. lint errors) | Show the error output, explain what it means, and suggest how to fix it |
| Merge conflict markers in files | Explain what a conflict is and offer to walk through resolving it |
| Empty commit attempted | Say: "There's nothing staged to commit." and re-check status |
