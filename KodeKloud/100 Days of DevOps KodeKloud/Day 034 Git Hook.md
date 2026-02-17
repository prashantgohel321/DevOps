# DevOps Day 34: Automating Releases with Server-Side Git Hooks

Today's task was a deep dive into the powerful automation capabilities built directly into Git: **Hooks**. I was tasked with creating a server-side script that would automatically create a dated release tag every time a developer pushed changes to the `master` branch.

This was a fantastic, real-world task that showed me how to extend Git's default behavior to enforce team policies and automate release management. I learned the critical difference between a developer's cloned repository and the central "bare" repository, and why the hook script must live on the server. This document is my very detailed, first-person account of that entire process, from writing the hook script to triggering and verifying it.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: Anatomy of My `post-update` Hook Script](#deep-dive-anatomy-of-my-post-update-hook-script)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands I Used](#exploring-the-commands-i-used)

---

### The Task
<a name="the-task"></a>
My objective was to automate the creation of release tags in a Git repository on the **Storage Server**. The specific requirements were:
1.  First, merge the `feature` branch into the `master` branch in the cloned repository at `/usr/src/kodekloudrepos/ecommerce`.
2.  Create a **`post-update` Git hook** in the central bare repository (`/opt/ecommerce.git`).
3.  This hook script must automatically create a new tag named `release-YYYY-MM-DD` (using the current date) whenever a `push` to the `master` branch occurs.
4.  Finally, push the merged `master` branch to the remote to trigger the hook and verify that the tag was created.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The solution required a two-phase approach: first, setting up the automation on the server, and second, acting as a developer to trigger that automation. As the repositories were in `root`-owned directories, all commands required `sudo`.

#### Phase 1: Creating the Server-Side Git Hook
This was the most critical part, and it had to be done in the **bare repository**.
1.  I connected to the Storage Server (`ssh natasha@ststor01`).
2.  I navigated directly to the `hooks` directory inside the central bare repository. This is the only place server-side hooks will work.
    ```bash
    cd /opt/ecommerce.git/hooks
    ```
3.  I created a new file named `post-update` using `vi`.
    ```bash
    sudo vi post-update
    ```
4.  Inside the editor, I wrote a simple shell script to perform the required logic.
    ```bash
    #!/bin/sh
    
    # Check if the ref that was updated is the master branch
    if [ "$1" = "refs/heads/master" ]; then
      # Get today's date in YYYY-MM-DD format
      TODAY=$(date +%F)
      TAG_NAME="release-$TODAY"
      
      # Create an annotated tag on the master branch
      git tag -a "$TAG_NAME" -m "Release for $TODAY"
      
      echo "-------> Git Hook: Created release tag $TAG_NAME <-------"
    fi
    
    exit 0
    ```
5.  **Crucially, I made the hook script executable.** Git will not run a hook that doesn't have execute permissions.
    ```bash
    sudo chmod +x post-update
    ```

#### Phase 2: Triggering the Hook
With the automation in place, I now acted as a developer to trigger it.
1.  I navigated to the developer's cloned working repository.
    ```bash
    cd /usr/src/kodekloudrepos/ecommerce
    ```
2.  I merged the `feature` branch into `master` to create a change to push.
    ```bash
    sudo git checkout master
    sudo git merge feature
    ```
3.  I pushed the updated `master` branch to the remote server. This was the trigger event.
    ```bash
    sudo git push origin master
    ```
    In the output from the remote, I saw the `echo` message from my script: `remote: -------> Git Hook: Created release tag release-2025-09-29 <-------`. This was the first sign of success.

#### Phase 3: Verification
The tag was created on the remote server, but my local clone didn't know about it yet.
1.  I fetched the new tags from the remote.
    ```bash
    sudo git fetch origin --tags
    ```
2.  I listed the tags now known to my local repository.
    ```bash
    sudo git tag
    ```
    The output included my new, automatically created tag (e.g., `release-2025-09-29`). This was the definitive proof that my server-side hook worked perfectly.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **Git Hooks**: These are custom scripts that Git automatically executes at specific points in its workflow (e.g., before a commit, after a push). They are the built-in way to automate and enforce custom rules and actions within your development process.
-   **Server-Side vs. Client-Side Hooks**:
    -   **Client-Side:** Run on a developer's local machine (e.g., `pre-commit` to check for code linting). Developers can bypass these.
    -   **Server-Side:** Run on the central repository server (e.g., `pre-receive`, `post-update`). These are triggered by a `git push` and **cannot be bypassed** by the developer. This makes them perfect for enforcing team-wide policies, like running CI tests or, in my case, creating a release tag.
-   **The `post-update` Hook**: This specific hook runs on the server **after** a successful push has completed and all refs have been updated. It's ideal for "notification" or "post-processing" tasks like sending an email to the team, notifying a CI server, or, as I did, creating a release tag based on the new state of the repository.

---

### Deep Dive: Anatomy of My `post-update` Hook Script
<a name="deep-dive-anatomy-of-my-post-update-hook-script"></a>
The hook is just a simple shell script, but understanding how it works is key.

[Image of a Git hook being triggered by a push]

```bash
#!/bin/sh

# Git passes arguments to the hook script. For 'post-update', the arguments
# are the names of the refs that were updated by the push.
# This 'if' statement checks if the first argument ('$1') is the ref for the master branch.
# This ensures my script only runs when the 'master' branch is updated.
if [ "$1" = "refs/heads/master" ]; then
  
  # I use the standard Linux 'date' command with the '+%F' format string
  # to get the current date in a clean YYYY-MM-DD format.
  TODAY=$(date +%F)
  TAG_NAME="release-$TODAY"
  
  # This is the core action. I'm running a 'git tag' command.
  # Because this script runs *inside* the bare repository on the server,
  # it can execute git commands directly.
  # '-a' creates an annotated (full) tag, and '-m' provides a message.
  git tag -a "$TAG_NAME" -m "Release for $TODAY"
  
  # This 'echo' is important for feedback. Anything echoed from a server-side
  # hook is sent back to the developer's client in the 'git push' output.
  echo "-------> Git Hook: Created release tag $TAG_NAME <-------"
fi

# A hook should always exit with a status of 0 to indicate success.
exit 0
```

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Placing the Hook in the Wrong Repository:** The most common mistake is to place the hook script in the cloned working copy (`/usr/src/kodekloudrepos/ecommerce/hooks`). Server-side hooks **must** be placed in the bare repository (`/opt/ecommerce.git/hooks`).
-   **Forgetting to Make the Hook Executable:** A hook script is just a text file until you give it execute permissions with `sudo chmod +x post-update`. If you forget this step, Git will silently ignore the hook, and it will never run.
-   **Forgetting to Fetch Tags:** The tag is created on the remote server. A common point of confusion is to push the changes and then run `git tag` locally and not see the new tag. You must first run `sudo git fetch origin --tags` to download the new tag information to your local repository.

---

### Exploring the Commands I Used
<a name="exploring-the-commands-i-used"></a>
-   `sudo vi /opt/ecommerce.git/hooks/post-update`: The command to create and edit the hook script in the correct server-side location.
-   `sudo chmod +x post-update`: The critical command to make the hook script **ex**ecutable.
-   `sudo git merge feature`: The developer action to integrate the feature branch into master.
-   `sudo git push origin master`: The developer action that serves as the **trigger** for the `post-update` hook on the server.
-   `sudo git fetch origin --tags`: The command to download all new objects, including tags, from the remote server to the local repository.
-   `sudo git tag`: When run with no arguments, it lists all the tags that the local repository is aware of. I used this for my final verification.
  