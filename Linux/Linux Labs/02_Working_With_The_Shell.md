# Linux Lab 2: Working With The Shell

This lab is an essential introduction to navigating and manipulating the Linux filesystem using the shell. It covers core concepts like home directories, environment variables, command arguments, and fundamental file operations (`mkdir`, `mv`, `rm`).



## Table of Contents
- [Linux Lab 2: Working With The Shell](#linux-lab-2-working-with-the-shell)
  - [Table of Contents](#table-of-contents)
    - [Key Concepts](#key-concepts)
    - [Step-by-Step Walkthrough](#step-by-step-walkthrough)
      - [1. Understanding User Home Directories](#1-understanding-user-home-directories)
      - [2. Environment Variables ($HOME)](#2-environment-variables-home)
      - [3. Anatomy of a Command](#3-anatomy-of-a-command)
      - [4. Types of Commands](#4-types-of-commands)
      - [5. Creating Directories (mkdir)](#5-creating-directories-mkdir)
      - [6. Creating Nested Directories (mkdir -p)](#6-creating-nested-directories-mkdir--p)
      - [7. Permission Denied \& The Power of `sudo`](#7-permission-denied--the-power-of-sudo)
      - [8. Moving Files (mv)](#8-moving-files-mv)
      - [9. Renaming Files (mv)](#9-renaming-files-mv)
      - [10. Deleting Directories (rm -rf)](#10-deleting-directories-rm--rf)
    - [Command Reference](#command-reference)

---

### Key Concepts
<a name="key-concepts"></a>

* **The Shell:** The command-line interface (CLI) where you type commands to interact with the operating system.
* **Home Directory (`~`):** The default directory assigned to a user. For user `bob`, it is `/home/bob`. This is where the user has full control to create and delete files.
* **Absolute vs. Relative Paths:**
    * **Absolute Path:** Starts from the root `/` (e.g., `/home/bob/fish`). It always points to the same location.
    * **Relative Path:** Starts from your *current* directory (e.g., `birds` or `./reptile`).
* **Arguments:** The extra information you give a command to tell it *what* to act on (e.g., in `mkdir birds`, "birds" is the argument).
* **Options/Flags:** Modifiers that change how a command behaves (e.g., `-p` in `mkdir -p`). They usually start with a hyphen.

---

### Step-by-Step Walkthrough
<a name="step-by-step-walkthrough"></a>

#### 1. Understanding User Home Directories
<a name="1-understanding-user-home-directories"></a>
**Question:** What is the home directory for the user called `bob`?
**Answer:** `/home/bob`

**Explanation:** In Linux, user home directories are standardly located under `/home/` followed by the username. This is Bob's personal workspace.

#### 2. Environment Variables ($HOME)
<a name="2-environment-variables-home"></a>
**Question:** Which command shows your home directory?
**Answer:** `echo $HOME`

**Explanation:**
* `$HOME` is an **environment variable** that stores the path to the current user's home directory.
* The `echo` command prints the value of the variable to the screen.
* Typing just `cd` (with no arguments) is a shortcut that takes you straight to `$HOME`.

#### 3. Anatomy of a Command
<a name="3-anatomy-of-a-command"></a>
**Question:** In `echo Welcome`, what does "Welcome" represent?
**Answer:** Argument

**Explanation:**
* **Command:** `echo` (The action to perform)
* **Argument:** `Welcome` (The target or data for the action)
* If we used `echo -n Welcome`, `-n` would be an **option** (or flag).

#### 4. Types of Commands
<a name="4-types-of-commands"></a>
**Question:** What type of command is `git`?
**Answer:** File (Executable)

**Explanation:** Commands in Linux can be:
* **Built-ins:** Part of the shell itself (e.g., `cd`, `echo` in some shells).
* **Aliases:** Shortcuts for other commands.
* **Files (Executables):** Standalone programs stored on the disk (e.g., `/usr/bin/git`). You can verify this with the `type git` or `which git` command.

#### 5. Creating Directories (mkdir)
<a name="5-creating-directories-mkdir"></a>
**Task:** Create the directory `birds`.
**Command:** `mkdir birds`

**Explanation:**
* `mkdir` stands for **m**a**k**e **dir**ectory.
* Since we are already in `/home/bob` (indicated by the `~` in the prompt `bob@caleston-lp10:~$`), creating `birds` puts it at `/home/bob/birds`.

#### 6. Creating Nested Directories (mkdir -p)
<a name="6-creating-nested-directories-mkdir--p"></a>
**Task:** Create `/home/bob/fish/salmon`.
**Command:** `mkdir -p /home/bob/fish/salmon`

**Explanation:**
* We want to create `salmon` inside `fish`, but the `fish` directory **doesn't exist yet**.
* Running `mkdir /home/bob/fish/salmon` would fail with an error: `No such file or directory`.
* The **`-p` (parents)** flag tells `mkdir` to create any missing parent directories (`fish`) automatically along the way.

#### 7. Permission Denied & The Power of `sudo`
<a name="7-permission-denied--the-power-of-sudo"></a>
**The Problem:** You tried `mkdir -p /fish/salmon` and got `Permission denied`.

**Why it happened:**
* `/fish/salmon` (starting with `/`) is an **absolute path**. It tries to create a directory named `fish` at the very root of the filesystem (`/`).
* The root directory `/` is owned by the administrator (`root`). A regular user like `bob` cannot write there.

**The Fix:**
1.  **Use `sudo`:** `sudo mkdir -p /fish/salmon` runs the command with root privileges.
2.  **Correct the Path:** The task actually wanted the directory in your home folder. `mkdir -p /home/bob/fish/salmon` (or just `mkdir -p fish/salmon`) works without `sudo` because Bob owns his own home directory.

**Your Workflow Analysis:**
* You correctly identified that you needed `sudo` to write to `/fish`.
* You then correctly realized you should be creating these in `/home/bob/` instead.
* **Tip:** `mkdir -p mammals/{elephant,monkey}` is a faster way to create multiple subdirectories at once using "brace expansion".

#### 8. Moving Files (mv)
<a name="8-moving-files-mv"></a>
**Task:** Move `frog` from `reptile` to `amphibian`.
**Command:** `mv ./reptile/frog ./amphibian/`

**Explanation:**
* `mv` stands for **m**o**v**e.
* **Source:** `./reptile/frog` (The file/dir to move)
* **Destination:** `./amphibian/` (Where to put it)
* The `./` explicitly means "in the current directory," though it's often optional.

#### 9. Renaming Files (mv)
<a name="9-renaming-files-mv"></a>
**Task:** Rename `snake` to `crocodile`.
**Command:** `mv snake crocodile` (after `cd reptile`)

**Explanation:**
* **The `mv` command does double duty:** It is used for both **moving** and **renaming**.
* If the destination (`crocodile`) does not exist, Linux assumes you want to rename the source (`snake`) to that new name.
* If `crocodile` *did* exist as a directory, `snake` would be moved *inside* it.

#### 10. Deleting Directories (rm -rf)
<a name="10-deleting-directories-rm--rf"></a>
**Task:** Delete `reptile` and its contents.
**Command:** `rm -rf reptile`

**Explanation:**
* `rm`: **R**e**m**ove.
* `-r`: **R**ecursive. Necessary because you are deleting a directory which might contain files. Standard `rm` only deletes files.
* `-f`: **F**orce. Deletes without asking for confirmation for every single file. **Use with caution!**

---

### Command Reference
<a name="command-reference"></a>

| Command | Name | Purpose | Example |
| :--- | :--- | :--- | :--- |
| `echo` | Echo | Prints text or variables to the screen | `echo $HOME` |
| `mkdir` | Make Directory | Creates a new folder | `mkdir birds` |
| `mkdir -p` | Make Parent | Creates a folder tree (nested dirs) | `mkdir -p a/b/c` |
| `cd` | Change Directory | Navigates the filesystem | `cd mammals` |
| `ls` | List | Shows files in a directory | `ls -la` |
| `mv` | Move | Moves or renames files/dirs | `mv old new` |
| `rm` | Remove | Deletes files | `rm file.txt` |
| `rm -rf` | Remove Recursive Force | Deletes a directory and everything in it | `rm -rf folder` |
| `sudo` | SuperUser Do | Runs command as root (admin) | `sudo mkdir /root/test` |

  