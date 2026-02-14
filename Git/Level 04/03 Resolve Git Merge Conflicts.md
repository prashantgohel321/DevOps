# Git Level 04 Day 03: Resolving Merge Conflicts in a Shared Repository

This document explains how a merge conflict was resolved in a shared Git repository when two developers modified the same file. The objective was to synchronize a local repository with the remote `origin`, correctly merge both sets of changes, fix a typo, and ensure that the final file content was complete and consistent.

The developer `max` attempted to push changes to the `master` branch of the repository `story-blog`, but the push was rejected because another developer had already pushed conflicting updates. Understanding why this happens and how to resolve it correctly is central to collaborative Git workflows.

---

<br>
<br>

- [Git Level 04 Day 03: Resolving Merge Conflicts in a Shared Repository](#git-level-04-day-03-resolving-merge-conflicts-in-a-shared-repository)
  - [Understanding the Problem Before Running Commands](#understanding-the-problem-before-running-commands)
  - [Step 1: Inspect the Repository State](#step-1-inspect-the-repository-state)
  - [Step 2: Pull Remote Changes and Trigger the Conflict](#step-2-pull-remote-changes-and-trigger-the-conflict)
  - [Step 3: Examine and Resolve the Conflict Manually](#step-3-examine-and-resolve-the-conflict-manually)
  - [Step 4: Mark the Conflict as Resolved and Complete the Merge](#step-4-mark-the-conflict-as-resolved-and-complete-the-merge)
  - [Verifying the Merge Result](#verifying-the-merge-result)
  - [How Git Handles Conflicts Internally](#how-git-handles-conflicts-internally)
  - [Why This Matters in Real Projects](#why-this-matters-in-real-projects)


<br>
<br>

## Understanding the Problem Before Running Commands

When `max` tried to push changes, Git rejected the push. This rejection happens because the remote branch contains commits that are not present in the local branch. Git prevents overwriting history by default. It enforces a rule that local history must incorporate remote changes before a push is allowed.

In simple terms, Git detected that the local branch was behind the remote branch. To resolve this, the remote updates must be fetched and merged locally.

---

<br>
<br>

## Step 1: Inspect the Repository State

Log in to the storage server and move to the repository directory.

```bash
ssh max@ststor01

cd story-blog
```

Ensure Git identity is configured.

```bash
git config user.name "max"
git config user.email "max@stratos.xfusioncorp.com"
```

Attempting to push at this stage results in rejection.

```bash
git push origin master
```

The error `rejected (fetch first)` indicates the local repository lacks recent remote commits.

---

<br>
<br>

## Step 2: Pull Remote Changes and Trigger the Conflict

To synchronize, pull the remote branch.

```bash
git pull origin master
```

Internally, this command performs two operations in sequence. First, Git fetches remote objects and updates its reference to `origin/master`. Second, Git attempts to merge those remote changes into the local `master` branch.

Because both developers modified the same lines in `story-index.txt`, Git cannot automatically merge the changes. It marks the file as conflicted and stops the merge process.

The output indicates:

```
CONFLICT (content): Merge conflict in story-index.txt
Automatic merge failed; fix conflicts and then commit the result.
```

At this stage, the working directory contains conflict markers inserted by Git.

---

<br>
<br>

## Step 3: Examine and Resolve the Conflict Manually

Open the conflicted file.

```bash
vi story-index.txt
```

Inside the file, Git marks conflicting regions using three markers.

```
<<<<<<< HEAD
(local changes)
=======
(remote changes)
>>>>>>> commit_hash
```

The section above `=======` represents the local version. The section below represents the remote version. Git cannot decide which content should remain.

Resolving the conflict involves three actions.

First, remove the conflict markers themselves.

Second, combine the meaningful content from both versions so that all four story titles are present in the file.

Third, correct the typo by changing "Mooose" to "Mouse".

The final content must contain the complete set of required stories and be typo-free. Once editing is complete, save the file.

---

<br>
<br>

## Step 4: Mark the Conflict as Resolved and Complete the Merge

After manually resolving the file, stage it.

```bash
git add story-index.txt
```

This staging step signals to Git that the conflict has been resolved.

Commit the merge.

```bash
git commit -m "Merge remote changes and fix typo in story title"
```

This commit creates a merge commit. A merge commit has two parents: one from the local branch and one from the remote branch. It represents the point where histories converge.

Finally, push the updated branch to the remote repository.

```bash
git push origin master
```

Because the local branch now includes remote history, the push succeeds.

---

<br>
<br>

## Verifying the Merge Result

To inspect commit history visually:

```bash
git log --oneline --graph
```

You should see a merge commit joining two lines of development history.

To verify file content:

```bash
cat story-index.txt
```

Ensure that all four story titles are present and that the typo has been corrected.

---

<br>
<br>

## How Git Handles Conflicts Internally

When two branches modify the same lines in a file, Git performs a three-way merge. It compares:

* The common ancestor version
* The local branch version
* The remote branch version

If the same lines were modified differently in both branches, Git cannot choose safely. Instead of guessing, it stops and inserts markers, leaving the decision to the developer.

Only after conflicts are resolved and staged does Git allow the merge to be finalized.

---

<br>
<br>

## Why This Matters in Real Projects

Merge conflicts are not errors. They are signals that collaborative changes overlap. Resolving them carefully ensures that important work is not accidentally discarded.

Best practice in collaborative development includes pulling changes frequently, communicating about shared files, and reviewing differences before committing major edits.

Understanding how conflicts occur and how to resolve them confidently is essential for working in shared repositories at any scale.
