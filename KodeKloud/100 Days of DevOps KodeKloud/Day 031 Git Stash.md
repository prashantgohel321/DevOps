# DevOps Day 31: Managing Work-in-Progress with `git stash`

Today's task was a fantastic lesson in a Git feature that is a true lifesaver for developers: the `git stash`. The scenario was very realistic: a developer had saved some unfinished work using the stash, and I needed to restore a specific set of those changes and make them a permanent part of the project's history.

I learned how to list the available stashes, how to apply a specific one using its identifier, and then how to take those restored changes through the standard `add`, `commit`, and `push` workflow. This document is my detailed, first-person guide to that entire process.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: The Stash Stack and `apply` vs. `pop`](#deep-dive-the-stash-stack-and-apply-vs-pop)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands I Used](#exploring-the-commands-i-used)

---

### The Task
<a name="the-task"></a>
My objective was to restore some specific, previously stashed work in a Git repository on the **Storage Server**. The requirements were:
1.  Work within the `/usr/src/kodekloudrepos/demo` Git repository.
2.  Find the list of available stashes.
3.  Restore the changes from the stash identified as `stash@{1}`.
4.  Commit the restored changes and push them to the `master` branch of the `origin` remote.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The process required me to first investigate the available stashes and then apply the correct one before committing the work. As the repository was in a `root`-owned directory, every command that modified the repository required `sudo`.

#### Phase 1: Investigation
1.  I connected to the Storage Server (`ssh natasha@ststor01`) and navigated to the repository (`cd /usr/src/kodekloudrepos/demo`).
2.  The first crucial step was to see what was in the stash.
    ```bash
    sudo git stash list
    ```
    The output showed me a list of the saved stashes, confirming that `stash@{1}` existed.

#### Phase 2: Restoring and Committing
1.  With the stash identified, I used the `git stash apply` command to restore the changes to my working directory.
    ```bash
    sudo git stash apply stash@{1}
    ```
    The command output listed the files that were modified, bringing the stashed changes back to life.

2.  The changes were now restored but uncommitted. I completed the standard workflow to save them permanently.
    ```bash
    # Stage all the changes that were just applied
    sudo git add .
    
    # Commit the changes with a clear message
    sudo git commit -m "Restore and commit changes from stash@{1}"
    
    # Push the new commit to the central server
    sudo git push origin master
    ```

#### Phase 3: Verification
The final step was to confirm that my new commit was now part of the project's official history.
1.  I ran `git log` to view the commit history.
    ```bash
    sudo git log --oneline
    ```
2.  The output now showed my new commit, "Restore and commit changes from stash@{1}", at the very top of the log. This was the definitive proof of success.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **`git stash`**: This is Git's mechanism for saving work that is not yet ready to be committed. It's a developer's best friend. The classic scenario is: I'm in the middle of a complex feature and my files are a mess. Suddenly, an urgent bug fix is needed on the `master` branch. I can't commit my messy work, and I can't switch branches because Git would complain about uncommitted changes. The solution is `git stash`.
-   **How it Works:** `git stash` takes all of my modified tracked files (both staged and unstaged changes) and saves them in a temporary, safe storage area called the "stash." It then cleans my working directory, reverting it back to the state of the last commit (`HEAD`). My directory is now clean, and I am free to switch branches and work on the urgent bug fix.
-   **Restoring Work:** Once I'm done with the bug fix, I can switch back to my feature branch and use `git stash apply` or `git stash pop` to bring all my unfinished work back into my working directory exactly as I left it.

---

### Deep Dive: The Stash Stack and `apply` vs. `pop`
<a name="deep-dive-the-stash-stack-and-apply-vs-pop"></a>
This task helped me understand two key concepts about the stash.

[Image of the git stash workflow]

1.  **The Stash is a Stack:** I can run `git stash` multiple times. Git stores these stashes in a **stack** (last-in, first-out).
    -   `stash@{0}`: The most recent set of changes I stashed.
    -   `stash@{1}`: The set of changes I stashed before that.
    -   `stash@{2}`: And so on.
    The `git stash list` command is essential for seeing what's in this stack and finding the correct identifier.

2.  **`git stash apply` (What I used):**
    -   **What it does:** This command re-applies the changes from a specified stash to my working directory.
    -   **Safety:** It **does not** remove the stash from the stack. The saved changes are still there in case I need them again or if applying them causes a conflict that I want to undo easily. This is the safer option.

3.  **`git stash pop` (The other option):**
    -   **What it does:** This command does two things at once: it **applies** the changes from the most recent stash (`stash@{0}`) and then immediately **deletes** that stash from the stack.
    -   **Use Case:** This is a convenient shortcut for the common workflow of stashing, switching branches, and then immediately returning to restore your work and continue. It's like "popping" the top item off the stack.

For my task, `apply` was the correct choice because the requirement was to restore a specific, older stash (`stash@{1}`), not just the most recent one.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Applying the Wrong Stash:** Without running `git stash list` first, it's easy to lose track of which stash contains which changes. Applying `stash@{0}` when I meant to apply `stash@{1}` would have restored the wrong work.
-   **Merge Conflicts:** If I had made other commits on my branch *after* stashing, it's possible that applying the stash could result in a merge conflict. Git would stop and ask me to resolve the overlapping changes manually before I could proceed.
-   **Forgetting to Commit:** A common mistake is to run `git stash apply` and then forget to run `git add .` and `git commit`. The changes are back in the working directory, but they are not saved in the project's history until they are committed.

---

### Exploring the Commands I Used
<a name="exploring-the-commands-i-used"></a>
-   `sudo git stash list`: Lists all the stashes that have been saved in the repository, showing their identifiers (e.g., `stash@{0}`) and the commit they were based on.
-   `sudo git stash apply stash@{1}`:
    -   `stash apply`: The subcommand to restore stashed changes.
    -   `stash@{1}`: The specific identifier for the stash I wanted to restore. If I had left this off, it would have applied the most recent stash (`stash@{0}`) by default.
-   `sudo git add .`: The standard command to stage all current changes in the working directory for the next commit.
-   `sudo git commit -m "..."`: The standard command to create a commit with a specific message.
-   `sudo git push origin master`: The standard command to push my new local commit to the `master` branch on the `origin` remote.
-   `sudo git log --oneline`: My verification command to view the commit history and confirm my new "Restore..." commit was at the top.
   