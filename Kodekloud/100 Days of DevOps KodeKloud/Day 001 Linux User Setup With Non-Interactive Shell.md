# DevOps Day 01 — Creating a Linux User with a Non‑Interactive Shell

<br>
<br>

- [DevOps Day 01 — Creating a Linux User with a Non‑Interactive Shell](#devops-day-01--creating-a-linux-user-with-a-noninteractive-shell)
  - [Real Scenario](#real-scenario)
- [Understanding the Requirement](#understanding-the-requirement)
- [How Linux Login Works Internally](#how-linux-login-works-internally)
- [Creating the User](#creating-the-user)
- [Verifying the User Creation](#verifying-the-user-creation)
- [Important System Files Involved](#important-system-files-involved)
- [Why DevOps Teams Use Non‑Interactive Users](#why-devops-teams-use-noninteractive-users)
- [Related Commands Worth Exploring](#related-commands-worth-exploring)
- [Alternative Method: /bin/false](#alternative-method-binfalse)
- [Practical Outcome](#practical-outcome)

<br>
<br>

## Real Scenario

- In production Linux environments, many programs run continuously in the background. These programs include monitoring agents, backup services, CI/CD runners, container runtimes, and log collectors. Even though these programs are automated, the Linux operating system still requires them to run under a **user identity**.

- Linux does not allow processes to exist without an owner. Every running process must belong to a specific **UID (User Identifier)** so the kernel can enforce permissions such as which files the process can read, modify, or execute.

- Because of this design, administrators usually create **dedicated service accounts** for these automated tools.

- These accounts are intentionally restricted so that humans cannot log in interactively. The goal is to allow the process to run while reducing the risk of unauthorized access.

- The task in this exercise is to create a user named `james` for a backup agent, while preventing interactive shell access.

---

<br>
<br>

# Understanding the Requirement

**The operations team required the following configuration:**

* A Linux user named **james** must exist on the server.
* The account will be used by a **backup agent service**.
* Humans must **not be able to log in as this user**.

At first glance this may appear unusual. Normally creating a user means allowing someone to log in. However, in DevOps environments many users exist only so that services can run safely.

Instead of allowing interactive access, the user will be assigned a **non‑interactive login shell**.

---

<br>
<br>

# How Linux Login Works Internally

To understand why a non‑interactive shell works, it helps to look at the login flow.

**When a user attempts to log in to Linux, the operating system performs several internal steps:**

1. The login service (such as SSH or a console login) authenticates the user credentials.
2. The system checks the user's entry inside the **`/etc/passwd`** database.
3. The final field of that entry tells Linux which program should start after authentication.

<br>
<br>

**For most human users, that program is a shell such as:**

```bash
/bin/bash
```

**When bash starts, it prints a prompt like:**

```bash
[user@server ~]$
```

This is called an **interactive shell** because it waits for commands typed by the user.

However, if the login shell is replaced with a different program, Linux will run that program instead of bash.

This mechanism is exactly what we use to disable interactive access.

---

<br>
<br>

# Creating the User

The user is created using the following command:

```bash
sudo useradd james -s /sbin/nologin
```

This single command performs multiple system operations.

---

<br>
<br>

- **`sudo`**: The command begins with `sudo`.
  - `sudo` allows a normal user to execute commands with **root privileges**.

**User management commands modify critical system files such as:**

```bash
/etc/passwd
/etc/shadow
/etc/group
```

Because these files control system authentication and identity, only the root user can modify them.

---

<br>
<br>

- **`useradd`**: `useradd` is a standard Linux utility responsible for creating new user accounts.

  - **When executed, it performs several internal actions:**
    1. Allocates a new **UID** from the system UID range.
    2. Creates a matching **primary group**.
    3. Adds a user entry to `/etc/passwd`.
    4. Updates `/etc/shadow` for password storage.
    5. Optionally creates a home directory.
    6. Assigns the login shell.

These operations register the user with the operating system.

---

<br>
<br>

- **Username: `james`**:The argument `james` becomes the **login name** of the account.
  - Internally Linux does not rely on usernames. Instead it maps the username to a numeric **UID**.

**Example:**

```bash
james → UID 1002
```

Files created by the user will actually be owned by UID 1002, even though the system displays the username.

---

<br>
<br>

- **`-s` Option (Login Shell)**: The `-s` option specifies the **login shell** for the account.
  - **Instead of assigning `/bin/bash`, the command sets the shell to:**

```bash
/sbin/nologin
```

  - The program `nologin` is a small binary that immediately terminates the session.
  - When someone attempts to log in as this user, the system executes `nologin` instead of bash. The program prints a message and exits.

**As a result:**

* Authentication may succeed
* No shell prompt appears
* The session ends immediately

This effectively disables interactive login.

---

<br>
<br>

# Verifying the User Creation

After creating the user, administrators usually verify the configuration.

The simplest method is to inspect the system user database.

```bash
grep james /etc/passwd
```

Example output:

```bash
james:x:1002:1002::/home/james:/sbin/nologin
```

This output reveals how Linux internally stores account information.

The `/etc/passwd` file stores user entries using colon-separated fields.

**Structure:**

```bash
username : password_placeholder : UID : GID : comment : home_directory : shell
```

**Breaking down the example:**

```bash
james          # The Username
x              # Indicates the encrypted password is stored in /etc/shadow.
1002           # User ID assigned by the system.
1002           # Primary group ID.
/home/james    # Home directory
/sbin/nologin  # Assigned login shell.
```

Seeing `nologin` confirms that interactive login is disabled.

---

<br>
<br>

# Important System Files Involved

- **`/etc/passwd`**: 
  - Contains the list of user accounts and their attributes.
  - Despite its name, this file does not contain passwords anymore.

---

<br>
<br>

- **`/etc/shadow`**
  - Stores encrypted password hashes and password expiration policies.
  - Only root can read this file.

---

<br>
<br>

- **`/etc/group`**
  - Defines system groups and which users belong to them.
  - Groups allow multiple users to share file permissions.

---

<br>
<br>

# Why DevOps Teams Use Non‑Interactive Users

This approach implements a core security concept called the **Principle of Least Privilege**.

**The idea is simple:**

A system component should only have the permissions required to perform its job.

**A backup agent needs:**

* access to read files
* ability to write backup archives
* ability to run scheduled tasks

**It does **not** need:**

* a command prompt
* interactive login
* human access

By disabling the shell, administrators reduce the attack surface of the server.

---

<br>
<br>

# Related Commands Worth Exploring

**View the user entry using the system account database:**

```bash
getent passwd james

# getent is a command that queries the system's account databases, including /etc/passwd. It provides a consistent way to retrieve user information regardless of the underlying storage mechanism (local files, LDAP, etc.).

# passwd is the database of user accounts, and getent looks up the entry for james, showing the same information as grep but in a more standardized format.
```

**List all users with non‑interactive shells:**

```bash
grep -E 'nologin|false' /etc/passwd

# -E enables extended regular expressions, allowing us to search for multiple patterns (nologin or false) in the shell field of the passwd file. This command helps identify all accounts that are configured to prevent interactive logins.
```

**Create a system service account without a home directory:**

```bash
sudo useradd -r -s /sbin/nologin backup_agent

# here -r is used to create a system account, which is typically reserved for services and does not have a home directory. This is another common pattern for service accounts that only need to run processes without human interaction.
```

`-r` creates a **system account** typically used by services.

---

<br>
<br>

# Alternative Method: /bin/false

**Another common non‑interactive shell is:**

```bash
/bin/false

# Example:
sudo useradd testuser -s /bin/false

```

**Difference between the two:**

| Shell   | Behavior                                      |
| ------- | --------------------------------------------- |
| nologin | Prints a message explaining login is disabled |
| false   | Immediately exits silently                    |

---

<br>
<br>

# Practical Outcome

After running the command:

* The user `james` exists in the system
* The backup service can run under this identity
* Interactive login is prevented

This configuration pattern is widely used across production servers for running automation tools securely.
