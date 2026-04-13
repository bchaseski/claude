---
name: git-resolve-conflicts
description: >
  Resolve Git merge conflicts interactively. Use this skill whenever someone says
  "resolve conflicts", "fix conflicts", "I have merge conflicts", "help with
  conflicts", "conflicting files", "conflict markers", or anything implying they
  are stuck on a Git conflict. Also proactively trigger this skill if you detect
  conflict markers (<<<<<<< / ======= / >>>>>>>) in files the user is working on,
  or if a git merge, rebase, cherry-pick, or stash pop just failed with conflicts.
---

# git-resolve-conflicts

Walks the user through resolving Git conflicts — regardless of whether they came
from a merge, rebase, cherry-pick, or stash pop — by explaining both sides in
plain English and letting the user decide what to keep.

## Goal
Resolve all conflicting files, complete the in-progress Git operation, and leave
the user with a clean working tree and no remaining conflict markers.

---

## Steps

### 1. Detect the conflict context
Determine what operation caused the conflicts:
```bash
git status
```

Check which operation is in progress:
- **Rebase**: `.git/rebase-merge/` or `.git/rebase-apply/` exists
- **Merge**: `.git/MERGE_HEAD` exists
- **Cherry-pick**: `.git/CHERRY_PICK_HEAD` exists
- **None of the above**: conflicts likely came from `git stash pop` or a manual edit

```bash
ls .git/rebase-merge .git/rebase-apply .git/MERGE_HEAD .git/CHERRY_PICK_HEAD 2>/dev/null
```

Tell the user what's happening:
> "You're in the middle of a **rebase** and hit a conflict. This means one of your
> commits changed the same code that was changed on the branch you're rebasing onto.
> Let's walk through it."

Adapt the wording for merge, cherry-pick, or stash pop accordingly.

### 2. List conflicting files
```bash
git diff --name-only --diff-filter=U
```

Summarize in plain English:
> "There are 2 files with conflicts: `src/api/auth.js` and `src/utils/format.ts`.
> Let's resolve them one at a time."

### 3. Walk through each conflicting file
For each file with conflicts:

#### a. Show the conflict
Read the file and locate the conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`).

Explain both sides in plain English — do **not** dump raw markers at the user:
> "In `src/api/auth.js`, there's a conflict in the `login` function:
> - **Your version** adds token refresh logic after login.
> - **The other version** changes the error handling to return a 401 instead of 403.
> These changes don't overlap logically — we can likely keep both."

#### b. Ask the user what to do
> "Which version do you want to keep?
> 1. **Yours** — keep your changes only
> 2. **Theirs** — keep the incoming changes only
> 3. **Both** — combine the changes (I'll merge them together)
> 4. **Custom** — tell me what you want and I'll write it"

#### c. Edit the file
Remove all conflict markers and write the resolved content based on the user's
choice. Ensure no `<<<<<<<`, `=======`, or `>>>>>>>` markers remain in the file.

#### d. Stage the resolved file
```bash
git add <resolved-file>
```

Confirm:
> "Resolved `src/api/auth.js`. Moving on to the next file."

Repeat for each conflicting file.

### 4. Verify no conflicts remain
```bash
git diff --name-only --diff-filter=U
```

If files still show conflicts, go back to step 3 for the remaining files.

### 5. Complete the operation
Once all conflicts are resolved, run the appropriate continue command based on
what was detected in step 1:

**Rebase:**
```bash
git rebase --continue
```
If the rebase has more commits to replay that also conflict, repeat from step 2.

**Merge:**
```bash
git commit --no-edit
```

**Cherry-pick:**
```bash
git cherry-pick --continue
```

**Stash pop (no in-progress operation):**
```bash
git commit -m "Resolve stash pop conflicts"
```
Ask the user if they want a different commit message.

### 6. Confirm success
```bash
git status
```

Tell the user:
> "All conflicts resolved. Your branch is clean and the **rebase** completed
> successfully. You're good to keep working."

Adapt the wording for the specific operation (merge, cherry-pick, etc.).

---

## Abort escape hatch

Always let the user know they can back out at any point. Before starting
resolution, and again if they seem unsure, tell them:

> "If you'd rather undo everything and go back to where you started, you can
> abort at any time."

Provide the right abort command based on the operation:

| Operation | Abort command |
|---|---|
| Rebase | `git rebase --abort` |
| Merge | `git merge --abort` |
| Cherry-pick | `git cherry-pick --abort` |
| Stash pop | `git checkout -- .` to discard conflict edits (stash stays in the stash list) |

---

## Error handling

| Situation | What to say |
|---|---|
| No conflicts found | "Your working tree looks clean — no conflicts to resolve right now." |
| User is unsure which version to keep | "If you're not sure, it's totally fine to ask the teammate who wrote the other change. You can also abort and come back to this later." |
| `rebase --continue` fails with "nothing to commit" | Run `git rebase --skip` — this commit became empty after resolution |
| Many conflicting files (>5) | "There are a lot of conflicts here. Want to resolve them one by one, or would you rather abort and try a different approach (like merging instead of rebasing)?" |
| Conflict markers remain after editing | Double-check the file for leftover markers and clean them up before staging |
| Operation continues but hits more conflicts | "The rebase hit another conflict on the next commit. Let's resolve this one too." Loop back to step 2 |
