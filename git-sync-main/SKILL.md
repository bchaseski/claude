---
name: git-sync-main
description: >
  Sync the user's current branch with the latest changes from its base branch
  (e.g., main, stg, develop). Use this skill whenever someone says "sync with main",
  "sync with stg", "sync with develop", "sync with base branch", "pull latest",
  "get the latest changes", "update my branch", "I'm behind main", "I'm behind stg",
  "teammates pushed changes", or anything implying they want to incorporate recent
  work from the team. Also proactively suggest this skill if the user mentions merge
  conflicts or asks why their branch is out of date.
---

# git-sync-main

Safely brings the user's current feature branch up to date with its base branch —
handling stashing, rebasing, and conflict resolution in plain English.

## Goal
Incorporate the latest changes from the base branch into the user's current branch,
leaving them with an up-to-date branch and all their own work intact.

---

## Steps

### 1. Note current branch and status
```bash
git branch --show-current
git status
```

Save the current branch name — you'll need it throughout.

### 2. Detect the base branch

Determine which branch the current branch is based on by checking well-known base
branches on the remote and picking the one with the closest common ancestor:

```bash
CANDIDATES="main master develop stg staging"
EXISTING=""
for branch in $CANDIDATES; do
  if git rev-parse --verify "origin/$branch" >/dev/null 2>&1; then
    EXISTING="$EXISTING $branch"
  fi
done

BEST_BRANCH=""
BEST_COUNT=999999
for branch in $EXISTING; do
  MERGE_BASE=$(git merge-base HEAD "origin/$branch")
  COUNT=$(git rev-list --count "$MERGE_BASE..HEAD")
  if [ "$COUNT" -lt "$BEST_COUNT" ]; then
    BEST_COUNT=$COUNT
    BEST_BRANCH=$branch
  fi
done

echo "Detected base branch: $BEST_BRANCH"
```

Save the detected branch as `BASE_BRANCH` — use it in all commands and messages below.

Tell the user:
> "I detected that your branch is based on `<BASE_BRANCH>`. I'll sync with that."

If no candidate branches are found on the remote, ask the user:
> "I couldn't auto-detect your base branch. Which branch should I sync with?"

**Throughout the rest of these steps, `BASE_BRANCH` refers to the branch detected here.
Use it in place of a hardcoded branch name in all commands and messages.**

If the user is currently on `BASE_BRANCH` itself, just do a pull and stop:
```bash
git pull origin $BASE_BRANCH
```
> "You're on `<BASE_BRANCH>` and it's now up to date."

### 3. Handle uncommitted changes
If there are uncommitted changes, stash them temporarily:
```bash
git stash push -m "auto-stash before syncing with $BASE_BRANCH"
```
Tell the user:
> "I've temporarily set aside your in-progress changes so we can sync safely. I'll bring them back when we're done."

Track whether a stash was created (so we can restore it at the end).

### 4. Fetch latest from origin
```bash
git fetch origin $BASE_BRANCH
```

Show how far behind the branch is:
```bash
git log HEAD..origin/$BASE_BRANCH --oneline
```
Summarize:
> "There are 5 new commits on `<BASE_BRANCH>` from your teammates since you last synced."

If already up to date, say:
> "You're already in sync with `<BASE_BRANCH>` — nothing new to pull in."
Restore stash if one was created and stop.

### 5. Rebase onto latest base branch
Prefer rebase over merge to keep a clean history:
```bash
git rebase origin/$BASE_BRANCH
```

**If rebase succeeds cleanly:**
> "Your branch is now up to date with `<BASE_BRANCH>`. All your changes are preserved on top of the latest work."

**If there are conflicts**, go to the Conflict Resolution section below.

### 6. Restore stashed changes (if applicable)
If a stash was created in step 3:
```bash
git stash pop
```

If `stash pop` produces conflicts, walk through them the same way as rebase conflicts.

Tell the user:
> "Your in-progress work has been restored. You're fully synced and ready to keep going."

---

## Conflict Resolution

Conflicts happen when you and a teammate edited the same part of a file. This is normal — here's how to handle it.

### Identify conflicting files
```bash
git status
```
Files marked `both modified` have conflicts.

### Explain the conflict markers
Open the file and look for blocks like:
```
<<<<<<< HEAD
your version of the code
=======
teammate's version of the code
>>>>>>> origin/<BASE_BRANCH>
```

Tell the user in plain English:
> "In `LoginPage.jsx`, you and a teammate both changed the same section. You need to decide which version to keep (or combine them). I can help you look at both versions and decide."

### Walk through each conflict
For each conflicting file, show both versions side by side and ask:
> "Which version do you want to keep — yours, your teammate's, or a combination of both?"

Once decided, edit the file to remove the conflict markers and contain only the final version.

### Mark as resolved and continue
```bash
git add <resolved-file>
git rebase --continue
```

Repeat for each conflict. If the user gets overwhelmed:
> "It's totally okay to pause here and ask a teammate for help with this conflict — especially if you're not sure which version is correct. You can always run `git rebase --abort` to undo everything and get back to where you started."

Provide the abort escape hatch clearly:
```bash
git rebase --abort   # undoes everything, returns to original state
```

---

## Error handling

| Situation | What to say |
|---|---|
| Stash pop conflict after rebase | Walk through like a normal conflict; remind them it's their own in-progress work |
| Rebase with many conflicts | Suggest aborting and asking a teammate; don't force them through 10 conflicts alone |
| No internet / can't reach origin | "Can't reach the remote server. Are you connected to VPN?" |
| `rebase --continue` fails (nothing to commit) | Run `git rebase --skip` to skip the empty commit |
| No candidate base branches found on origin | Ask the user: "I couldn't auto-detect your base branch. Which branch should I sync with?" |
