# Maintaining a Subdirectory in Two Independent Git Repositories While Preserving Real Commit History

## Scenario Overview

Consider a situation where a large repository contains multiple learning tracks, notes, and structured content. Over time, one particular directory evolves into a substantial body of work and is extracted into its own dedicated repository using `git subtree split`. The extracted repository now lives independently and continues evolving.

At a later point, a new requirement emerges:

The extracted repository must continue evolving independently, but its content must also be reflected inside the original repository under a specific subdirectory. The update must:

* Touch only that subdirectory.
* Preserve full, real commit history.
* Avoid squashing commits.
* Avoid rewriting or corrupting existing unrelated history.
* Maintain a clean and future‑proof workflow.

This document explains the complete journey — including failed attempts — and the final clean architectural solution.

---

<br>
<br>

- [Maintaining a Subdirectory in Two Independent Git Repositories While Preserving Real Commit History](#maintaining-a-subdirectory-in-two-independent-git-repositories-while-preserving-real-commit-history)
  - [Scenario Overview](#scenario-overview)
  - [The Initial Architecture](#the-initial-architecture)
  - [The New Requirement](#the-new-requirement)
  - [Step 1 — Adding the Secondary Repository as a Remote](#step-1--adding-the-secondary-repository-as-a-remote)
    - [What `git remote add` Does](#what-git-remote-add-does)
    - [What `git fetch secondary` Does](#what-git-fetch-secondary-does)
  - [Step 2 — Attempting Subtree Pull](#step-2--attempting-subtree-pull)
    - [Failure: Refusing to Merge Unrelated Histories](#failure-refusing-to-merge-unrelated-histories)
    - [Why This Happened](#why-this-happened)
  - [Step 3 — Attempting Subtree Merge](#step-3--attempting-subtree-merge)
  - [Step 4 — Attempting Manual Graph Stitching](#step-4--attempting-manual-graph-stitching)
    - [Explanation of the Commands](#explanation-of-the-commands)
    - [Failure Encountered](#failure-encountered)
  - [Understanding the Core Conflict](#understanding-the-core-conflict)
  - [Final Clean Architectural Solution](#final-clean-architectural-solution)
  - [Step 1 — Remove the Existing Directory from the Primary Repository](#step-1--remove-the-existing-directory-from-the-primary-repository)
    - [What `git rm -r` Does](#what-git-rm--r-does)
  - [Step 2 — Add the Subtree Properly](#step-2--add-the-subtree-properly)
    - [What `git subtree add` Does](#what-git-subtree-add-does)
  - [Future Workflow](#future-workflow)
  - [Why This Solution Is Correct](#why-this-solution-is-correct)
  - [Key Lessons Learned](#key-lessons-learned)
  - [Final Architecture](#final-architecture)


<br>
<br>

## The Initial Architecture

There are two repositories:

1. A primary repository that contains many domains of content.
2. A secondary repository created earlier by extracting one directory using `git subtree split`.

When `git subtree split` was originally executed, Git performed an internal rewrite of history. It scanned the entire commit graph of the main repository, selected only the commits that modified the specified directory, and rebuilt them as if that directory had always been the repository root.

This is important.

The new repository does not share commit hashes with the original repository anymore. Although the content originated from the first repository, the commit graph has a new root. From Git’s perspective, they are unrelated histories.

This technical detail explains every failure encountered later.

---

<br>
<br>

## The New Requirement

The secondary repository becomes the source of truth. All new work is performed there.

Now the requirement is:

Synchronize its updates back into the primary repository under a specific subdirectory, without affecting anything else.

The instinctive attempt is to use `git subtree pull` inside the primary repository.

---

<br>
<br>

## Step 1 — Adding the Secondary Repository as a Remote

Inside the local clone of the primary repository:

```bash
git remote add secondary <repository-url>
git fetch secondary
```

### What `git remote add` Does

Every Git repository contains a configuration file at `.git/config`. Running `git remote add` inserts an entry describing another repository, including its fetch rules.

No data is downloaded at this stage.

### What `git fetch secondary` Does

`git fetch` connects to the remote repository, downloads commit objects (which include trees and blobs), and stores them in the local `.git/objects` database.

It also creates remote‑tracking branches such as:

```
secondary/main
```

Important: Fetch does not modify the working directory. It only updates the internal commit database.

---

<br>
<br>

## Step 2 — Attempting Subtree Pull

The next logical step:

```bash
git subtree pull --prefix=Subdirectory secondary main
```

### Failure: Refusing to Merge Unrelated Histories

Git produced:

```
fatal: refusing to merge unrelated histories
```

### Why This Happened

Git attempted to perform a merge operation between:

* The primary repository’s `main` branch
* `secondary/main`

Since the secondary repository was created using `git subtree split`, its commit graph does not share a common ancestor with the primary repository anymore. The histories are independent.

Git refuses such merges by default to prevent accidental data corruption.

---

<br>
<br>

## Step 3 — Attempting Subtree Merge

An alternative was attempted:

```bash
git subtree merge --prefix=Subdirectory secondary/main
```

The same error occurred.

This is because `git subtree` ultimately performs merge operations internally. Without an existing subtree relationship recorded in history, Git cannot reconcile the commit graphs.

---

<br>
<br>

## Step 4 — Attempting Manual Graph Stitching

A controlled approach was attempted:

1. Creating a temporary branch.
2. Performing a merge with `--allow-unrelated-histories`.
3. Manually reading the tree using `git read-tree` with a prefix.

Example commands used:

```bash
git checkout -b sync-branch

git merge --allow-unrelated-histories -s ours --no-commit secondary/main

git read-tree --prefix=Subdirectory/ -u secondary/main
```

### Explanation of the Commands

* `--allow-unrelated-histories` tells Git to permit merging branches without a shared ancestor.
* `-s ours` uses the "ours" merge strategy, which keeps the current branch's tree while recording the other branch as merged.
* `--no-commit` prevents an automatic commit, allowing manual control.
* `git read-tree` writes a tree object into the index under a specified directory prefix.

### Failure Encountered

An overlap error occurred because the target directory already existed in the primary repository. Git refused to overwrite tracked files.

This revealed a deeper architectural truth: the directory already existed with history, and we were trying to inject another unrelated history into the same path.

That approach leads to complex graph conflicts and fragile metadata.

---

<br>
<br>

## Understanding the Core Conflict

At this stage, the system had:

* The primary repository containing an older copy of the subdirectory.
* The secondary repository containing its rewritten history.

Trying to merge them directly forces Git to reconcile two independent histories occupying the same path.

This is not a clean architecture.

The correct approach must:

* Establish a formal subtree relationship.
* Avoid mixing two independent ownership lines for the same directory.

---

<br>
<br>

## Final Clean Architectural Solution

A decision must be made:

The secondary repository becomes the canonical source of truth.

The primary repository becomes a consumer of that subtree.

This leads to a clean reset process.

---

<br>
<br>

## Step 1 — Remove the Existing Directory from the Primary Repository

```bash
git checkout main

git rm -r Subdirectory

git commit -m "Remove old directory to reinitialize subtree relationship"

git push origin main
```

### What `git rm -r` Does

It removes the directory from version control and stages the removal.

The files are deleted in the working directory and marked for commit.

Once committed, the primary repository no longer tracks that directory.

Importantly, historical commits still contain the directory. Only the current state removes it.

---

<br>
<br>

## Step 2 — Add the Subtree Properly

Now that the path is clean:

```bash
git subtree add --prefix=Subdirectory secondary main

git push origin main
```

### What `git subtree add` Does

Internally, Git:

* Fetches the specified branch.
* Rewrites its tree so it lives under the given prefix.
* Creates a merge commit that records subtree metadata.

This metadata includes information that allows future subtree operations to understand how the histories relate.

Now the histories are formally connected.

---

<br>
<br>

## Future Workflow

From this point onward, updating becomes simple and repeatable.

```bash
git fetch secondary

git subtree pull --prefix=Subdirectory secondary main

git push origin main
```

No unrelated history errors.
No manual tree stitching.
No squash commits.

Each commit from the secondary repository is preserved with:

* Original author
* Original timestamp
* Full commit message

Only the target subdirectory is modified. The rest of the repository remains untouched.

---

<br>
<br>

## Why This Solution Is Correct

The final approach works because it establishes a single ownership model.

The secondary repository is the authoritative source.
The primary repository consumes it using a formally recorded subtree relationship.

By first removing the directory and then re-adding it as a subtree, we avoid overlapping trees and disconnected commit graphs.

This produces:

* Clean commit graph
* Real preserved history
* Predictable future updates
* No duplicated lineage

---

<br>
<br>

## Key Lessons Learned

1. `git subtree split` rewrites history and creates a new root.
2. Rewritten histories do not share ancestry with the original repository.
3. Subtree relationships must be established cleanly; they cannot be assumed.
4. Attempting to merge two independent histories into the same directory without resetting ownership leads to conflicts.
5. Removing the directory and reinitializing subtree is the cleanest long‑term strategy.

---

<br>
<br>

## Final Architecture

Secondary Repository (source of truth)
↓
Subtree pull
↓
Primary Repository /Subdirectory

One direction of synchronization.
One canonical history.
Clean maintenance model.

This design ensures long‑term stability without sacrificing commit authenticity or repository structure.
