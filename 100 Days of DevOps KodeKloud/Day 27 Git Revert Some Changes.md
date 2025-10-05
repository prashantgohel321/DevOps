# DevOps Day 27: Safely Undoing Changes with `git revert`

Today's task was about a critical real-world scenario that every developer and DevOps engineer faces: a bad commit has been pushed to a shared repository, and we need to undo it. This was a fantastic lesson in how to handle mistakes safely without rewriting the project's history.

I learned about the `git revert` command, which is the standard, professional way to undo changes on a collaborative branch. The most valuable part was understanding the crucial difference between `git revert` and its more dangerous cousin, `git reset`. This document is my detailed, first-person guide to that entire process.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: The Critical Difference - `git revert` vs. `git reset`](#deep-dive-the-critical-difference---git-revert-vs-git-reset)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands Used](#exploring-the-commands-used)

---

### The Task
<a name="the-task"></a>
My objective was to undo the most recent commit in a Git repository located on the **Storage Server**. The specific requirements were:
1.  Work within the `/usr/src/kodekloudrepos/news` Git repository.
2.  Revert the latest commit (referred to as `HEAD`) to the state of the previous commit.
3.  The new "revert" commit must have the exact commit message: `revert news`.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The process involved investigating the repository's history and then carefully using the `git revert` command to create a new commit that undid the previous one. As the repository was in a `root`-owned directory, all commands required `sudo`.

#### Phase 1: Investigation
1.  I connected to the Storage Server (`ssh natasha@ststor01`) and navigated to the repository (`cd /usr/src/kodekloudrepos/news`).
2.  I used `git log` to view the commit history. This was a crucial first step to understand the current state of the repository.
    ```bash
    sudo git log --oneline
    ```
    The output showed the most recent commit at the top, which was the one I needed to revert.

#### Phase 2: The Revert and Commit
To ensure I used the exact commit message required by the task, I used a two-step process.
1.  **Perform the revert without committing:** I used the `--no-commit` flag. This flag tells Git to undo the changes in the files and stage them, but to wait for me to create the commit manually. `HEAD` is a pointer that always refers to the latest commit on the current branch.
    ```bash
    sudo git revert --no-commit HEAD
    ```
2.  **Create the custom commit:** With the changes staged, I could now create a new commit with my custom message.
    ```bash
    sudo git commit -m "revert news"
    ```

#### Phase 3: Verification
The final and most important step was to confirm that the history was now correct.
1.  I ran `git log` again.
    ```bash
    sudo git log --oneline
    ```
2.  The output now showed my new **`revert news`** commit at the very top of the history. This was the definitive proof that I had successfully and safely undone the previous commit.
    ```
    a1b2c3d (HEAD -> master) revert news
    f9e8d7c Some recent bad changes
    c4b5a6e initial commit
    ```

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **`git revert`**: This is the key command for this task. It is the **safe, non-destructive** way to undo a commit that has already been shared with others. It doesn't delete history. Instead, it creates a **new commit** that contains the inverse of the changes from the commit you are reverting. If the bad commit added a line of code, the revert commit will remove that same line.
-   **Preserving History**: In collaborative projects, the shared commit history is a sacred record of what has happened. Deleting or rewriting that history can cause massive problems for other team members who have already based their work on it. `git revert` is the standard because it preserves this history by simply adding a new entry that says, "Oops, we are undoing the last thing we did."
-   **`HEAD`**: This is a special pointer in Git that always points to the most recent commit on your currently checked-out branch. Using `git revert HEAD` is a convenient shortcut for "revert the very last thing that happened."

---

### Deep Dive: The Critical Difference - `git revert` vs. `git reset`
<a name="deep-dive-the-critical-difference---git-revert-vs-git-reset"></a>
This task perfectly illustrates why understanding the difference between `revert` and `reset` is one of the most important safety lessons in Git.

[Image of a git revert vs. git reset diagram]

-   **`git revert` (Safe for Public/Shared Branches):**
    -   **How it works:** It creates a *new* commit that undoes the changes of a previous commit.
    -   **History:** The original "bad" commit remains in the project's history, and a new "revert" commit is added after it. The timeline moves forward.
    -   **Collaboration:** This is safe for shared branches (`master`, `main`, etc.) because it doesn't change the existing history. Other developers can simply `git pull` the new revert commit to get their local copies back in sync.

-   **`git reset` (Dangerous for Public/Shared Branches):**
    -   **How it works:** It **deletes** commits. It moves the branch pointer backward in time, effectively erasing the commits that came after that point.
    -   **History:** The "bad" commit is removed from the branch's history as if it never happened. The timeline is rewritten.
    -   **Collaboration:** This is **extremely dangerous** on a shared branch. If another developer has already pulled the "bad" commit, and you then delete it with `reset`, the project history has now diverged. When they try to pull again, they will get a major conflict that is very difficult for beginners to resolve. `git reset` should only be used on your own **private, local branches** before you have pushed them and shared them with anyone else.

**The Golden Rule I learned:** If the commit is on a shared branch, always use `git revert`.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Using `git reset` on a Shared Branch:** This is the most dangerous and common mistake. It will achieve the desired code state locally but will cause major problems for the rest of the team.
-   **Forgetting `sudo`:** In this specific lab environment, the repository was owned by `root`. Forgetting to use `sudo` for the `git revert` and `git commit` commands would have resulted in a "Permission denied" error.
-   **Reverting the Wrong Commit:** If I hadn't checked the `git log` first, I might have reverted the wrong commit by mistake. Always investigate before making changes to the history.
-   **Not Using `--no-commit`:** If I had just run `git revert HEAD`, Git would have opened a text editor for me to enter a commit message. By using `--no-commit` and then `git commit -m "..."`, I was able to specify the exact commit message required by the task directly on the command line.

---

### Exploring the Commands Used
<a name="exploring-the-commands-used"></a>
-   `sudo git log --oneline`: A command to view the commit history.
    -   `log`: Shows the commit log.
    -   `--oneline`: A very useful flag that condenses the output, showing each commit on a single line with its hash and message.
-   `sudo git revert --no-commit HEAD`: The main command to undo changes.
    -   `revert`: The subcommand to create a new commit that is the inverse of a previous commit.
    -   `--no-commit`: A flag that tells Git to perform the revert in the working directory and staging area, but to wait for the user to create the final commit manually.
    -   `HEAD`: A pointer to the most recent commit on the current branch.
-   `sudo git commit -m "revert news"`: The standard command to create a commit with a specific **m**essage. I used this to finalize the revert operation with the custom message required by the task.
  