# Linux Level 1, Task 3: Creating a Secure Non-Interactive User

Today's task was a deep dive into a fundamental Linux security practice: creating a "service account." The objective was to create a user for an application (a backup agent) that could own files and run processes but could not be used by a human to log into the server.

This was a fantastic lesson in the Principle of Least Privilege. I learned how to use the `useradd` command with the `-s` flag to assign a special non-interactive shell, effectively locking the account from interactive logins while keeping it functional for automated tasks. This document is my detailed, first-person guide to that entire process.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: Interactive vs. Non-Interactive Shells](#deep-dive-interactive-vs-non-interactive-shells)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands I Used](#exploring-the-commands-i-used)

---

### The Task
<a name="the-task"></a>
My objective was to create a secure service account on **App Server 1**. The specific requirements were:
1.  Create a user named `yousuf`.
2.  This user must be configured with a **non-interactive shell**.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The process was very efficient, involving a single command to create the user and another to verify the configuration.

#### Step 1: Connect to the Server
First, I needed to log into the correct server as a user with administrative privileges.
```bash
ssh tony@stapp01
```

#### Step 2: Create the Non-Interactive User
This was the core of the task. I used a single `useradd` command with the `-s` flag to specify the non-interactive shell.
```bash
sudo useradd yousuf -s /sbin/nologin
```

#### Step 3: Verification
The final and most important step was to confirm that the user was created with the correct shell. A failed login attempt is actually a sign of success here.
1.  **Check the `/etc/passwd` file:** This is the most direct way to verify. I used `grep` to find the user's entry.
    ```bash
    grep yousuf /etc/passwd
    ```
    The output was `yousuf:x:1001:1001::/home/yousuf:/sbin/nologin`. The final field, `/sbin/nologin`, was the definitive proof that I had set the shell correctly.

2.  **Attempt to Switch User:** I also tried to log in as the new user.
    ```bash
    su - yousuf
    ```
    The system correctly responded with `This account is currently not available.` This confirmed that the non-interactive shell was working as intended and blocking login attempts.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
-   **User Accounts**: In Linux, every file and process is owned by a user. Creating separate user accounts is the foundation of security and permission management.
-   **Service Accounts**: A "service account" is a special user created for a specific application or service (like a web server, a database, or a backup agent) to run under. This is a critical security practice. Instead of running the backup agent as the powerful `root` user, it runs as the limited `yousuf` user.
-   **Principle of Least Privilege**: This task is a perfect example of this principle. The `yousuf` account is given the minimum privileges it needs to do its job (own files, run a process) but is denied privileges it doesn't need (the ability for a human to log in). If an attacker were to exploit a vulnerability in the backup agent, they would be trapped in the context of the `yousuf` user, which has no shell and very limited power, dramatically reducing the potential damage.

---

### Deep Dive: Interactive vs. Non-Interactive Shells
<a name="deep-dive-interactive-vs-non-interactive-shells"></a>
This task was all about understanding the difference between the two types of shells in Linux.

[Image of an interactive vs non-interactive shell diagram]

-   **Interactive Shell (e.g., `/bin/bash`)**:
    -   **What it is:** This is the standard command-line interpreter that a human uses. When I log in via SSH, the system starts a `/bin/bash` process, which gives me a command prompt, lets me type commands, run scripts, and interact with the operating system.
    -   **Purpose:** Designed for human interaction.

-   **Non-Interactive Shell (e.g., `/sbin/nologin`)**:
    -   **What it is:** This is not really a "shell" in the traditional sense. It's a small program whose only job is to print a message (like "This account is not available") and then immediately exit, terminating the login attempt.
    -   **Purpose:** Designed for security. It provides a valid shell entry in the `/etc/passwd` file, making the user account valid for owning files and running background processes, but it makes it impossible for that user to ever get an interactive command prompt. This is the perfect shell for service accounts, daemons, and automated processes. Another common alternative is `/bin/false`, which does the same thing but without printing a message.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Forgetting the `-s` flag:** If I had just run `sudo useradd yousuf`, the system would have assigned the default interactive shell (usually `/bin/bash`), failing the primary requirement of the task.
-   **Forgetting `sudo`:** Creating users is an administrative task. Forgetting to use `sudo` would have resulted in a "Permission denied" error.
-   **Misinterpreting the Verification:** A beginner might try to `su - yousuf`, see the "account is not available" message, and think they made a mistake. For this task, that failure is the proof of success.

---

### Exploring the Commands I Used
<a name="exploring-the-commands-i-used"></a>
-   `sudo useradd yousuf -s /sbin/nologin`: The main command for this task.
    -   `useradd`: The command to add a new user.
    -   `-s /sbin/nologin`: The **s**hell flag. It sets the user's login shell to the specified path.
    -   `yousuf`: The name of the user to be created.
-   `grep yousuf /etc/passwd`: A standard command to search for lines containing "yousuf" within the `/etc/passwd` user database file. I used this to view the user's entry and verify their shell.
-   `su - yousuf`: The **s**ubstitute **u**ser command. It attempts to start a new login shell as the `yousuf` user. The `-` is a shortcut to simulate a full login, which includes loading the user's profile and changing to their home directory. The failure of this command was my second verification method.
  