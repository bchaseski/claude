---
name: git-submit-pr
description: >
  Push the current branch and open a pull request on GitHub Enterprise using the
  GitHub CLI. Use this skill whenever someone says "submit a PR", "open a pull
  request", "create a PR", "request a review", "I'm done with my feature", or
  anything that implies they want their work reviewed by teammates. Always run
  git-checkpoint first if there are uncommitted changes.
---

# git-submit-pr

Guides a newcomer through pushing their branch and creating a pull request on
GitHub Enterprise — using `gh pr create` to handle everything automatically.

## Goal
Push the current feature branch to origin, then use the GitHub CLI to create a
well-described PR against `main`, ready for a teammate to review.

## Prerequisite
The `gh` CLI must be authenticated against your GitHub Enterprise instance:
```bash
gh auth status
```
If not authenticated, guide the user to run:
```bash
gh auth login --hostname <your-ghe-hostname>
```
(Replace `<your-ghe-hostname>` with your org's GHE host, e.g. `github.yourcompany.com`)

---

## Steps

### 1. Check for uncommitted changes
```bash
git status
```
If there are uncommitted changes, stop and say:
> "You have unsaved changes. Let me help you commit those before opening a PR."
Then invoke `git-checkpoint` before continuing.

### 2. Confirm current branch
```bash
git branch --show-current
```
If on `main`, stop and warn:
> "You're on `main` — PRs should come from a feature branch. Did you mean to work on a feature branch first?"

### 3. Check what's new vs main
```bash
git log main..HEAD --oneline
```
Summarize the commits in plain English:
> "You have 3 commits ready to submit: you added the export button, fixed a spacing bug, and updated the page title."

If there are **no commits ahead of main**, tell the user:
> "There's nothing new to submit — your branch has no changes beyond main yet."

### 4. Push the branch
```bash
git push origin HEAD
```
If the branch hasn't been pushed before, Git may suggest setting an upstream — run:
```bash
git push --set-upstream origin <branch-name>
```

### 5. Generate PR title and body
Use the commit log and diff to draft a PR description. Structure it as:

```
## What does this PR do?
<1–3 sentence plain-English summary of the change>

## Why?
<What problem does it solve or what value does it add?>

## How to test
<Simple steps a reviewer can follow to verify the change>

## Screenshots (if applicable)
<!-- Add any relevant screenshots here -->
```

Show the draft to the user and let them edit before submitting.

### 6. Create the PR with gh CLI
```bash
gh pr create \
  --title "<title>" \
  --body "<body>" \
  --base main
```

If the user's org requires specific reviewers, labels, or a PR template, mention:
> "Does your team have specific reviewers you should add? I can include them with `--reviewer username`."

### 7. Confirm and share the link
After creation, `gh` will return the PR URL. Show it to the user:
> "✅ PR submitted! Here's your link to share with your team: <url>"
> "Your teammates will be notified. You can continue making commits to this branch and they'll automatically appear in the PR."

---

## Error handling

| Situation | What to say |
|---|---|
| `gh` not installed | "The GitHub CLI isn't installed. Run `brew install gh` to get it, then `gh auth login --hostname <host>`." |
| Not authenticated | Walk through `gh auth login --hostname <your-ghe-hostname>` |
| Push rejected (not up to date) | Run `git pull --rebase origin main` first, then retry push |
| PR already exists for this branch | Say: "A PR is already open for this branch." Run `gh pr view --web` to open it |
| Protected branch rules fail | Explain the rule (e.g. "at least 1 reviewer required") and suggest adding one |
