# Linux Lab 13: Permissions and Ownership

This lab was a comprehensive exercise in understanding and manipulating file system permissions in Linux. I learned how to interpret the permission string (`rwxr-xr-x`), how to change permissions using both octal (`755`) and symbolic (`g+w`) notation, and how to change file ownership, including recursive operations.

This document details the step-by-step process I followed to complete the lab.

## Table of Contents
- [Linux Lab 13: Permissions and Ownership](#linux-lab-13-permissions-and-ownership)
  - [Table of Contents](#table-of-contents)
    - [The Tasks](#the-tasks)
    - [My Step-by-Step Solution](#my-step-by-step-solution)
      - [Phase 1: Inspection](#phase-1-inspection)
      - [Phase 2: Modifying Permissions](#phase-2-modifying-permissions)
      - [Phase 3: Changing Ownership](#phase-3-changing-ownership)
    - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
    - [Deep Dive: Decoding Permissions](#deep-dive-decoding-permissions)
    - [Common Pitfalls](#common-pitfalls)
    - [Exploring the Commands Used](#exploring-the-commands-used)

---

### The Tasks
<a name="the-tasks"></a>
My objectives were:
1.  Inspect permissions for a directory (`sports`).
2.  Understand the owner, group, and "other" permission sets.
3.  Modify permissions for a file (`soccer`) to remove write access for group/others.
4.  Modify permissions again to add write access for the group and remove all access for others.
5.  Change the ownership of a file to a service account (`mercury`).
6.  Recursively change the ownership of an entire directory structure.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>

#### Phase 1: Inspection
1.  **Check Directory Permissions:** I used `ls -ld /home/bob/sports` to inspect the directory itself, not its contents.
    -   Output: `drwxr-x--- 2 bob bob ...`
    -   **Owner Permissions:** `rwx` (Read, Write, Execute) - Full control.
    -   **Group Permissions:** `r-x` (Read, Execute) - Can view files and enter the directory.
    -   **Other Permissions:** `---` (None) - No access at all.
    -   **Owner:** `bob`.

#### Phase 2: Modifying Permissions
2.  **Restrict File Permissions:** A file `soccer` had full permissions (`rwxrwxrwx`). I needed to change it so the group and others only had read and execute.
    -   **Command:** `chmod 755 /home/bob/sports/soccer`
    -   **Result:** `-rwxr-xr-x` (Owner: `rwx`, Group: `r-x`, Others: `r-x`).

3.  **Fine-Tuning Permissions:** I then had to add write permission for the group and remove all permissions for others.
    -   **Command:** `chmod 770 /home/bob/sports/soccer`
    -   **Result:** `-rwxrwx---` (Owner: `rwx`, Group: `rwx`, Others: `---`).

#### Phase 3: Changing Ownership
4.  **Change File Owner:** I changed the owner of `soccer` to the user `mercury`.
    -   **Command:** `sudo chown mercury /home/bob/sports/soccer`
    -   *Note: This required `sudo` because I was giving away ownership of a file.*

5.  **Recursive Ownership Change:** Finally, I had to change the owner of the `sports` directory and *everything inside it* to `mercury`.
    -   **Command:** `sudo chown -R mercury /home/bob/sports`
    -   **Result:** Both the directory `sports` and the files inside (`soccer`, `football`) were now owned by `mercury`.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
-   **File Permissions**: In Linux, security starts at the file level. Every file has three sets of permissions for three categories of users. Understanding this is critical for protecting sensitive data and ensuring applications can run correctly.
-   **`chmod` (Change Mode)**: This is the command to change permissions.
    -   **Octal Notation (e.g., 755):** A shorthand way to set all permissions at once. `7` (rwx), `5` (r-x), `0` (---).
    -   **Symbolic Notation (e.g., g+w):** A readable way to modify specific permissions. `g` (group) `+` (add) `w` (write).
-   **`chown` (Change Owner)**: This command changes who owns the file. Only the root user (or a user with `sudo`) can give ownership to someone else.
-   **Recursive (`-R`)**: This flag is essential when managing directories. It tells the command to apply the change not just to the directory itself, but to every file and folder inside it, saving me from running the command dozens of times.

---

### Deep Dive: Decoding Permissions
<a name="deep-dive-decoding-permissions"></a>
The string `-rwxr-xr-x` contains a lot of information.

[Image of Linux file permission string breakdown]

1.  **Type:** The first character indicates the file type. `-` is a file, `d` is a directory.
2.  **Owner (User):** The next three characters (`rwx`).
    -   `r` = 4 (Read)
    -   `w` = 2 (Write)
    -   `x` = 1 (Execute)
    -   Sum: 4+2+1 = **7**
3.  **Group:** The middle three characters (`r-x`).
    -   `r` = 4
    -   `-` = 0
    -   `x` = 1
    -   Sum: 4+0+1 = **5**
4.  **Others:** The final three characters (`r-x`).
    -   Sum: **5**

So, `rwxr-xr-x` translates to the octal code **755**.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Confusing File vs. Directory Permissions:**
    -   **Read:** On a file, you can see contents. On a directory, you can list files (`ls`).
    -   **Write:** On a file, you can edit contents. On a directory, you can create/delete files.
    -   **Execute:** On a file, you can run it as a script. On a directory, you can enter it (`cd`).
-   **Forgetting `sudo` for `chown`:** You cannot give away a file to another user without administrative privileges.
-   **Recursive Danger:** Be very careful with `chown -R` or `chmod -R`, especially on system directories. You can accidentally break your system by changing permissions on thousands of files at once.

---

### Exploring the Commands Used
<a name="exploring-the-commands-used"></a>
-   `ls -l`: List files in long format to see permissions and ownership.
-   `ls -ld [dir]`: List the directory *itself*, not its contents. Crucial for checking directory permissions.
-   `chmod [mode] [file]`: Change file permissions.
    -   `chmod 755 file`: Sets `rwxr-xr-x`.
    -   `chmod 770 file`: Sets `rwxrwx---`.
-   `chown [user] [file]`: Change the owner of a file.
-   `chown -R [user] [directory]`: Recursively change the owner of a directory and all its contents.
  