# Linux Lab 12: User and Group Management

This lab focuses on the administration of user accounts and groups in Linux. It covers how to identify user information (UID, GID), verify sudo access, understand where user data is stored (`/etc/passwd`, `/etc/shadow`), and create new users and groups.

## Table of Contents
- [Linux Lab 12: User and Group Management](#linux-lab-12-user-and-group-management)
  - [Table of Contents](#table-of-contents)
    - [Key Concepts](#key-concepts)
    - [Step-by-Step Walkthrough](#step-by-step-walkthrough)
      - [1. User Account Basics](#1-user-account-basics)
      - [2. Identifying User Information (id)](#2-identifying-user-information-id)
      - [3. Understanding Sudo Access](#3-understanding-sudo-access)
      - [4. Password Storage (/etc/shadow)](#4-password-storage-etcshadow)
      - [5. Inspecting User Details (/etc/passwd)](#5-inspecting-user-details-etcpasswd)
      - [6. Understanding Group Membership](#6-understanding-group-membership)
      - [7. Creating Users and Setting Passwords](#7-creating-users-and-setting-passwords)
      - [8. Creating Groups and Custom Users](#8-creating-groups-and-custom-users)
    - [Command Reference](#command-reference)

---

### Key Concepts
<a name="key-concepts"></a>

* **UID (User ID):** A unique number assigned to each user.
* **GID (Group ID):** A unique number assigned to each group.
* **Primary Group:** The main group a user belongs to (usually has the same name as the user). Files created by the user belong to this group by default.
* **`/etc/passwd`:** Stores user account information (username, UID, GID, home directory, shell).
* **`/etc/shadow`:** Stores secure, encrypted password information.
* **`/etc/sudoers`:** Configures which users can run commands as superuser (root).

[Image of Linux user management architecture showing UID GID and config files]

---

### Step-by-Step Walkthrough
<a name="step-by-step-walkthrough"></a>

#### 1. User Account Basics
<a name="1-user-account-basics"></a>
**Question:** What type of account does Bob use?
**Answer:** `user account`

**Explanation:**
In Linux, there are generally two types of accounts:
1.  **User Accounts:** For real people to log in and do work (e.g., bob, sarah).
2.  **System Accounts:** For services and applications to run under (e.g., apache, mysql). They usually have lower UIDs and no login shell.

#### 2. Identifying User Information (id)
<a name="2-identifying-user-information-id"></a>
**Question:** Which command will show you the UID for a user?
**Answer:** `id`

**Task:** Find the UID for bob.
**Command:** `id` (when logged in as bob) or `id bob`
**Output:** `uid=1000(bob) gid=1000(bob) groups=1000(bob)`
**Answer:** `1000`

#### 3. Understanding Sudo Access
<a name="3-understanding-sudo-access"></a>
**Question:** What level of sudo access does bob have?
**Command:** `sudo grep bob /etc/sudoers`
**Output:** `bob ALL=(ALL) ALL`
**Answer:** `All Permissions`

**Explanation:**
The line `bob ALL=(ALL) ALL` means user `bob` can run **ALL** commands on **ALL** hosts as **ALL** users. This is full administrator access.

#### 4. Password Storage (/etc/shadow)
<a name="4-password-storage-etcshadow"></a>
**Question:** Which access control file has the encrypted password for the users?
**Answer:** `/etc/shadow`

**Explanation:**
While `/etc/passwd` contains user info, it is readable by everyone. For security, the actual password hashes are stored in `/etc/shadow`, which is only readable by the root user.

#### 5. Inspecting User Details (/etc/passwd)
<a name="5-inspecting-user-details-etcpasswd"></a>
**Task:** Find the Full Name of the user `chris`.
**Command:** `sudo grep chris /etc/passwd`
**Output:** `chris:x:1002:1002:Chris Hunter:/home/chris:/bin/sh`
**Answer:** `Chris Hunter`

**Explanation:**
The `/etc/passwd` format is:
`Username:Password:UID:GID:GECOS(Full Name):Home Directory:Shell`
The 5th field contains the user's full name/comments.

#### 6. Understanding Group Membership
<a name="6-understanding-group-membership"></a>
**Question:** Which groups are chris part of?
**Command:** `id chris`
**Output:** `uid=1002(chris) gid=1002(chris) groups=1002(chris),1003(cannon),1004(sapphire)`
**Answer:** `chris, cannon, sapphire`

**Question:** What is chris's primary group?
**Answer:** `chris`

**Explanation:**
The group listed in `gid=` is the **primary group**. The groups listed in `groups=` include the primary group plus any **secondary (supplementary) groups**.

#### 7. Creating Users and Setting Passwords
<a name="7-creating-users-and-setting-passwords"></a>
**Task:** Create user `sarah` and set her password to `caleston321`.
**Commands:**
1.  `sudo useradd sarah` (Creates the user)
2.  `sudo passwd sarah` (Prompts to set the password)

**Explanation:**
`useradd` creates the account entry and home directory. `passwd` updates the shadow file with the new password hash.

#### 8. Creating Groups and Custom Users
<a name="8-creating-groups-and-custom-users"></a>
**Task:**
1.  Create a group `john` with GID `1010`.
2.  Create user `john` with UID `1010`, primary group `john`, and shell `/bin/sh`.

**Commands:**
1.  `sudo groupadd -g 1010 john`
2.  `sudo useradd -u 1010 -g 1010 -s /bin/sh john`

**Explanation:**
* **`groupadd -g 1010`**: Creates a group with a specific Group ID.
* **`useradd` flags:**
    * `-u 1010`: Sets specific User ID.
    * `-g 1010`: Sets specific Primary Group ID.
    * `-s /bin/sh`: Sets the default login shell.

---

### Command Reference
<a name="command-reference"></a>

| Command | Purpose | Example |
| :--- | :--- | :--- |
| `id` | Display user identity (UID/GID) | `id bob` |
| `useradd` | Create a new user | `sudo useradd -u 1010 john` |
| `groupadd` | Create a new group | `sudo groupadd -g 1010 admins` |
| `passwd` | Change user password | `sudo passwd sarah` |
| `grep` | Search files for text | `grep chris /etc/passwd` |
| `sudo` | Execute command as superuser | `sudo ls /root` |
| `/etc/passwd` | User account database file | `cat /etc/passwd` |
| `/etc/shadow` | Secure password file | `sudo cat /etc/shadow` |
| `/etc/sudoers` | Sudo access configuration file | `sudo cat /etc/sudoers` |

   