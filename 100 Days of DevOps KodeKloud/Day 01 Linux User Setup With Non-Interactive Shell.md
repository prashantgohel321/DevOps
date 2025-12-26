<center><h1>DevOps Day 1<br>Creating a User with a Non-Interactive Shell</h1></center>

<br>

The first task in the 100 Days of DevOps challenge involved <mark> **creating a new user** </mark>  for a backup agent tool on `App Server 1`, requiring a non-interactive shell.

## Table of Contents
- [Table of Contents](#table-of-contents)
  - [The Task](#the-task)
  - [My Solution \& Command Breakdown](#my-solution--command-breakdown)
    - [1. The Creation Command](#1-the-creation-command)
    - [2. The Verification Command](#2-the-verification-command)
  - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
  - [Deep Dive: What is a Non-Interactive Shell?](#deep-dive-what-is-a-non-interactive-shell)
  - [Exploring the Directories and Files](#exploring-the-directories-and-files)

---

<br>
<br>

### The Task
<a name="the-task"></a>
- The system admin team at xFusionCorp Industries needed a user named `james` created on one of their app servers. This user account would be used by a backup agent, so for security reasons, it shouldn't be possible for a human to log in and get a command prompt with it.

---

<br>
<br>

### My Solution & Command Breakdown
<a name="my-solution--command-breakdown"></a>
- After connecting to `App Server 1` using SSH, I ran a single command to accomplish the entire task.

#### 1. The Creation Command
- This command creates the user and sets their shell at the same time.

```bash
sudo useradd james -s /sbin/nologin
```

**Command Breakdown:**
* `sudo`: Means “Super User Do.” It lets you run commands with admin power. Since creating users needs higher permission, we use sudo to do it safely.
* `useradd`: Linux command for adding a new user account.
* `james`: This is the username I was asked to create.
* `-s`: This is a flag or an "option" for Shell. It tells the `useradd` command which login shell the new user should have.
* `/sbin/nologin`: A special shell that blocks the user from logging in. It’s often used for system or service accounts that don’t need direct access.

#### 2. The Verification Command
- I used `grep` to check the system's user file.

```bash
grep 'james' /etc/passwd

# OUTPUT:
# james:x:1002:1002::/home/james:/sbin/nologin
```

**Command Breakdown:**
* `grep`: Command-line tool **for searching plain-text data** for lines that match a regular expression or a simple string.
* `'james'`: Search string. I was telling `grep` to find any line containing the word "james".
* `/etc/passwd`: This is the file I wanted to search in. It's a system file that contains the list of all user accounts.

---

<br>
<br>

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
This task is all about the **Principle of Least Privilege**. A user account should only have the permissions it absolutely needs to do its job, and nothing more.

-   **Security**: The backup agent doesn’t need a person to log in; it **just needs permission to run tasks and own files**. By giving it a non-interactive shell, we make sure no one (not even by accident) can use this account to access the server directly.
-   **Automation**: In DevOps, we often create service accounts for tools like Jenkins, Docker, or monitoring systems. These **accounts are meant for automated programs, not humans**. It’s a common and secure setup method.

---

<br>
<br>

### Deep Dive: What is a Non-Interactive Shell?
<a name="deep-dive-what-is-a-non-interactive-shell"></a>
- To understand this, let’s first see what an **interactive shell** is.
- When you log in to a Linux server, the system runs a program like `/bin/bash`. This shell is interactive — it shows you a prompt (`$`), waits for your commands, runs them, and displays the output.
- A **non-interactive shell** is the opposite.
- When a user’s shell is set to `/sbin/nologin`, here’s what happens:
  1.  Someone (or a program) tries to log in as `james`.
  2.  The system checks `/etc/passwd` and sees that james has `/sbin/nologin` as the shell.
  3.  It runs `/sbin/nologin`, which shows a message like “This account is currently not available.”.
  4.  Then it ends the session immediately.

- This type of shell never gives a command prompt.
- Think of it like a delivery gate — a robot (automated program) can drop off packages, but if a person tries to enter, the gate instantly closes.

---

<br>
<br>

### Exploring the Directories and Files
<a name="exploring-the-directories-and-files"></a>

* `/etc/passwd`: A text file that **stores details of all users on the system**. Each line represents one user, with information separated by colons (:). The line for `james` shows all his basic account details.
* `/home/james`: This is the home directory created for the `james` user. It’s a personal space where the user (or backup agent) can store logs, config files, or other data.
* `/sbin/`: Short for **System Binaries**. This folder contains core programs needed for the system to start and run. Since `nologin` is located here, it’s treated as an important system-level tool, not a regular user command.