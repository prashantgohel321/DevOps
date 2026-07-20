# DevOps Day 02 — Creating a Temporary Linux User with an Expiry Date

<br>
<br>

- [DevOps Day 02 — Creating a Temporary Linux User with an Expiry Date](#devops-day-02--creating-a-temporary-linux-user-with-an-expiry-date)
  - [Real Scenario](#real-scenario)
- [Understanding the Requirement](#understanding-the-requirement)
- [Creating the Temporary User](#creating-the-temporary-user)
- [Verifying the Account Expiry](#verifying-the-account-expiry)
- [How Linux Implements Account Expiry Internally](#how-linux-implements-account-expiry-internally)
- [Difference Between Account Expiry and Password Expiry](#difference-between-account-expiry-and-password-expiry)
- [Why DevOps Teams Use Expiring Accounts](#why-devops-teams-use-expiring-accounts)
- [Additional Commands to Explore](#additional-commands-to-explore)
- [Practical Outcome](#practical-outcome)

<br>
<br>

## Real Scenario

- In real production environments, not every user account should remain active forever. Many organizations frequently provide **temporary access** to contractors, developers, auditors, or external support engineers who only need access for a short time.

- For example, a developer might require server access for a week to debug an issue, or a consultant may need access during a migration project. If these accounts remain active after the work is finished, they become what security teams call **orphaned accounts** or **ghost accounts**.

- These forgotten accounts create serious security risks because they still provide a valid entry point into the system.

- To solve this problem, Linux allows administrators to create accounts with an **expiry date**. When the expiry date is reached, the account becomes disabled automatically without requiring manual intervention.

- In this task, a temporary user named `anita` needed access to **App Server 3**, but the account should automatically expire on **January 28, 2024**.


---

<br>
<br>

# Understanding the Requirement

**The system administration team needed to ensure three things:**

* A Linux user named **anita** must exist on the server.
* The account should be active immediately so the developer can log in.
* The account must automatically expire on **2024-01-28**.

Instead of relying on administrators to remember to disable the account later, Linux can enforce this rule automatically using account aging policies.

---

<br>
<br>

# Creating the Temporary User

**The user account can be created using the following command:**

```bash
sudo useradd anita --expiredate 2024-01-28
```

- This command creates the user and sets the expiry date in a single step.
- Understanding each component of the command helps reveal how Linux manages account lifecycles.

---

<br>
<br>

- **`sudo`**
  - The command begins with `sudo`, which temporarily grants **root-level privileges**.

**User management operations modify critical system files such as:**

```bash
/etc/passwd
/etc/shadow
/etc/group
```

Because these files control authentication and system identity, only the root user is allowed to modify them.

---

<br>
<br>

- **`useradd`**
  - `useradd` is the standard Linux utility used to create new user accounts.

**When executed, the command performs several internal operations:**

1. Assigns a new **UID (User Identifier)**.
2. Creates a **primary group** for the user.
3. Adds the user entry into `/etc/passwd`.
4. Creates an entry in `/etc/shadow` for password storage.
5. Assigns default account policies.

These operations register the user with the operating system.

---

<br>
<br>

- **Username: `anita`**
  - The argument `anita` becomes the login name of the account.
  - Although humans identify users by name, Linux internally tracks users using numeric identifiers called **UIDs**.

**Example mapping:**

```bash
anita → UID 1003
```

Files created by this user will be owned by UID 1003 even though the system displays the username.

---

<br>
<br>

- **`--expiredate` Option**
  - The `--expiredate` flag tells Linux to disable the account after a specific date.

```bash
--expiredate 2024-01-28
```

- The date must be written in the **YYYY-MM-DD format**.
- When the system clock reaches this date, Linux marks the account as expired.
- Important detail: the account is **disabled, not deleted**.

**This means:**
* The user cannot log in anymore
* The home directory still exists
* The user's files remain untouched
* The account entry remains in the system databases

This behavior is useful for auditing and data retention purposes.

---

<br>
<br>

# Verifying the Account Expiry

After creating the account, administrators usually verify that the expiry policy has been applied correctly.

**The command used for this is:**

```bash
sudo chage -l anita

# chage is the utility for managing user account aging policies, and the -l option lists all the policies applied to the user anita, including the account expiration date. This allows administrators to confirm that the expiry date is set as intended.
```

**Example output:**

```bash
Account expires : Jan 28, 2024
```

The `chage` utility is used to manage **user account aging policies**.

---

<br>
<br>

- **`chage` Command**

The name `chage` stands for **change age**.

**This command allows administrators to manage several account lifecycle settings, including:**

* password expiration
* password warning period
* account inactivity timeout
* account expiration date

---

<br>
<br>

- **`-l` Option**

The `-l` option means **list**.

When used with `chage`, it displays all aging policies applied to the user account.

**Example command:**

```bash
chage -l anita
```

This provides a quick audit view of the account configuration.

---

<br>
<br>

# How Linux Implements Account Expiry Internally

- The expiration policy is stored in the `/etc/shadow` file.

- Unlike `/etc/passwd`, which contains public account information, `/etc/shadow` stores sensitive authentication data including password hashes and aging policies.

**A typical shadow entry may look like this:**

```bash
anita:$6$hashvalue:19720:0:99999:7::19744:

# === Breakdown ===:
# anita          - username
# $6$hashvalue   - password hash
# 19720          - last password change (days since Jan 1, 1970)
# 0              - minimum password age (days)
# 99999          - maximum password age (days)
# 7              - password warning period (days)
#                - inactive account period (days)
# 19744          - account expiration date (days since Jan 1, 1970)
```

- Each field controls different aspects of password and account aging.

- The expiration date is stored as the **number of days since January 1, 1970**, which is the Unix epoch used by Linux systems.

- When a login attempt occurs, the authentication system checks the current system date against this stored value.

- If the expiration date has passed, the login attempt is rejected.

---

<br>
<br>

# Difference Between Account Expiry and Password Expiry

Many beginners confuse these two policies, but they serve different purposes.

**Account Expiry**

* Disables the entire user account
* Login attempts fail completely
* Used for temporary users

**Password Expiry**

* Forces the user to change their password
* The account remains active
* Used for security compliance

**Example command for password expiry:**

```bash
chage -M 90 anita

# -M specifies the maximum number of days a password is valid. After 90 days, the user will be prompted to change their password at the next login.
```

This forces the user to change their password every 90 days.

---

<br>
<br>

# Why DevOps Teams Use Expiring Accounts

Automatic account expiration provides several advantages in modern infrastructure environments.

- **Improved Security**: Temporary accounts automatically deactivate after the project or contract ends, preventing unauthorized access.

- **Reduced Administrative Work**: Administrators do not need to manually disable accounts or track expiry dates.

- **Compliance Requirements**: Many organizations follow strict security frameworks such as ISO 27001 or SOC 2. These frameworks require limiting access duration for temporary users.

Automating expiration helps enforce those policies.

---

<br>
<br>

# Additional Commands to Explore

**Create a user with an expiry date and home directory:**

```bash
sudo useradd -m devuser --expiredate 2024-06-01

# -m creates a home directory for the user, which is useful if the temporary user needs to store files or configurations during their access period.
```

**Modify the expiry date of an existing user:**

```bash
sudo chage -E 2024-02-10 anita

# -E specifies a new account expiration date. This allows administrators to extend or shorten the access period for an existing user without needing to recreate the account.
```

**Remove the expiration date completely:**

```bash
sudo chage -E -1 anita

# -1 removes any expiration date, making the account active indefinitely until manually disabled or deleted.
```

**Lock the account immediately:**

```bash
sudo usermod -L anita

# -L locks the user account, preventing all login attempts without changing the expiration date. This is useful for emergency situations where immediate access needs to be revoked.
```

**Unlock the account:**

```bash
sudo usermod -U anita

# -U unlocks a previously locked account, allowing the user to log in again if the account is still active.
```

<br>
<br>

The above mentioned command will only work for system users not for LDAP users. For LDAP users, the account expiry is managed through the LDAP directory and not through local system commands.

---

<br>
<br>

# Practical Outcome

**After running the creation command:**

* The user `anita` can log into the server immediately
* The account will automatically expire on **January 28, 2024**
* The account remains stored for auditing purposes

This configuration pattern is widely used across production systems to manage temporary access safely and efficiently.
