# DevOps Day 01: Creating a User with a Non-Interactive Shell

This document explains a very common real-world DevOps task: creating a Linux user account that is not meant for human login. The task looks small, but it touches core ideas of Linux security, automation, and how operating systems control access. This kind of user is typically created for background services, agents, and automated tools rather than for people.

The scenario here involves creating a user named `james` on an application server for a backup agent. Since a backup agent runs automatically and does not require a human to type commands, the user must exist without allowing interactive login.

---

<br>
<br>

- [DevOps Day 01: Creating a User with a Non-Interactive Shell](#devops-day-01-creating-a-user-with-a-non-interactive-shell)
  - [The Actual Requirement](#the-actual-requirement)
  - [The Command Used and Why It Solves the Task](#the-command-used-and-why-it-solves-the-task)
  - [Verifying That the User Exists and Is Restricted](#verifying-that-the-user-exists-and-is-restricted)
  - [Why This Approach Is Used in Real Systems](#why-this-approach-is-used-in-real-systems)
  - [How Non-Interactive Shells Work Internally](#how-non-interactive-shells-work-internally)
  - [Files and Directories Involved in This Process](#files-and-directories-involved-in-this-process)
  - [Additional Commands to Explore and Learn More](#additional-commands-to-explore-and-learn-more)
  - [Key Takeaway](#key-takeaway)


<br>
<br>

## The Actual Requirement

The system administration team required a user called `james` to be present on App Server 1. This user would be used by a backup agent process. From a security perspective, allowing someone to log in as this user and obtain a shell prompt would be unnecessary and risky. Therefore, the user must exist in the system but must not be able to start a shell session.

This requirement directly maps to how Linux controls user access using login shells.

---

<br>
<br>

## The Command Used and Why It Solves the Task

After connecting to the server using SSH with administrative access, a single command was sufficient to both create the user and restrict its login behavior.

```bash
sudo useradd james -s /sbin/nologin
```

This command works because `useradd` is responsible for registering new users in the system’s user database, and the `-s` option allows control over which program is executed when that user attempts to log in.

The word `sudo` temporarily grants administrative privileges. User creation modifies system files such as `/etc/passwd`, which are protected and cannot be changed by normal users. Without sudo, the command would fail.

The `useradd` utility creates a new user entry, assigns a user ID, group ID, home directory, and default settings unless told otherwise.

The name `james` becomes the login identifier for the account.

The `-s` option specifies the **login shell**. A **login shell** is not just a preference; it is the exact program the system runs after authentication succeeds. By setting this shell to `/sbin/nologin`, the system is instructed to deny any interactive session immediately after authentication.

The program `/sbin/nologin` is a small system binary whose only job is to print a message and terminate the session. No prompt is shown and no commands can be executed.

---

<br>
<br>

## Verifying That the User Exists and Is Restricted

After creating the user, the safest way to confirm the result is to inspect the system’s user database indirectly.

```bash
grep 'james' /etc/passwd

# OUTPUT:
# james:x:1002:1002::/home/james:/sbin/nologin
```

The `grep` command scans text files and prints lines that match a given string. Here, it searches for any line containing the word `james`.

The file `/etc/passwd` stores one line per user account. Each line is structured using colon separators. Reading the output from left to right shows the username, internal identifiers, the home directory path, and finally the login shell.

The presence of `/sbin/nologin` at the end of the line confirms that the user cannot obtain an interactive shell.

---

<br>
<br>

## Why This Approach Is Used in Real Systems

This task is a direct application of the principle of least privilege. A system account should have only the permissions required to perform its function and nothing more.

A backup agent needs file ownership, read access, and sometimes execution permission to run scheduled jobs. It does not need a human-operated terminal session. Allowing interactive login would expand the attack surface of the server.

In DevOps environments, many tools rely on similar users. Continuous integration servers, container runtimes, monitoring agents, and schedulers often run under dedicated users that exist purely so processes have an identity. These users are designed for automation, not for people.

Restricting the shell reduces risk while still allowing the system to operate normally.

---

<br>
<br>

## How Non-Interactive Shells Work Internally

When a user attempts to log in, Linux does not automatically start a command prompt. Instead, it checks the user’s entry in `/etc/passwd` to determine which program should run after authentication.

For a normal human user, this program is usually `/bin/bash` or another shell. Bash starts, prints a prompt, and waits for commands. This is known as an interactive shell because it is designed for continuous back-and-forth interaction.

For the `james` user, the system finds `/sbin/nologin` as the login shell. After authentication, the system executes this program instead of bash. The program displays a short message indicating that the account is not available and then exits. Because the program exits immediately, the session ends without ever reaching a command prompt.

From the operating system’s perspective, this behavior is intentional and clean. Authentication succeeds, but interaction is deliberately blocked.

---

<br>
<br>

## Files and Directories Involved in This Process

The file `/etc/passwd` is a foundational system file that lists all user accounts. It does not store passwords but defines how each user is identified and which shell they are allowed to run.

The directory `/home/james` is the home directory assigned to the user. Even though the user cannot log in interactively, processes running as this user may still read from or write to this directory. Backup tools often store configuration or runtime data here.

The directory `/sbin` contains essential system binaries. Programs located here are usually intended for administrative or system-level tasks. The placement of `nologin` in this directory signals that it is part of core system control rather than a regular user utility.

---

<br>
<br>

## Additional Commands to Explore and Learn More

To confirm whether a user can log in interactively, you can inspect the shell field directly:

```bash
getent passwd james
```

To list all users that have non-interactive shells:

```bash
grep -E 'nologin|false' /etc/passwd
```

To create a system user without a home directory:

```bash
sudo useradd -r -s /sbin/nologin backup_agent
```

To prevent login using `/bin/false` instead of `nologin`:

```bash
sudo useradd testuser -s /bin/false
```

Exploring these variations helps build a deeper understanding of how Linux distinguishes between human users and service accounts.

---

<br>
<br>

## Key Takeaway

Creating a user with a non-interactive shell is not a trick or shortcut. It is a deliberate security pattern used across production systems. By controlling the shell, Linux controls access. This single design choice allows automation tools to function while preventing accidental or malicious human access. Understanding this concept early makes many advanced DevOps practices easier to reason about later.
