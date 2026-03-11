# Understanding and Fixing Divergent Branch Push Errors in Git


## Scenario Overview

While working inside a repository, changes are staged and committed successfully. However, when attempting to push those commits to the remote repository, Git rejects the push with the following message:

```
! [rejected] main -> main (fetch first)
error: failed to push some refs
```

After attempting a `git pull`, another error appears:

```
fatal: Need to specify how to reconcile divergent branches.
```

This document explains why this happens, what Git is protecting you from, and how to resolve it properly using both rebase and merge strategies. It also explains why `git restore` failed in this context.

---

- [Understanding and Fixing Divergent Branch Push Errors in Git](#understanding-and-fixing-divergent-branch-push-errors-in-git)
  - [Scenario Overview](#scenario-overview)
- [What Actually Happened Internally](#what-actually-happened-internally)
  - [Step 1 — Local Commit Created](#step-1--local-commit-created)
  - [Step 2 — Push Attempt](#step-2--push-attempt)
- [Why Git Rejects the Push](#why-git-rejects-the-push)
- [Step 3 — Pull Attempt and the Second Error](#step-3--pull-attempt-and-the-second-error)
- [Solution 1 — Recommended: Rebase](#solution-1--recommended-rebase)
  - [What Rebase Does](#what-rebase-does)
  - [Execute:](#execute)
    - [What Happens Internally](#what-happens-internally)
  - [Handling Conflicts During Rebase](#handling-conflicts-during-rebase)
- [Solution 2 — Merge Instead of Rebase](#solution-2--merge-instead-of-rebase)
- [Setting a Default Behavior](#setting-a-default-behavior)
- [Why `git restore` Failed](#why-git-restore-failed)
- [Clean Workflow Recommendation](#clean-workflow-recommendation)
- [Core Concepts Explained Simply](#core-concepts-explained-simply)
  - [Fast-Forward](#fast-forward)
  - [Divergent Branches](#divergent-branches)
  - [Rebase](#rebase)
  - [Merge](#merge)
- [Final Summary](#final-summary)

<br>
<br>

# What Actually Happened Internally

## Step 1 — Local Commit Created

The following commands were executed:

```bash
git add .
git commit -m "Changed owner of 108.192 to prashant.gohel"
```

This created a new commit in the local `main` branch.

At this moment:

* Local `main` has one new commit.
* Remote `origin/main` may or may not have new commits.

<br>
<br>

## Step 2 — Push Attempt

```bash
git push origin main
```

Git rejected the push with:

```bash
(fetch first)
```

This means:
- The remote repository contains commits that your local repository does not have.

**Graphically, the situation looks like this:**

Remote main:

```bash

A --- B --- C

```

Local main:

```bash

A --- B --- D

```

The histories share a common ancestor (B), but both sides added new commits (C remotely, D locally).

This situation is called **divergent branches**.

---

<br>
<br>

# Why Git Rejects the Push

Git only allows a push if it can perform a *fast-forward* update.

**A fast-forward means:**

The remote branch tip is directly behind your local branch, like this:

Remote:

```bash

A --- B

```

Local:

```bash

A --- B --- C

```

In that case, Git simply moves the remote pointer forward to C.

But in a divergent case, fast-forward is impossible because both sides progressed independently.

Git blocks the push to prevent overwriting remote history.

---

<br>
<br>

# Step 3 — Pull Attempt and the Second Error

When running:

```bash
git pull origin main
```

Git responded with:

```bash
Need to specify how to reconcile divergent branches.
```

This happens because modern Git requires explicit instruction on how to combine histories when branches diverge.

There are two primary strategies:

1. Merge
2. Rebase

Git refuses to guess automatically.

---

<br>
<br>

# Solution 1 — Recommended: Rebase

## What Rebase Does

Rebase rewrites your local commits so that they appear on top of the latest remote commits.

Instead of creating a merge commit, it moves your commit forward.

## Execute:

```bash
git pull --rebase origin main
git push origin main
```

### What Happens Internally

1. Git fetches remote commits.
2. Temporarily removes your local commits.
3. Moves your branch to the remote tip.
4. Reapplies your commits one by one.

Graph becomes:

Remote:

```bash

A --- B --- C

```

After rebase:

```bash

A --- B --- C --- D

```

Now push works because it becomes a fast-forward.

---

<br>
<br>

## Handling Conflicts During Rebase

If a conflict occurs:

```bash
# Fix conflicting files manually

git add <resolved_file>

git rebase --continue
```

This continues applying remaining commits.

If you want to abort:

```bash
git rebase --abort
```

---

<br>
<br>

# Solution 2 — Merge Instead of Rebase

If you prefer not to rewrite commit history:

```bash
git pull --no-rebase origin main
git push origin main
```

This creates a merge commit.

Graph becomes:

```bash

A --- B --- C
\
D ----- M

```

Where `M` is the merge commit combining both histories.

This approach keeps history intact but adds an extra merge node.

---

<br>
<br>

# Setting a Default Behavior

If this error appears frequently, configure a default reconciliation strategy.

To always rebase when pulling:

```bash
git config --global pull.rebase true
```

To always merge:

```bash
git config --global pull.rebase false
```

To allow only fast-forward pulls (strict mode):

```bash
git config --global pull.ff only
```

This prevents accidental merge commits.

---

<br>
<br>

# Why `git restore` Failed

Command executed:

```bash
git restore
```

Error:

```
fatal: you must specify path(s) to restore
```

Explanation:

`git restore` operates on specific files. It requires a path.

Example usage:

```bash
git restore filename.txt
```

Additionally, `git status` showed:

```
nothing to commit, working tree clean
```

This confirms:

There were no uncommitted changes.

The problem was not in the working directory. It was in branch history divergence.

---

<br>
<br>

# Clean Workflow Recommendation

When working in shared repositories where multiple users push to `main`, follow this pattern:

```bash
git pull --rebase origin main
# make changes
git add .
git commit -m "message"
git push origin main
```

This ensures your local branch stays aligned before introducing new commits.

---

<br>
<br>

# Core Concepts Explained Simply

## Fast-Forward

Remote branch pointer moves forward without creating new commits.

## Divergent Branches

Both local and remote added commits independently.

## Rebase

Rewrites local commits to appear after remote commits.

## Merge

Combines two branch tips using a new merge commit.

---

<br>
<br>

# Final Summary

The push was rejected because:

* The remote branch had commits not present locally.
* Local and remote histories diverged.
* Git prevented overwriting history.

The clean fix is:

```bash
git pull --rebase origin main
git push origin main
```

This keeps history linear and avoids unnecessary merge commits.

Understanding this behavior removes confusion and allows predictable collaboration in shared repositories.
