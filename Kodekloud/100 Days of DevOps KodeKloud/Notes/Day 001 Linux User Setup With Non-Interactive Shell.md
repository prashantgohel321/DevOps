# DevOps Day 01 — Creating a Linux User with a Non‑Interactive Shell

<br>
<br>

The moment services start running in a real environment, something subtle but important becomes visible: nothing in Linux runs “on its own.” Every process you see with `ps`, whether it’s a backup agent, a CI runner, or even a database, is always tied to a user identity. That identity is not just a label; internally it is a numeric UID, and the kernel uses that UID to decide what that process is allowed to read, write, or execute.

That is why even fully automated components need a user. But giving them a normal login-enabled user would quietly introduce risk. If that account can open a shell, it becomes an entry point. The goal, then, is not just to create a user, but to create one that exists purely for execution, not interaction.

The clean way to do that is by controlling what Linux launches after authentication.

When a login attempt happens—through SSH, console, or any login service—the system first verifies credentials, then looks into `/etc/passwd`. That file is not just a list of users; it is effectively a launch configuration. The last field in each entry tells Linux which program to start once the user is authenticated.

For a normal user, that program is something like `/bin/bash`, which is a shell. A shell is simply a program that waits for commands and executes them, giving that familiar prompt. But if instead of a shell you point to a program that does nothing useful for interaction, the login technically succeeds but immediately ends.

That is the idea behind a non-interactive shell.

**So instead of creating a user in the usual way, the shell is deliberately replaced:**

```bash
sudo useradd james -s /sbin/nologin
```

This command looks simple, but it modifies core identity layers of the system. The `useradd` utility is not just inserting a name; it allocates a UID, creates a group, and writes entries across `/etc/passwd`, `/etc/shadow`, and `/etc/group`. These files together form the authentication and authorization backbone of Linux.

The `-s` option is where the behavior changes completely. It defines the login shell, which, in reality, is just the program Linux executes after login. Instead of assigning `/bin/bash`, it assigns `/sbin/nologin`.

`nologin` is not a shell. It is a small binary <mark><b>whose only job is to terminate the session immediately</b></mark>, usually with a message. So even if credentials are correct, the system never reaches a usable prompt. The access path exists, but it leads nowhere.

Once created, the system reflects this configuration directly:

```bash
grep james /etc/passwd
```

You will see something like:

```bash
james:x:1002:1002::/home/james:/sbin/nologin

# Breakdown of fields:
# 1. Username: james
# 2. Password placeholder: x (actual hash is in /etc/shadow)
# 3. UID: 1002 (assigned by the system)
# 4. GID: 1002 (primary group ID)
# 5. User info: (empty in this case)
# 6. Home directory: /home/james (created by default)
# 7. Login shell: /sbin/nologin (prevents interactive login)
```

This line is more meaningful than it looks. Each field is interpreted by the system: the username maps to a UID, the UID maps to ownership, and the final field controls session behavior. The `x` in the password field indicates that the actual password hash is stored separately in `/etc/shadow`, which is protected so only root can read it.

At this point, the user fully exists from the kernel’s perspective. *Any service can run under it*, *files can be owned by it*, and *permissions apply normally*. **But if someone tries to SSH into it**, **the session ends immediately**. That *balance—usable for processes*, *unusable for humans*—is exactly what production systems need.

In DevOps environments, this pattern appears everywhere. Jenkins agents, Docker daemons, monitoring tools, and database services all run under restricted users. This is how the principle of least privilege naturally shows up in practice: instead of giving broad access and trying to restrict it later, access is never granted in the first place.

Once you start working deeper, a few commands become especially useful for observing and validating this behavior.

**Instead of directly reading files, querying through the system’s name service layer gives a more accurate picture:**

```bash
getent passwd james
```

`getent` doesn’t just read `/etc/passwd`; it queries the system’s configured identity sources, which could include LDAP or other backends. That makes it more reliable in distributed environments.

To quickly audit all restricted users in a system:

```bash
awk -F: '$7 ~ /(nologin|false)/ {print $1,$7}' /etc/passwd
```

Here, `-F:` tells `awk` to split fields by colon, and `$7` represents the shell field. This surfaces all users that cannot log in interactively.

In hardened systems, even more control is often layered on top. For example, locking the password ensures that even authentication cannot succeed:

```bash
sudo usermod -L james
```

This modifies the shadow entry so that password-based login is disabled entirely. Now the account exists purely as an execution identity.

Sometimes, these accounts don’t even need a home directory or login history. That’s where system accounts come in:

```bash
sudo useradd -r -M -s /sbin/nologin backup_agent
```

The `-r` flag creates a system account, typically assigning it a UID from a reserved range. The `-M` avoids creating a home directory. This keeps the system cleaner and avoids unnecessary filesystem exposure.

Another subtle variation is using `/bin/false` instead of `nologin`. Both prevent interaction, but their behavior differs slightly. `false` exits silently, while `nologin` usually provides a message. In automated environments, that difference can matter when logs are being parsed.

At runtime, you can actually see these users in action:

```bash
ps -eo user,pid,cmd | grep james
```

This shows processes owned by that user, confirming that even without login capability, the account is actively used by the system.

In the end, what looks like a small tweak—the shell field in `/etc/passwd`—is actually a control point over how identities behave across the entire system. By replacing an interactive shell with a terminating program, the system allows execution without exposure. That is the kind of subtle control that becomes second nature in DevOps: shaping behavior not by adding restrictions later, but by designing it correctly from the start.

<br>
<br>

### Files Involved

**What `/etc/passwd` file is for?**

The **`/etc/passwd`** file is a fundamental component of the Linux operating system that serves as **a database of user accounts**. It contains essential information about each user, such as their **`username`**, **`UID`** (User Identifier), **`GID`** (Group Identifier), **`home directory`**, and **`login shell`**. When a user attempts to log in, the system consults this file to verify credentials and determine the appropriate environment for the session. Each line in **`/etc/passwd`** represents a single user account, making it a critical resource for managing user access and permissions on the system.

<br>
<br>

**What `/etc/shadow` file is for?**

The **`/etc/shadow`** file is a secure file that stores encrypted passwords for user accounts. It contains information about each user's password policies, such as the last password change date, password expiration details, and account lockout status. This file is only accessible to the root user and is crucial for maintaining the security of user authentication on the system. By separating password hashes from the more publicly readable **`/etc/passwd`** file, Linux enhances security by preventing unauthorized access to sensitive password information.

<br>
<br>

**What `/etc/group` file is for?**

The **`/etc/group`** file is a database that defines the groups on a Linux system. It contains information about each group, including the **`group name`**, **`GID`** (Group Identifier), and a list of **`members`** who belong to that group. Groups are used to manage permissions and access control for multiple users simultaneously. When a user is added to a group, they inherit the permissions associated with that group, making it easier to manage access rights across the system. The **`/etc/group`** file is essential for organizing users into logical units and controlling their access to resources based on group membership.
