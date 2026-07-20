# Git Level 04 Day 04: Automating Release Tag Creation Using a Server-Side Hook

This document explains how a server-side Git hook was implemented to automatically generate release tags whenever changes are pushed to the `master` branch. The objective was to configure a `post-update` hook in a bare repository so that every successful push results in a tag formatted as `release-YYYY-MM-DD`.

Unlike previous tasks that focused on local Git workflows, this task shifts attention to the server side of Git. Instead of reacting to events before a commit or push happens, we configure behavior that executes after the remote repository has already accepted new changes.

The remote repository in this case is `/opt/games.git`, which functions as the central shared repository. The local working repository resides in `/usr/src/kodekloudrepos/games`.

---

<br>
<br>

- [Git Level 04 Day 04: Automating Release Tag Creation Using a Server-Side Hook](#git-level-04-day-04-automating-release-tag-creation-using-a-server-side-hook)
  - [Understanding the Architecture Before Implementation](#understanding-the-architecture-before-implementation)
  - [Step 1: Access the Server Hosting the Bare Repository](#step-1-access-the-server-hosting-the-bare-repository)
  - [Step 2: Create the post-update Hook Script](#step-2-create-the-post-update-hook-script)
  - [Step 3: Make the Hook Executable](#step-3-make-the-hook-executable)
  - [Step 4: Trigger the Hook from the Local Repository](#step-4-trigger-the-hook-from-the-local-repository)
  - [Step 5: Verify That the Tag Exists](#step-5-verify-that-the-tag-exists)
  - [Internal Behavior of Server-Side Hooks](#internal-behavior-of-server-side-hooks)
  - [Limitations and Considerations](#limitations-and-considerations)
  - [Practical Use of Server-Side Hooks](#practical-use-of-server-side-hooks)
  - [Result of This Configuration](#result-of-this-configuration)


<br>
<br>

## Understanding the Architecture Before Implementation

In Git, a repository used as a central remote is typically a bare repository. A bare repository does not have a working directory. It stores only Git objects and references. When someone executes `git push`, the remote server updates its branch references directly.

Server-side hooks exist inside the `hooks/` directory of that bare repository. These scripts are executed automatically by Git when specific events occur.

The `post-update` hook runs after references have been updated successfully. It cannot reject a push because the update has already occurred. It is typically used for notification, synchronization, or automated post-processing actions such as deployments or tagging.

---

<br>
<br>

## Step 1: Access the Server Hosting the Bare Repository

The hook must be created directly on the server that hosts the central repository.

```bash
ssh natasha@ststor01
```

After logging in, navigate to the bare repository’s hooks directory.

```bash
cd /opt/games.git/hooks
```

At this location, several sample hook templates may already exist with the `.sample` extension.

---

<br>
<br>

## Step 2: Create the post-update Hook Script

Create a new file named `post-update`. The filename must exactly match the hook name for Git to execute it.

```bash
vi post-update
```

Insert the following script.

```bash
#!/bin/bash

DATE=$(date +%Y-%m-%d)

git tag "release-$DATE"

echo "Release tag release-$DATE created successfully."
```

The first line declares the script interpreter. This is required so the operating system knows how to execute the script.

The `date +%Y-%m-%d` command retrieves the current date in a structured format. This format ensures chronological ordering when listing tags.

The `git tag` command creates a lightweight tag referencing the current `HEAD` of the repository, which after a successful push corresponds to the latest commit on the updated branch.

Finally, the echo statement prints confirmation text. When pushing, this output appears prefixed with `remote:` in the client terminal.

---

## Step 3: Make the Hook Executable

Git will ignore the hook if it does not have execute permissions.

```bash
chmod +x post-update
```

Permission bits must allow execution for the repository owner. Without this step, the script will silently never run.

---

## Step 4: Trigger the Hook from the Local Repository

Now move to the local repository that tracks `/opt/games.git` as its remote.

```bash
cd /usr/src/kodekloudrepos/games
```

Ensure you are on the `master` branch.

```bash
git checkout master
```

Merge the feature branch into master.

```bash
git merge feature
```

After the merge completes successfully, push the updated master branch to the remote.

```bash
git push origin master
```

When this push reaches `/opt/games.git`, the bare repository updates its references. Immediately after the update, Git executes the `post-update` script.

You should observe output similar to:

```
remote: Release tag release-2023-XX-XX created successfully.
```

This indicates the hook was executed successfully.

---

<br>
<br>

## Step 5: Verify That the Tag Exists

Tags created on the remote repository can be fetched locally.

```bash
git fetch --tags
git tag
```

The list should contain a tag matching the current date in the `release-YYYY-MM-DD` format.

To verify directly on the server, you can also run:

```bash
cd /opt/games.git
git tag
```

---

<br>
<br>

## Internal Behavior of Server-Side Hooks

When `git push` executes, Git transmits commit objects and updates branch references on the remote server. After references such as `refs/heads/master` are updated, Git checks for executable hook scripts inside the `hooks/` directory.

If a file named `post-update` exists and is executable, Git invokes it automatically. The script runs in the context of the repository directory.

Because this is a bare repository, there is no working directory checkout. All actions must operate directly on Git objects and references.

---

<br>
<br>

## Limitations and Considerations

The provided script creates a lightweight tag without checking whether a tag for that date already exists. If multiple pushes occur on the same day, the command may fail due to duplicate tag names.

A more defensive implementation could check for existing tags before creating one.

Additionally, this hook does not restrict execution to the `master` branch explicitly. In practice, the hook receives reference arguments that can be inspected to ensure tags are only generated when `master` is updated.

---

<br>
<br>

## Practical Use of Server-Side Hooks

Server-side hooks are commonly used for:

* Automatic deployment after pushes
* CI/CD trigger integration
* Enforcing commit policies
* Logging or notification systems
* Automated tagging strategies

In this case, tagging acts as a simple release versioning mechanism tied to date-based milestones.

---

<br>
<br>

## Result of This Configuration

After implementation:

* Every push to the remote repository updates branch references
* The `post-update` hook executes automatically
* A date-based release tag is created
* The action is visible in push output

This setup demonstrates how Git can be extended beyond version control into automation and release management workflows.
