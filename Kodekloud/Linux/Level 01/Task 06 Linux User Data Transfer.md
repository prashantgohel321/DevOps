# Linux Level 1, Task 6: Targeted File Migration with `find`

Today's task was a classic system administration challenge that is incredibly common in the real world: I had to perform a targeted data migration. The scenario was that files from multiple users were mixed in a single directory structure, and I needed to extract all the files belonging to one specific user and copy them to a new location, all while keeping their original directory structure intact.

This was a fantastic lesson in combining the power of two fundamental Linux commands: `find` to locate the files and `cp` (with a special flag) to copy them correctly. This document is my detailed, first-person guide to that entire process.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: A Line-by-Line Breakdown of the `find` Command](#deep-dive-a-line-by-line-breakdown-of-the-find-command)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands I Used](#exploring-the-commands-i-used)

---

### The Task
<a name="the-task"></a>
My objective was to perform a selective file copy on **App Server 3**. The specific requirements were:
1.  Search within the `/home/usersdata` directory.
2.  Find all items that are **files** (not directories) owned by the user `kirsty`.
3.  Copy these files to the `/media` directory.
4.  Crucially, the original directory structure of the files must be preserved under the new location.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The process was very efficient, using a single, powerful command to accomplish the entire task.

#### Step 1: Connect to the Server
First, I needed to log into the correct server as a user with administrative privileges.
```bash
ssh banner@stapp03
```

#### Step 2: Find and Copy the Files
This was the core of the task. I chained the `find` and `cp` commands together using the `-exec` action.
```bash
find /home/usersdata -user kirsty -type f -exec sudo cp --parents {} /media \;
```
This single line of code searched the entire directory tree, found every file owned by `kirsty`, and then for each file, it ran a `cp` command that intelligently created the necessary parent directories at the destination before copying the file.

#### Step 3: Verification
The final and most important step was to confirm that the files were copied to the correct location with the directory structure intact.
1.  I used the `ls` command with the `-R` (recursive) flag to list the contents of the new directory structure.
    ```bash
    sudo ls -lR /media/home/usersdata
    ```
2.  The output showed the directory tree from `/home/usersdata` had been perfectly recreated under `/media`, and all the files listed were owned by `kirsty`. This was the definitive proof of success.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
-   **The `find` command**: This is the master search utility in Linux. It can recursively search a directory tree for files and directories that match a wide range of criteria (name, size, owner, permissions, modification time, etc.). It's an essential tool for any sysadmin.
-   **The `cp --parents` command**: This is the secret to solving this task efficiently. Normally, `cp file /dest/` just copies the file. But the `--parents` flag is a special option that tells `cp`, "Look at the source file's full path. At the destination, create that same directory structure first, and then copy the file." This is exactly what's needed to preserve a directory tree.
-   **Why not a simple `cp -r`?**: Running `sudo cp -r /home/usersdata /media` would have copied *everything*—all files from all users—which would have failed the task. The challenge was to be selective, which is why the `find` command was necessary to filter the files first.

---

### Deep Dive: A Line-by-Line Breakdown of the `find` Command
<a name="deep-dive-a-line-by-line-breakdown-of-the-find-command"></a>
The single command I used is a powerful combination of search criteria and an action.

[Image of files being selectively copied while preserving structure]

`find /home/usersdata -user kirsty -type f -exec sudo cp --parents {} /media \;`

1.  **`find /home/usersdata`**:
    -   **`find`**: The command itself.
    -   **`/home/usersdata`**: The starting point. `find` will look in this directory and all of its subdirectories.

2.  **`-user kirsty -type f`**:
    -   These are the "predicates" or filters. `find` will only consider items that match *all* of these conditions.
    -   **`-user kirsty`**: Matches only if the file or directory is owned by the user `kirsty`.
    -   **`-type f`**: Matches only if the item is a regular **f**ile (not a directory, link, or other special file type).

3.  **`-exec sudo cp --parents {} /media \;`**:
    -   This is the "action." For every single file that matches the predicates, `find` will execute this command.
    -   **`-exec`**: Tells `find` to execute the following command.
    -   **`sudo cp --parents`**: The command to be run. I used `sudo` because the `/media` directory is owned by `root`.
    -   **`{}`**: This is a special placeholder. `find` automatically replaces `{}` with the full path of the file it has just found (e.g., `/home/usersdata/projectA/report.txt`).
    -   **`/media`**: The destination for the `cp` command.
    -   **`\;`**: This is a required terminator. It tells `find` where the `-exec` command ends.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Forgetting `--parents`:** If I had just used `sudo cp {} /media`, all the files found (e.g., `report.txt`, `notes.txt`) would have been dumped directly into the `/media` directory, completely flattening the structure and overwriting any files with the same name.
-   **Forgetting `-type f`:** If I had left this out, `find` would have also matched directories owned by `kirsty`. The `cp --parents` command would then behave differently and might not produce the desired outcome. Filtering for files only makes the command's behavior precise and predictable.
-   **Permissions:** Forgetting to use `sudo` on the `cp` command would have resulted in "Permission denied" errors, as my regular user cannot write to the `/media` directory.

---

### Exploring the Commands I Used
<a name="exploring-the-commands-i-used"></a>
-   `find /home/usersdata -user kirsty -type f -exec sudo cp --parents {} /media \;`: The primary, all-in-one command for this task. It finds and selectively copies files while preserving their directory structure.
-   `sudo ls -lR /media/home/usersdata`: My verification command.
    -   `ls`: The **l**i**s**t command.
    -   `-l`: Shows the **l**ong format (permissions, owner, size, etc.).
    -   `-R`: Makes the listing **R**ecursive, showing the contents of all subdirectories, which was essential for confirming the structure was preserved.
-   `ls -la /home/usersdata | grep kirsty`: An alternative investigation command.
    -   **What it does:** It lists all files (including hidden ones with `-a`) in the *top level* of `/home/usersdata` and then uses `grep` to show only the lines containing the word "kirsty".
    -   **Why it's not a complete solution:** This command is good for a quick look, but it's not powerful enough for this task. It is **not recursive**, so it would not find any files in subdirectories. It also might give false positives if a file was owned by another user but was in the `kirsty` group, or if "kirsty" was in the filename itself. The `find` command is far more precise and powerful.
   