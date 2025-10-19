<center><h1>DevOps Day 2<br>Creating a User with an Expiry Date</h1></center>
<br>
In the 100 Days of DevOps challenge, I managed temporary user access for a limited-time developer, '`anita`', by creating her account and ensuring it would expire on a specific date.

## Table of Contents
- [Table of Contents](#table-of-contents)
  - [The Task](#the-task)
  - [My Solution \& Command Breakdown](#my-solution--command-breakdown)
    - [1. The Creation Command](#1-the-creation-command)
    - [2. The Verification Command](#2-the-verification-command)
  - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
  - [Deep Dive: How Account Expiry Works](#deep-dive-how-account-expiry-works)
  - [Exploring the Commands Used](#exploring-the-commands-used)

---

### The Task
<a name="the-task"></a>
A developer named `anita` needed temporary access to `App Server 3`.
1.  Create a user account named `anita`.
2.  Set the account to expire on **January 28, 2024**.

---

### My Solution & Command Breakdown
<a name="my-solution--command-breakdown"></a>
- After connecting to `App Server 3` via SSH, I used two commands: one to create the user and another to verify the expiry date was set correctly.

#### 1. The Creation Command
- This command creates the user `anita` and sets the account expiration date in a single step.

```bash
sudo useradd anita --expiredate 2024-01-28
```

**Command Breakdown:**
* `--expiredate`: This option is used with `useradd` to set the date when the user account should automatically expire (get disabled). The date must be written in the format `YYYY-MM-DD`.

#### 2. The Verification Command
- To confirm the expiry date was applied, I used the `chage` (change age) utility.

```bash
sudo chage -l anita

# OUTPUT:
# Account expires						: Jan 28, 2024
```
This command displayed all the aging policies for the `anita` account.

**Command Breakdown:**
* `chage`: Command-line tool for viewing and modifying user password and account aging information.
* `-l`: The "list" flag, which instructs `chage` to display the current settings for a user.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
This task shows how security policies can be automated. In real situations, many contractors or temporary workers need short-term access. Manually remembering to disable all those accounts is time-consuming and easy to forget.

-   **Better Security**: Temporary accounts can become dangerous if left active after someone leaves — these forgotten or “ghost” accounts are big security risks. Setting an expiry date makes sure access ends automatically, keeping the system safe.
-   **Less Mannual Work**: I don’t have to set reminders or create support tickets to disable accounts later. The system does it for me, which follows a key DevOps idea — automate repetitive tasks.
-   **Compliance Made Ease**: Many companies have rules about how long temporary users can have access. Using `--expiredate` helps enforce those rules automatically.

---

### Deep Dive: How Account Expiry Works
<a name="deep-dive-how-account-expiry-works"></a>
In Linux, when an account expires, it means the account is disabled, not deleted.

When the system date reaches `2024-01-28`, here’s what happens to the anita account:
- **Disabled** → Anita can’t log in anymore; every login attempt fails.
- **Not Deleted** → Her files and home folder (/home/anita) still exist, and her entry remains in /etc/passwd.

This is actually the ideal behavior — the account is blocked, but her data stays safe for auditing or record-keeping.
If needed, an admin can easily re-enable the account later by updating or removing the expiry date.

👉 **Note**: This is not the same as password expiry. Password expiry only forces the user to change their password — it doesn’t disable their account.

---

### Exploring the Commands Used
<a name="exploring-the-commands-used"></a>
* `chage`: This command is used for managing the lifecycle of a user's password and account. The `-l` flag is great for auditing, and I can see it has other options to *set* policies like password expiration, inactivity periods, and warning days.