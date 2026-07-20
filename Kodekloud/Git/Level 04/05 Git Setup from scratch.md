# Git Level 04 Day 05: Setting Up a Central Git Repository with Master Branch Protection

This document explains how a Git environment was configured from scratch on a storage server, including installation, creation of a bare repository, configuration of a server-side protection hook, and validation of controlled branch behavior. The objective was not just to initialize Git, but to enforce policy: the `master` branch must not accept direct pushes, while feature branches should function normally.

The setup uses `/opt/media.git` as the central bare repository and `/usr/src/kodekloudrepos/media` as the developer working directory.

---
<br>
<br>

- [Git Level 04 Day 05: Setting Up a Central Git Repository with Master Branch Protection](#git-level-04-day-05-setting-up-a-central-git-repository-with-master-branch-protection)
  - [Understanding the Overall Architecture Before Implementation](#understanding-the-overall-architecture-before-implementation)
  - [Step 1: Install Git and Configure Global Identity](#step-1-install-git-and-configure-global-identity)
  - [Step 2: Create the Central Bare Repository](#step-2-create-the-central-bare-repository)
  - [Step 3: Configure the update Hook to Protect master](#step-3-configure-the-update-hook-to-protect-master)
  - [Step 4: Clone the Repository as a Developer](#step-4-clone-the-repository-as-a-developer)
  - [Step 5: Add Content and Push the Feature Branch](#step-5-add-content-and-push-the-feature-branch)
  - [Step 6: Verify Protection of master Branch](#step-6-verify-protection-of-master-branch)
  - [Internal Behavior of the update Hook](#internal-behavior-of-the-update-hook)
  - [Why This Setup Matters in Real Environments](#why-this-setup-matters-in-real-environments)
  - [Final State of the Environment](#final-state-of-the-environment)


<br>
<br>

## Understanding the Overall Architecture Before Implementation

A central Git repository used for collaboration is typically created as a bare repository. A bare repository stores Git objects, references, and hooks, but it does not contain a working directory. Developers clone it to create editable working copies.

Branch protection in this setup is implemented using a server-side hook named `update`. Unlike `post-update`, the `update` hook runs before a reference is updated. If the hook exits with a non-zero status code, Git rejects the push. This allows enforcement of strict branch control policies at the server level.

---

<br>
<br>

## Step 1: Install Git and Configure Global Identity

Log in to the storage server.

```bash
ssh natasha@ststor01
```

Install Git if it is not already available.

```bash
sudo yum install git -y
```

Configure global identity for commits.

```bash
git config --global user.email "natasha@xfusioncorp.com"
git config --global user.name "Natasha"
```

Global configuration ensures that all repositories created under this user have consistent author metadata.

---

<br>
<br>

## Step 2: Create the Central Bare Repository

Create the repository directory and initialize it in bare mode.

```bash
sudo mkdir -p /opt/media.git
cd /opt/media.git
sudo git init --bare
```

The `--bare` option ensures no working directory is created. This repository will only accept pushes and manage references.

Verify structure.

```bash
ls -l /opt/media.git
```

You should see directories such as `objects`, `refs`, and `hooks`.

---

<br>
<br>

## Step 3: Configure the update Hook to Protect master

Navigate to the hooks directory inside the bare repository.

```bash
cd /opt/media.git/hooks
```

Copy the pre-provided `update` hook script.

```bash
sudo cp /tmp/update /opt/media.git/hooks/update
sudo chmod +x /opt/media.git/hooks/update
```

The `update` hook is invoked once per reference being pushed. It receives three parameters:

* The reference name (e.g., `refs/heads/master`)
* The old commit SHA
* The new commit SHA

If the script exits with status code `1`, the push for that reference is rejected. Proper execution permission is mandatory. Without it, Git ignores the script silently.

---

## Step 4: Clone the Repository as a Developer

Prepare a working directory for development.

```bash
sudo mkdir -p /usr/src/kodekloudrepos
sudo chown -R natasha:natasha /usr/src/kodekloudrepos
```

Clone the bare repository.

```bash
cd /usr/src/kodekloudrepos
git clone /opt/media.git media
cd media
```

At this point, the repository is empty because no commits exist in the remote.

Create a new feature branch.

```bash
git checkout -b xfusioncorp_media
```

This branch will hold development changes instead of modifying `master` directly.

---

<br>
<br>

## Step 5: Add Content and Push the Feature Branch

Copy the required file into the repository.

```bash
cp /tmp/readme.md .
```

Stage and commit the file.

```bash
git add readme.md
git commit -m "Initial commit for xfusioncorp_media"
```

Push the feature branch to the remote.

```bash
git push origin xfusioncorp_media
```

This push succeeds because the hook logic blocks only the `master` branch.

---

## Step 6: Verify Protection of master Branch

Create a local master branch pointing to the same commit.

```bash
git branch master
```

Attempt to push master.

```bash
git push origin master
```

The push should fail with an error similar to:

```
remote: error: hook declined to update refs/heads/master
```

This confirms that the `update` hook correctly intercepts attempts to modify the protected branch.

---

<br>
<br>

## Internal Behavior of the update Hook

When `git push` is executed, the client sends commit objects to the remote repository. Before updating branch references, Git executes the `update` hook script for each branch being modified.

If the hook script evaluates the reference name and detects `refs/heads/master`, it returns a non-zero exit code. Git interprets this as a rejection and aborts the update for that branch.

Because hooks execute at the repository level, this protection cannot be bypassed by clients unless they gain direct access to the server filesystem.

---

<br>
<br>

## Why This Setup Matters in Real Environments

Protecting the main branch is a common production practice. Direct pushes to master are often prohibited to ensure:

* Code review through pull requests
* Automated testing before merging
* Controlled release workflows
* Prevention of accidental overwrites

Server-side hooks enforce these rules centrally, ensuring consistency across all developers regardless of local configuration.

---

<br>
<br>

## Final State of the Environment

At the end of this configuration:

* Git is installed and globally configured
* `/opt/media.git` exists as a bare central repository
* The `update` hook enforces master branch protection
* Feature branch `xfusioncorp_media` exists and is pushed successfully
* Direct pushes to `master` are rejected by policy

This environment demonstrates how Git can be configured not just for version control, but for controlled collaboration and policy enforcement at the infrastructure level.
