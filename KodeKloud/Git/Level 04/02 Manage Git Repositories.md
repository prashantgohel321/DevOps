# Git Level 04 Day 02: Repository Initialization and Controlled Branch Workflow

This document explains how a new Git repository was created in Gitea, initialized with existing project data, and extended through a feature branch that corrected a content issue. The objective was not only to execute Git commands but to follow a structured workflow that reflects how real development teams manage repositories, branches, and fixes.

The scenario involves a developer named `max`, who requires a repository named `story_ecommerce`, populated with existing source content, followed by the creation of a feature branch called `max_demo` where a typo is corrected and pushed independently from the main branch.

---

<br>
<br>

- [Git Level 04 Day 02: Repository Initialization and Controlled Branch Workflow](#git-level-04-day-02-repository-initialization-and-controlled-branch-workflow)
  - [Understanding the Objective in Workflow Terms](#understanding-the-objective-in-workflow-terms)
  - [Phase 1: Creating the Remote Repository in Gitea](#phase-1-creating-the-remote-repository-in-gitea)
  - [Phase 2: Cloning and Initializing the Master Branch](#phase-2-cloning-and-initializing-the-master-branch)
  - [Phase 3: Creating a Feature Branch and Correcting the Typo](#phase-3-creating-a-feature-branch-and-correcting-the-typo)
  - [Internal Git Behavior in This Workflow](#internal-git-behavior-in-this-workflow)
  - [Verification and Final State](#verification-and-final-state)

<br>
<br>

## Understanding the Objective in Workflow Terms

The task can be divided into three logical phases.

First, create a remote repository. This establishes the authoritative source of truth where collaborators can push and pull changes.

Second, clone that repository locally and populate the default branch with existing project data. This forms the initial project history.

Third, create a feature branch where changes are isolated, tested, and pushed without disturbing the stable branch.

This sequence mirrors how professional Git workflows operate in production environments.

---

<br>
<br>

## Phase 1: Creating the Remote Repository in Gitea

Log into the Gitea web interface using the credentials provided for `max`. Inside the dashboard, create a new repository named `story_ecommerce`.

The repository must be created empty. Initializing it with a README or any file would create a conflict when pushing local data if histories do not match.

After creation, copy the HTTP clone URL. This URL defines the remote endpoint that Git will use for pushing and pulling data.

---

<br>
<br>

## Phase 2: Cloning and Initializing the Master Branch

Move to the storage server where the project data resides.

```bash
ssh max@ststor01
```

Navigate to the home directory and clone the repository.

```bash
cd /home/max
git clone http://git.stratos.xfusioncorp.com/max/story_ecommerce.git
cd story_ecommerce
```

The `git clone` command does more than copy files. It creates a local working directory, initializes a `.git` folder to track version history, and automatically configures a remote named `origin` pointing to the Gitea server.

At this stage, the repository is empty locally because the remote contains no commits.

Copy the project data into the repository directory.

```bash
cp -r /usr/devops/* .
```

Before committing, ensure Git identity is configured. Without this, commits may fail or be unattributed.

```bash
git config user.email "max@stratos.xfusioncorp.com"
git config user.name "max"
```

Stage all files for tracking.

```bash
git add .
```

The staging step does not create a commit. It simply marks which files should be included in the next snapshot.

Create the initial commit.

```bash
git commit -m "add stories"
```

A commit records the state of the repository at that moment and links it to a commit message for traceability.

Push the commit to the remote repository.

```bash
git push origin master
```

The command pushes the local `master` branch to the remote named `origin`. After this step, the repository on Gitea contains the initial project state.

---

<br>
<br>

## Phase 3: Creating a Feature Branch and Correcting the Typo

Development best practice avoids committing changes directly to the main branch. Instead, a new branch is created for modifications.

Create and switch to the new branch.

```bash
git checkout -b max_demo
```

This command creates a branch called `max_demo` based on the current state of `master` and immediately switches the working directory to it.

Copy the file that contains the typo.

```bash
cp /tmp/stories/story-index-max.txt .
```

Correct the typo using a stream editor.

```bash
sed -i 's/Mooose/Mouse/g' story-index-max.txt
```

Verify that the correction was applied.

```bash
grep "Mouse" story-index-max.txt
```

Stage only the modified file.

```bash
git add story-index-max.txt
```

Commit the change with a meaningful message.

```bash
git commit -m "typo fixed for Mooose"
```

Push the new branch to the remote repository.

```bash
git push origin max_demo
```

The first time a branch is pushed, Git creates that branch on the remote server.

---

<br>
<br>

## Internal Git Behavior in This Workflow

When the initial commit was pushed, the remote repository gained its first commit object. That commit became the tip of the `master` branch.

When `max_demo` was created, Git did not duplicate the repository. It simply created a new branch pointer referencing the same commit history. When a new commit was added to `max_demo`, only that branch moved forward, while `master` remained unchanged.

This branching model allows parallel development without rewriting stable history.

---

<br>
<br>

## Verification and Final State

To verify branch existence locally:

```bash
git branch
```

To verify remote branches:

```bash
git branch -r
```

To confirm commit history graphically:

```bash
git log --oneline --graph --all
```

At completion:

* The repository `story_ecommerce` exists in Gitea
* The `master` branch contains initial project files
* The `max_demo` branch contains the typo correction
* Both branches are pushed to the remote server

This process establishes a clean separation between baseline content and feature-level changes, reflecting standard Git collaboration practices.
