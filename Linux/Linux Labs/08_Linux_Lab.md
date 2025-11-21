# Linux Lab 8: Working With Shell 2 - Advanced Operations

This lab advances your shell skills by introducing file archiving (`tar`), compression (`gzip`), file searching (`find`, `grep`), and the powerful concepts of I/O redirection (`>`, `>>`, `2>`) and piping (`|`).

## Table of Contents
- [Linux Lab 8: Working With Shell 2 - Advanced Operations](#linux-lab-8-working-with-shell-2---advanced-operations)
  - [Table of Contents](#table-of-contents)
    - [Key Concepts](#key-concepts)
    - [Step-by-Step Walkthrough](#step-by-step-walkthrough)
      - [1. Switching to Superuser (sudo su)](#1-switching-to-superuser-sudo-su)
      - [2. Archiving and Compressing (tar \& gzip)](#2-archiving-and-compressing-tar--gzip)
      - [3. Decompressing Files (gunzip)](#3-decompressing-files-gunzip)
      - [4. Finding Files by Name (find)](#4-finding-files-by-name-find)
      - [5. Redirecting Output (\>)](#5-redirecting-output-)
      - [6. Searching Inside Files (grep)](#6-searching-inside-files-grep)
      - [7. Creating Files with Redirection](#7-creating-files-with-redirection)
      - [8. Handling Standard Error (2\>)](#8-handling-standard-error-2)
      - [9. Piping Commands (|)](#9-piping-commands-)
    - [Command Reference](#command-reference)

---

### Key Concepts
<a name="key-concepts"></a>

* **Archiving vs. Compression:**
    * **Archiving (`tar`):** Bundling multiple files/folders into a single file (tape archive). It does *not* reduce size.
    * **Compression (`gzip`):** Reducing the size of a file. Often used together (e.g., `.tar.gz`).
* **Redirection:** Changing where command input comes from or output goes to.
    * `>`: Redirect standard output (stdout) to a file (overwrite).
    * `>>`: Redirect stdout to a file (append).
    * `2>`: Redirect standard error (stderr) to a file.
* **Piping (`|`):** Taking the output of one command and using it as the input for the next command.
* **Searching:**
    * `find`: Search for files by name, size, time, etc.
    * `grep`: Search for text *inside* files.

---

### Step-by-Step Walkthrough
<a name="step-by-step-walkthrough"></a>

#### 1. Switching to Superuser (sudo su)
<a name="1-switching-to-superuser-sudo-su"></a>
**Tip:** Instead of typing `sudo` before every command, you can switch to the root user shell.
**Command:** `sudo su`
* **Why?** It keeps you in superuser mode until you type `exit`.
* **Caution:** Be very careful running commands as root!

#### 2. Archiving and Compressing (tar & gzip)
<a name="2-archiving-and-compressing-tar--gzip"></a>
**Task:** Create a tarball of `/home/bob/reptile/snake/python` and compress it.
**Commands:**
1.  `tar -cf /home/bob/python.tar /home/bob/reptile/snake/python`
2.  `gzip /home/bob/python.tar`

**Explanation:**
* `tar`: The archiving utility.
    * `-c`: **Create** a new archive.
    * `-f`: **File**. Tells tar that the next argument is the name of the archive file to create (`/home/bob/python.tar`).
    * The last argument is the source directory to archive.
* `gzip`: Compresses the file in place. `/home/bob/python.tar` becomes `/home/bob/python.tar.gz`.

#### 3. Decompressing Files (gunzip)
<a name="3-decompressing-files-gunzip"></a>
**Task:** Extract `eaglet.dat.gz`.
**Command:** `gunzip /home/bob/birds/eagle/eaglet.dat.gz`

**Explanation:**
* `gunzip` (GNU unzip) decompresses the file.
* It removes the `.gz` extension, leaving you with the original `eaglet.dat`.

#### 4. Finding Files by Name (find)
<a name="4-finding-files-by-name-find"></a>
**Task:** Find the file `caleston-code` inside `/opt`.
**Command:** `sudo find /opt -name caleston-code`
**Output:** `/opt/test/test123/caleston/caleston-code`

**Explanation:**
* `find`: The utility for searching directory trees.
* `/opt`: The starting directory for the search.
* `-name`: Specifies the criteria (search by filename).

#### 5. Redirecting Output (>)
<a name="5-redirecting-output-"></a>
**Task:** Find `dummy.service` in `/etc` and save the path to `/home/bob/dummy-service`.
**Commands:**
1.  `sudo find /etc -name dummy.service` (To find the path: `/etc/systemd/system/dummy.service`)
2.  `echo /etc/systemd/system/dummy.service > /home/bob/dummy-service`

**Explanation:**
* `>` is the **redirect operator**.
* It takes the output of `echo` (which is just the text path) and writes it into the file `/home/bob/dummy-service`.
* If the file didn't exist, it's created. If it did, it's overwritten.

#### 6. Searching Inside Files (grep)
<a name="6-searching-inside-files-grep"></a>
**Task:** Find the file in `/etc` containing string `172.16.238.197` and save the result path.
**Command:** `sudo grep -ir 172.16.238.197 /etc/ > /home/bob/ip`

**Explanation:**
* `grep`: **G**lobal **R**egular **E**xpression **P**rint. Searches text.
* `-i`: **Ignore case** (not strictly needed for numbers, but good habit).
* `-r`: **Recursive**. Search all files in `/etc` and its subdirectories.
* `>`: Redirects the matching line (which includes the filename) to `/home/bob/ip`.

#### 7. Creating Files with Redirection
<a name="7-creating-files-with-redirection"></a>
**Task:** Create a file with specific text content.
**Command:** `echo "a file in my home directory" > /home/bob/file_with_data.txt`

**Explanation:**
This is the fastest way to create a small text file. `echo` prints the text, and `>` captures it into the file.

#### 8. Handling Standard Error (2>)
<a name="8-handling-standard-error-2"></a>
**Task:** Run a failing python script and capture the error message.
**Command:** `python3 /home/bob/my_python_test.py 2> /home/bob/py_error.txt`

**Explanation:**
* Linux commands have two output streams:
    * **Standard Output (stdout - 1):** Normal program output.
    * **Standard Error (stderr - 2):** Error messages.
* `2>` tells the shell: "Take stream 2 (errors) and redirect it to this file."
* If you just used `>`, the error message would still print to the screen, and the file would be empty.

#### 9. Piping Commands (|)
<a name="9-piping-commands-"></a>
**Task:** Read a compressed file without extracting it and save the content.
**Command:** `zcat /usr/share/man/man1/tail.1.gz | tee /home/bob/pipes`

**Explanation:**
* `zcat`: Like `cat`, but for compressed `.gz` files. It decompresses the content to stdout without changing the original file.
* `|` (Pipe): Takes the output of `zcat` and feeds it as input to `tee`.
* `tee`: Reads from standard input and writes to **both** standard output (screen) and the specified file (`/home/bob/pipes`). It splits the stream like a T-pipe.

---

### Command Reference
<a name="command-reference"></a>

| Command | Name | Purpose | Example |
| :--- | :--- | :--- | :--- |
| `tar` | Tape Archive | Bundles files together | `tar -cf archive.tar folder/` |
| `gzip` | GNU Zip | Compresses files | `gzip file.tar` |
| `gunzip`| GNU Unzip | Decompresses files | `gunzip file.gz` |
| `find` | Find | Searches for files in a directory hierarchy | `find /var -name "*.log"` |
| `grep` | Grep | Searches for text patterns inside files | `grep -r "error" /var/log` |
| `>` | Redirect | Redirects stdout to a file (overwrite) | `echo "hello" > hello.txt` |
| `2>` | Redirect Error | Redirects stderr to a file | `command 2> error.log` |
| `|` | Pipe | Connects stdout of one command to stdin of another | `ls | grep "txt"` |
| `zcat` | Z-Cat | Displays contents of compressed files | `zcat file.gz` |
| `tee` | Tee | Reads stdin and writes to stdout and files | `echo "hi" | tee file.txt` |

  