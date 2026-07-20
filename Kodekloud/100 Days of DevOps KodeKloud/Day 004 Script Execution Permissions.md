# DevOps Day 04 — Setting Executable Permissions on a Script

<br>
<br>

- [DevOps Day 04 — Setting Executable Permissions on a Script](#devops-day-04--setting-executable-permissions-on-a-script)
  - [Real Scenario](#real-scenario)
- [Understanding the Requirement](#understanding-the-requirement)
- [Step 1 — Checking Current Permissions](#step-1--checking-current-permissions)
- [Understanding Linux Permission Structure](#understanding-linux-permission-structure)
- [Step 2 — Granting Execute Permission](#step-2--granting-execute-permission)
- [Step 3 — Verifying the Change](#step-3--verifying-the-change)
- [Numeric (Octal) Permission Representation](#numeric-octal-permission-representation)
- [Why Linux Does Not Allow Scripts to Run by Default](#why-linux-does-not-allow-scripts-to-run-by-default)
- [Common Permission Scenarios in DevOps](#common-permission-scenarios-in-devops)
- [Additional Commands Worth Exploring](#additional-commands-worth-exploring)
- [Practical Outcome](#practical-outcome)


## Real Scenario

- In Linux systems, every file has a permission model that determines **who can read it, modify it, or execute it**. This permission model is one of the most fundamental security mechanisms built into the operating system.

- When automation scripts are deployed on servers — such as backup scripts, monitoring scripts, or deployment scripts — they must be marked as **executable** before the operating system allows them to run.

- In this task, a shell script named `xfusioncorp.sh` was placed on **App Server 2**, but it could not be executed because it lacked the required execute permission.

- The goal was to modify the file permissions so **all users on the system could execute the script**.

---

<br>
<br>

# Understanding the Requirement

- A script file is simply a text file containing commands.

- Even if the script is written correctly, Linux will refuse to run it unless the **execute permission bit** is set.

- This behavior is intentional and is part of Linux's security model. By default, new files are created without execute permissions to prevent accidental or malicious code execution.

- Before modifying the permissions, it is always a good practice to inspect the current permission state of the file.

---

<br>
<br>

# Step 1 — Checking Current Permissions

**The first command used was:**

```bash
ls -l /tmp/xfusioncorp.sh
```

**Example output:**

```bash
-rw-r--r-- 1 root root 1200 Apr 10 12:00 /tmp/xfusioncorp.sh

# === Breakdown ===:
# -rw-r--r--          → permission string
# 1                   → number of links
# root                → owner
# root                → group
# 1200                → size in bytes # to check file size in human readable format, use -h option
# Apr 10 12:00        → last modified date and time
# /tmp/xfusioncorp.sh → filename

```

- The command `ls` lists files and directories.

- The `-l` option enables **long format listing**, which displays detailed metadata about the file.


The most important part here is the **permission string**.

```bash
-rw-r--r--

# This is umask 022 permission, which is the default for new files created by a user. It allows:
# - owner: read and write
# - group: read and write
# - others: read

# How to change default umask for a user:
# 1. Open the user's shell configuration file (e.g., ~/.bashrc or ~/.profile).
# 2. Add the line: umask 027  # This will set the default permissions to 750 (rwxr-x---).
# 3. Save the changes.

# What is umask?
# umask (user file-creation mode mask) is a command that sets the default permissions for newly created files and directories. It works by masking out certain permission bits from the default permissions (which are typically 666 for files and 777 for directories). For example, a umask of 022 will result in new files having permissions of 644 (rw-r--r--) and new directories having permissions of 755 (rwxr-xr-x).
```

- Notice that there is **no `x` (execute) permission** in any position.

- Because of this, the system will refuse to execute the script.

**If someone tried to run the script like this:**

```bash
./xfusioncorp.sh
```

**Linux would return:**

```bash
Permission denied
```

---

<br>
<br>

# Understanding Linux Permission Structure

**A permission string such as:**

```bash
-rwxr-xr-x
```

contains **four sections**.

- **File Type**

The first character indicates the file type.

**Examples:**

```bash
-  → regular file
d  → directory
l  → symbolic link
```

---

- **Owner Permissions**

The next three characters represent permissions for the **file owner**.

**Example:**

```bash
rwx
```

**Meaning:**

* read
* write
* execute

---

- **Group Permissions**

The next three characters apply to members of the file's **group**.

**Example:**

```bash
r-x
```

**Meaning:**

* read
* execute
* no write permission

---

- **Other Users**

The final three characters apply to **all other users** on the system.

**Example:**

```bash
r-x
```

Meaning any user can read and execute the file but cannot modify it.

---

- **In some case: +**

The presence of a `+` at the end of the permission string indicates that **Access Control Lists (ACLs)** are in use, which provide more granular permission settings beyond the traditional owner/group/other model.

You can get 

```bash
getfacl /tmp/xfusioncorp.sh
```

Example output:

```bash
# file: /tmp/xfusioncorp.sh
# owner: root
# group: root
# user::rw-
# group::r--
# other::r--
# ACL entries: 3
```

---

<br>
<br>

# Step 2 — Granting Execute Permission

**To allow execution of the script, the following command was used:**

```bash
sudo chmod a+x /tmp/xfusioncorp.sh # a+x specifies that execute permission should be added for all users (owner, group, and others).
# OR
sudo chmod 755 /tmp/xfusioncorp.sh
```

This command modifies the file's permission bits.

---

**`sudo`**

- The command begins with `sudo`.
- Because the file may be owned by another user (such as root), administrative privileges may be required to modify its permissions.

---

**`chmod`**

- `chmod` stands for **change mode**.
- It is the primary Linux command used to modify file permissions.
- Internally, chmod modifies permission bits stored in the filesystem's metadata.

---

**`a+x`**

The expression `a+x` is written in **symbolic notation**.

**Breaking it down:**

```bash
a → all users           # Other options include: u (owner), g (group), o (others)
+ → add permission      # Other operators include: - (remove), = (set exactly)
x → execute permission  # Other permissions include: r (read), w (write)
```

**This command adds execute permission for:**

* owner
* group
* others

---

<br>
<br>

# Step 3 — Verifying the Change

After modifying permissions, it is important to confirm the result.

```bash
ls -l /tmp/xfusioncorp.sh
```

Example output:

```bash
-rwxr-xr-x 1 root root 1200 Apr 10 12:00 /tmp/xfusioncorp.sh
```

Now the permission string contains `x` in each category, confirming that execution is allowed.

Users can now run the script using:

```bash
./xfusioncorp.sh
```

---

<br>
<br>

# Numeric (Octal) Permission Representation

Linux permissions can also be represented using numeric values.

Each permission corresponds to a number:

```bash
read    = 4
write   = 2
execute = 1
```

Permissions are calculated by adding these values together.

**Example:**

**Owner permissions `rwx`:**

```bash
4 + 2 + 1 = 7
```

**Group permissions `r-x`:**

```bash
4 + 0 + 1 = 5
```

**Other permissions `r-x`:**

```bash
4 + 0 + 1 = 5
```

**So the permission `rwxr-xr-x` can also be written as:**

```bash
chmod 755 /tmp/xfusioncorp.sh
```

Both commands achieve the same result.

---

<br>
<br>

# Why Linux Does Not Allow Scripts to Run by Default

Linux follows a **secure-by-default** philosophy.

When a file is created, the system assumes it is **data**, not a program.

Therefore execute permission is not automatically granted.

**This prevents accidental execution of:**

* malicious scripts
* downloaded files
* corrupted programs

Administrators must explicitly mark a file as executable.

---

<br>
<br>

# Common Permission Scenarios in DevOps

Some common permission patterns used in production environments include:

- **Application scripts**

```bash
chmod 755 deploy.sh
```

Owner can modify the script, others can execute it.

---

- **Sensitive scripts**

```bash
chmod 700 backup.sh
```

Only the owner can read, modify, or execute the script.

---

- **Shared utilities**

```bash
chmod 775 tool.sh
```

Owner and group can modify the script, others can execute it.

---

<br>
<br>

# Additional Commands Worth Exploring

**Check file ownership:**

```bash
ls -l
```

**Change file owner:**

```bash
chown user:group file.sh
```

**Remove execute permission:**

```bash
chmod a-x script.sh
```

**Run a script explicitly with bash without execute permission:**

```bash
bash script.sh
```

---

<br>
<br>

# Practical Outcome

After applying the permission change:

* The script `xfusioncorp.sh` becomes executable
* All users on the system can run the script
* The backup automation can execute the script successfully

Understanding Linux file permissions is a foundational skill for DevOps engineers because automation, deployment pipelines, and infrastructure scripts all depend on correct permission management.
