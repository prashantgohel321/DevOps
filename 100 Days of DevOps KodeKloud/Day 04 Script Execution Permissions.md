# Day 4: Setting Executable Permissions on a Script

My task for Day 4 of the 100 Days of DevOps challenge was a fundamental one: making a shell script executable. A new backup script had been placed on a server, but the system was missing the necessary permissions to actually run it. My job was to fix that.

This exercise was a perfect introduction to the Linux permissions model, which is the foundation of the operating system's security.

## Table of Contents
- [The Task](#the-task)
- [My Solution & Command Breakdown](#my-solution--command-breakdown)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: Understanding Linux File Permissions](#deep-dive-understanding-linux-file-permissions)
- [Exploring the Commands Used](#exploring-the-commands-used)

---

### The Task
<a name="the-task"></a>
A bash script named `xfusioncorp.sh` was located in the `/tmp/` directory on `App Server 2`. It lacked executable permissions. My specific instructions were:
1.  Grant executable permissions to the `/tmp/xfusioncorp.sh` script.
2.  Ensure that **all users** on the system could execute it.

---

### My Solution & Command Breakdown
<a name="my-solution--command-breakdown"></a>
After connecting to `App Server 2`, I first checked the existing permissions and then used a single command to change them.

#### 1. The Verification Command (Before)
It's always good practice to see the state of something before you change it. I used `ls -l` to get a detailed listing of the file.

```bash
ls -l /tmp/xfusioncorp.sh
```
The output looked something like this: `-rw-r--r-- ...`, which confirmed that no one had execute (`x`) permissions.

#### 2. The Permission Change Command
I used the `chmod` (change mode) command to add the necessary permissions.

```bash
sudo chmod a+x /tmp/xfusioncorp.sh
```

**Command Breakdown:**
* `sudo`: The script was owned by the `root` user, so I needed administrative privileges to modify its permissions.
* `chmod`: This is the primary command for changing the access mode of a file.
* `a+x`: This is called "symbolic notation" and is very readable.
    * `a` stands for **all** users (which includes the owner, the group, and others).
    * `+` means to **add** a permission.
    * `x` stands for the **execute** permission.
* `/tmp/xfusioncorp.sh`: The path to the file I was modifying.

#### 3. The Verification Command (After)
I ran the `ls -l` command again to confirm my change was successful.
```bash
ls -l /tmp/xfusioncorp.sh
```
The output now showed the new permissions: `-rwxr-xr-x ...`. The presence of the `x` in all three permission groups confirmed that the task was complete. The filename also likely changed color in the terminal, providing a quick visual cue.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
This task is all about telling the operating system that a file is not just data to be read, but a program that can be run.

-   **Security Feature**: By default, new files are not executable. This is a crucial security feature. Imagine if you downloaded a text file from the internet, and it could immediately run as a program without your consent! By forcing an administrator to explicitly grant execute permissions, Linux ensures that only trusted scripts and programs can be run.
-   **Operational Requirement**: For an automation script to work, the user or service that needs to run it must have execute permissions. In this case, the backup system (and potentially any admin who needs to test it) required the ability to execute this script. Without the `+x` flag, the system would return a "Permission Denied" error, even if the script's code was perfect.

---

### Deep Dive: Understanding Linux File Permissions
<a name="deep-dive-understanding-linux-file-permissions"></a>
The permission string like `-rwxr-xr-x` can be broken down into four parts.

1.  **File Type**: The first character (`-`) indicates the file type. `-` means it's a regular file. `d` would mean it's a directory.
2.  **Owner Permissions**: The next three characters (`rwx`) are for the file's **owner**. This user can read, write, and execute the file.
3.  **Group Permissions**: The next three (`r-x`) are for the **group**. Members of this group can read and execute the file, but cannot write (modify) it.
4.  **Other Permissions**: The final three (`r-x`) are for **others** (everyone else). These users can also read and execute, but not write.

There are two common ways to set these permissions:

* **Symbolic Notation (what I used)**: `a+x`, `u+x` (user only), `g+w` (group add write), `o-r` (others remove read). It's very intuitive.
* **Octal (Numeric) Notation**: Each permission is assigned a number: `read=4`, `write=2`, `execute=1`. You add them up for each user category. The permissions I set (`rwxr-xr-x`) translate to:
    * Owner: `rwx` = 4 + 2 + 1 = **7**
    * Group: `r-x` = 4 + 0 + 1 = **5**
    * Others: `r-x` = 4 + 0 + 1 = **5**
    * So, `sudo chmod 755 /tmp/xfusioncorp.sh` would have achieved the exact same result.

---

### Exploring the Commands Used
<a name="exploring-the-commands-used"></a>
This task introduced me to two of the most frequently used commands in Linux.

* `chmod`: The "change mode" command. It's the only tool I need for modifying file and directory permissions. I can see how mastering both its symbolic and octal notations will be very useful.
* `ls -l`: The "list" command with the `-l` (long format) flag. It's my window into the metadata of the filesystem, showing me not just the filename, but also its permissions, owner, group, size, and modification date. It's an essential command for verification and troubleshooting.
