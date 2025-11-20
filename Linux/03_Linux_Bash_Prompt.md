# Linux Lab 3: Linux Bash Prompt

This lab focuses on user environment customization, shell management, and persistence. It covers critical concepts like changing user shells, managing environment variables, creating aliases, and customizing the bash prompt (`PS1`).

## Table of Contents
- [Linux Lab 3: Linux Bash Prompt](#linux-lab-3-linux-bash-prompt)
  - [Table of Contents](#table-of-contents)
    - [Key Concepts](#key-concepts)
    - [Step-by-Step Walkthrough](#step-by-step-walkthrough)
      - [1. Identifying the Default Shell](#1-identifying-the-default-shell)
      - [2. Changing the User Shell (usermod)](#2-changing-the-user-shell-usermod)
      - [3. Terminal Environment Variables (TERM)](#3-terminal-environment-variables-term)
      - [4. Persistent Configuration (.profile)](#4-persistent-configuration-profile)
      - [5. Creating Environment Variables](#5-creating-environment-variables)
      - [6. Understanding the PATH Variable](#6-understanding-the-path-variable)
      - [7. Creating Command Aliases](#7-creating-command-aliases)
      - [8. Customizing the Bash Prompt (PS1)](#8-customizing-the-bash-prompt-ps1)
    - [Command Reference](#command-reference)

---

### Key Concepts
<a name="key-concepts"></a>

* **Shells:** The program that interprets your commands. Common shells include `bash` (Bourne Again Shell) and `sh` (Bourne Shell).
* **Environment Variables:** Dynamic values that affect the processes or shells on a computer (e.g., `HOME`, `PATH`, `TERM`, `PS1`).
* **Profile Files:** Hidden files in a user's home directory (like `.profile` and `.bashrc`) that run every time a user logs in. They are used to make settings **persistent**.
* **Aliases:** Custom shortcuts for longer commands.
* **PS1 (Prompt String 1):** The environment variable that defines the appearance of your command line prompt.

---

### Step-by-Step Walkthrough
<a name="step-by-step-walkthrough"></a>

#### 1. Identifying the Default Shell
<a name="1-identifying-the-default-shell"></a>
**Question:** What is the default shell for Bob?
**Answer:** `/bin/bash`

**Explanation:** You can verify a user's default shell by looking at the `/etc/passwd` file, which stores essential user account information.
```bash
grep bob /etc/passwd
# Output: bob:x:1000:1000::/home/bob:/bin/bash
```
The last field (`/bin/bash`) specifies the shell.

#### 2. Changing the User Shell (usermod)
<a name="2-changing-the-user-shell-usermod"></a>
**Task:** Change Bob's shell from `bash` to `sh`.
**Command:** `sudo usermod -s /bin/sh bob`

**Explanation:**
* `usermod`: A command to modify a user account.
* `-s`: The flag to change the login **s**hell.
* `/bin/sh`: The path to the new shell (Bourne Shell).
* `sudo`: Required because modifying user accounts is an administrative task.

#### 3. Terminal Environment Variables (TERM)
<a name="3-terminal-environment-variables-term"></a>
**Question:** What is the value of the environment variable TERM?
**Answer:** `xterm-256color`

**Explanation:**
The `TERM` variable tells the system what kind of terminal you are using so it knows how to display colors and handle cursor movements.
* To check this value yourself, run:
  ```bash
  echo $TERM
  ```

#### 4. Persistent Configuration (.profile)
<a name="4-persistent-configuration-profile"></a>
**Task:** Understand how to make changes persistent.

**Explanation:**
If you just type `alias ll="ls -l"` in your terminal, it only lasts until you close that window. To make it permanent ("persistent"), you must add the command to a startup script like `~/.profile` or `~/.bashrc`.
* **`~/.profile`**: Executed for login shells. Good for environment variables.
* **`~/.bashrc`**: Executed for non-login interactive shells. Ideally where aliases and prompts go, though `.profile` is often used for simplicity in these labs.

#### 5. Creating Environment Variables
<a name="5-creating-environment-variables"></a>
**Task:** Create a persistent environment variable `PROJECT=MERCURY`.
**Command:** `echo 'export PROJECT=MERCURY' >> ~/.profile`

**Explanation:**
* `export`: Makes the variable available to child processes (programs you run from the shell).
* `>>`: **Appends** the line to the end of the file. (Using `>` would overwrite the entire file!)

#### 6. Understanding the PATH Variable
<a name="6-understanding-the-path-variable"></a>
**Question:** Which directory is NOT part of the PATH variable?
**Answer:** `/opt/caleston-code`

**Explanation:**
The `PATH` variable is a list of directories where the system looks for executable programs.
* Standard directories include `/usr/bin`, `/bin`, `/usr/sbin`, `/sbin`, and `/usr/local/bin`.
* `/opt/caleston-code` is a custom application directory and would not be in the system's default path unless manually added.

#### 7. Creating Command Aliases
<a name="7-creating-command-aliases"></a>
**Task:** Create a persistent alias named `up` that runs the `uptime` command.
**Command:** `echo 'alias up="uptime"' >> ~/.profile`

**Explanation:**
* **Alias:** A custom shortcut. Now, typing `up` will execute `uptime`.
* Adding it to `.profile` ensures it works every time Bob logs in.

#### 8. Customizing the Bash Prompt (PS1)
<a name="8-customizing-the-bash-prompt-ps1"></a>
**Task:** Update Bob's prompt to display the date, user, host, and current directory.
**Format:** `[Wed Apr 22]bob@caleston-lp10:~$`
**Command:**
```bash
echo 'export PS1="[\$(date +%a\ %b\ %d)]\u@\h:\w\$ "' >> ~/.bashrc
source ~/.bashrc
```

**Explanation:**
* **`PS1`**: The primary prompt string variable.
* **`\u`**: Username (`bob`)
* **`\h`**: Hostname (`caleston-lp10`)
* **`\w`**: Working directory (`~`)
* **`\$`**: Shell prompt symbol (`$` for user, `#` for root)
* **`$(date +%a\ %b\ %d)`**: This is command substitution. It runs the `date` command with a specific format (Day Month Date) and puts the result into the prompt.
    * We escape the `$` as `\$` inside the echo command so that it writes the *literal command* into the file, rather than executing it right now and writing a static date.
* **`source ~/.bashrc`**: This command reloads the configuration file immediately so you can see the change without logging out and back in.

---

### Command Reference
<a name="command-reference"></a>

| Command | Name | Purpose | Example |
| :--- | :--- | :--- | :--- |
| `usermod` | User Modify | Changes user account properties | `sudo usermod -s /bin/sh bob` |
| `grep` | Global Regular Expression Print | Searches text/files for patterns | `grep bob /etc/passwd` |
| `echo` | Echo | Prints text to screen or file | `echo $TERM` |
| `>>` | Append Redirect | Adds output to the end of a file | `echo "text" >> file.txt` |
| `source` | Source | Executes commands from a file in the current shell | `source ~/.bashrc` |
| `date` | Date | Displays or sets the system date | `date +%Y-%m-%d` |
| `uptime` | Uptime | Shows how long the system has been running | `uptime` |

    