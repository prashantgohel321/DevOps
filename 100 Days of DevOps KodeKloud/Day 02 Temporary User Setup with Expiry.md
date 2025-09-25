# Day 2: Creating a User with an Expiry Date

For my second task in the 100 Days of DevOps challenge, I had to manage temporary user access. The scenario involved a developer, `anita`, who needed access to a server for a limited time. My job was to create her account but ensure it would automatically expire on a specific date.

This was a practical exercise in user lifecycle management and a crucial security practice.

<img src="SS/Day02.png">

## Table of Contents
- [The Task](#the-task)
- [My Solution & Command Breakdown](#my-solution--command-breakdown)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: How Account Expiry Works](#deep-dive-how-account-expiry-works)
- [Exploring the Commands Used](#exploring-the-commands-used)

---

### The Task
<a name="the-task"></a>
A developer named `anita` needed temporary access to `App Server 3`. My specific instructions were:
1.  Create a user account named `anita`.
2.  Set the account to expire on **January 28, 2024**.

---

### My Solution & Command Breakdown
<a name="my-solution--command-breakdown"></a>
After connecting to `App Server 3` via SSH, I used two commands: one to create the user and another to verify the expiry date was set correctly.

#### 1. The Creation Command
This command creates the user `anita` and sets the account expiration date in a single step.

```bash
sudo useradd anita --expiredate 2024-01-28
```

**Command Breakdown:**
* `sudo`: I used this to execute the command with root privileges, which is necessary for user management.
* `useradd`: The standard Linux utility for creating new user accounts.
* `anita`: The username for the new account.
* `--expiredate`: This is the key flag for this task. It tells `useradd` to set a date on which the account will be disabled. The date format required is `YYYY-MM-DD`.
* `2024-01-28`: The specific expiration date I was instructed to set.

#### 2. The Verification Command
To confirm the expiry date was applied, I used the `chage` (change age) utility.

```bash
sudo chage -l anita
```
This command displayed all the aging policies for the `anita` account, and I saw this crucial line in the output, which confirmed my success:
`Account expires						: Jan 28, 2024`

**Command Breakdown:**
* `sudo`: `chage` also needs administrative privileges to view user account details.
* `chage`: A command-line tool for viewing and modifying user password and account aging information.
* `-l`: The "list" flag, which instructs `chage` to display the current settings for a user.
* `anita`: The user account I wanted to inspect.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
This task is a perfect example of **automating security policies**. In a real-world scenario, you might have dozens of contractors, vendors, or temporary employees who need access. Manually tracking when to disable each account is inefficient and prone to human error.

-   **Enhanced Security**: The biggest risk with temporary accounts is that they are forgotten and left active after the person has left. These "ghost" accounts become a major security vulnerability. By setting an expiry date, I ensured that access is automatically revoked, closing this security hole without any further action from me.
-   **Reduced Administrative Overhead**: I don't need to create a ticket or set a calendar reminder to disable `anita`'s account in the future. The system handles it for me. This is a core principle of DevOps—automating operational tasks to improve efficiency and reliability.
-   **Enforcing Compliance**: Many organizations have strict policies about temporary access. Using features like `--expiredate` helps enforce these policies at a technical level.

---

### Deep Dive: How Account Expiry Works
<a name="deep-dive-how-account-expiry-works"></a>
It's important to understand what "expiring" an account means in Linux.

When the system clock reaches `2024-01-28`, the `anita` account is **disabled**, not deleted.
* **Disabled**: The user can no longer log in. Any attempt to authenticate as `anita` will fail.
* **Not Deleted**: The user's home directory (`/home/anita`) and all of their files are still on the system. The user's entry still exists in `/etc/passwd`.

This is the desired behavior. You typically want to preserve the user's data for auditing or archival purposes, even after their access is revoked. An administrator can easily re-enable the account later by setting a new expiry date or removing it entirely.

This is different from **password expiry**, which forces a user to change their password after a certain period but does not disable the account itself.

---

### Exploring the Commands Used
<a name="exploring-the-commands-used"></a>
This task introduced me to two powerful user management utilities.

* `useradd`: My go-to command for creating users. I'm learning that it has many useful flags like `-s` (from Day 1) for setting a shell and `--expiredate` for setting an expiry date, allowing me to configure accounts precisely from the start.
* `chage`: This command seems to be the central tool for managing the lifecycle of a user's password and account. The `-l` flag is great for auditing, and I can see it has other options to *set* policies like password expiration, inactivity periods, and warning days.
