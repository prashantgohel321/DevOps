<center><h1>Day 4<br>Setting Executable Permissions on a Script</h1></center>
<br>
I was tasked with making a shell script executable, as the system required the necessary permissions to run the new backup script.

## Table of Contents
- [Table of Contents](#table-of-contents)
  - [The Task](#the-task)
  - [My Solution \& Command Breakdown](#my-solution--command-breakdown)
    - [1. The Verification Command (Before)](#1-the-verification-command-before)
    - [2. The Permission Change Command](#2-the-permission-change-command)
    - [3. The Verification Command (After)](#3-the-verification-command-after)
  - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
  - [Deep Dive: Understanding Linux File Permissions](#deep-dive-understanding-linux-file-permissions)
  - [Exploring the Commands Used](#exploring-the-commands-used)

---

<br>
<br>

### The Task
<a name="the-task"></a>
The task involved granting executable permissions to a bash script named `xfusioncorp.sh` on `App Server 2` and ensuring all system users could execute it.

---

<br>
<br>

### My Solution & Command Breakdown
<a name="my-solution--command-breakdown"></a>
- After connecting to `App Server 2`, I first checked the existing permissions and then used a single command to change them.

#### 1. The Verification Command (Before)
- I used `ls -l` to get a detailed listing of the file.

```bash
ls -l /tmp/xfusioncorp.sh

# OUTPUT:
# -rw-r--r-- ...   -> confirmed that no one had execute (`x`) permissions.
```


#### 2. The Permission Change Command
I used the `chmod` (change mode) command to add the necessary permissions.

```bash
sudo chmod a+x /tmp/xfusioncorp.sh
```

**Command Breakdown:**
* `chmod`: The main command used to change file permissions.
* `a+x`: A symbolic way to add execute permission:
    * `a`: all users (owner, group, others)
    * `+`: add permission
    * `x`: execute permission


#### 3. The Verification Command (After)
I ran the `ls -l` command again to confirm my change was successful.
```bash
ls -l /tmp/xfusioncorp.sh

# OUTPUT:
# -rwxr-xr-x ...
```

---

<br>
<br>

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
This task is all about telling the operating system that a file is not just data to be read, but a program that can be run.

-   **Security**: By default, new files aren’t executable. This prevents random or downloaded files from running automatically, keeping the system safe. Linux makes sure only trusted scripts or programs can run.

-   **Operational Need**: Automation scripts need execute permission to work. In this case, the backup system (and admins testing it) must be able to run the script. Without `+x,` the system would block it with a “Permission Denied” error, even if the script is correct.

---

<br>
<br>

### Deep Dive: Understanding Linux File Permissions
<a name="deep-dive-understanding-linux-file-permissions"></a>
A permission string like `-rwxr-xr-x` has four parts:
- **File Type** → The first character shows the type: `-` = regular file, `d` = directory.
- **Owner Permissions** → Next three (rwx) are for the owner: read, write, execute.
- **Group Permissions** → Next three (r-x) are for the group: read and execute, but no write.
- **Other Permissions** → Last three (r-x) are for everyone else: read and execute, but no write.

**Two common ways to set permissions:**

- **Symbolic Notation** → Human-readable like `a+x` (all users add execute), `u+x `(user add execute), `g+w` (group add write), `o-r` (others remove read).
- **Octal/ Numeric Notation** → Each permission has a number: read=4, write=2, execute=1. Add them for each category:
- Owner rwx = 4+2+1 = 7
- Group r-x = 4+0+1 = 5
- Others r-x = 4+0+1 = 5
So `sudo chmod 755 /tmp/xfusioncorp.sh` does the same as setting `rwxr-xr-x`.

---

<br>
<br>

### Exploring the Commands Used
<a name="exploring-the-commands-used"></a>
This task introduced me to two of the most frequently used commands in Linux.

* `chmod`: Stands for **change mode**. It’s the main command to modify file or directory permissions. Learning both **symbolic** and **octal** ways to use it is very useful.
* `ls -l`: Lists files in `long` format. Shows not just filenames, but also permissions, owner, group, size, and last modified date. Essential for checking and troubleshooting permissions.
