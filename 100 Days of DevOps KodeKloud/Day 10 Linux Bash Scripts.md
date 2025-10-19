<center><h1>DevOps Day 10<br>Automating Backups with a Bash Script</h1></center>
<br>

Today I was tasked with creating a bash script to automate website backup, a task that required preparing the server environment for seamless automation. Successful automation involves setting prerequisites and writing the script, which is crucial for a successful automation. Today I learned that a strong foundation is essential for successful automation.

## Table of Contents
- [Table of Contents](#table-of-contents)
  - [The Task](#the-task)
  - [My Step-by-Step Solution](#my-step-by-step-solution)
    - [Part 1: The Critical Prerequisite Setup](#part-1-the-critical-prerequisite-setup)
    - [Part 2: Writing the Backup Script](#part-2-writing-the-backup-script)
  - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
  - [Deep Dive: Why Password-less SSH is Non-Negotiable for Automation](#deep-dive-why-password-less-ssh-is-non-negotiable-for-automation)
  - [Common Pitfalls](#common-pitfalls)
  - [Exploring the Commands Used](#exploring-the-commands-used)

---

### The Task
<a name="the-task"></a>
I needed to create a bash script called `news_backup.sh` on App Server 2 to handle a multi-step backup. Requirements:

1. Script location → `/scripts` directory.
2. Backup website files → `/var/www/html/news` into a `.zip` archive.
3. Archive name → `xfusioncorp_news.zip`, saved locally in `/backup`.
4. Copy archive → Transfer it to the Nautilus Backup Server into `/backup`.
5. Password-less execution → My user (`steve`) must run it without prompts.
6. Prerequisite → zip utility must be installed manually before running the script.
7. Restriction → No `sudo` allowed inside the script.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
- I broke my approach into two distinct phases: preparing the environment and then writing the script.

#### Part 1: The Critical Prerequisite Setup
<a name="part-1-the-critical-prerequisite-setup"></a>
- I performed these one-time setup steps on **App Server 2** as the `steve` user.

1.  **Install `zip`:** The task required the `zip` utility for archiving.
    ```bash
    sudo yum install -y zip
    ```

2.  **Create and Own Directories:** The script needed a home (`/scripts`) and a place to store backups (`/backup`). I created them with `sudo` and then immediately changed their ownership to my user, `steve`. This was a key step to ensure my script could write to these locations without needing `sudo`.
    ```bash
    sudo mkdir -p /scripts /backup
    sudo chown steve:steve /scripts /backup
    ```

3.  **Establish Password-less SSH:** This was the most important prerequisite. To allow my script to copy a file to the backup server automatically, I set up SSH key-based authentication.
    * First, I generated a key pair for my user on App Server 2:
        ```bash
        ssh-keygen -t rsa
        # I pressed Enter for all prompts to accept defaults and set no passphrase.
        ```
    * Next, I used the `ssh-copy-id` utility to send my public key to the **Nautilus Backup Server**. I had to enter the backup server user's (`clint`) password one last time to authorize this.
        ```bash
        ssh-copy-id clint@stbkp01
        ```
    * Finally, I tested the connection to make sure it was truly password-less.
        ```bash
        ssh clint@stbkp01
        # It logged me in instantly. Success! I typed 'exit' to return.
        ```

#### Part 2: Writing the Backup Script
<a name="part-2-writing-the-backup-script"></a>
- With the environment fully prepared, I was ready to write the script.

1.  **Create and Edit the Script:** I created an empty, executable file in the correct location.
    ```bash
    touch /scripts/news_backup.sh
    chmod +x /scripts/news_backup.sh
    vi /scripts/news_backup.sh
    ```

2.  **The Script Content:** I added the following code into the file. I made sure to add comments to explain what each part of the script does.
    ```bash
    #!/bin/bash

    # This script creates a zip archive of the website directory,
    # saves it to a local backup folder, and then securely copies
    # it to a remote backup server.

    # Step 1: Create a recursive zip archive of the website files.
    # The archive is saved to the /backup directory.
    zip -r /backup/xfusioncorp_news.zip /var/www/html/news

    # Step 2: Copy the created archive to the backup server.
    # This scp command works without a password because of the
    # prerequisite SSH key setup.
    scp /backup/xfusioncorp_news.zip clint@stbkp01:/backup/
    ```

3.  **Execution and Verification:** After saving the script, I ran it and verified its success at each stage.
    ```bash
    # Execute the script
    /scripts/news_backup.sh

    # Verify the local backup was created
    ls -l /backup/xfusioncorp_news.zip

    # Verify the remote backup was copied successfully
    ssh clint@stbkp01 "ls -l /backup/xfusioncorp_news.zip"
    ```
Both verification commands showed the `xfusioncorp_news.zip` file, confirming my script had worked perfectly.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
-   **Bash Scripting:** This is the universal language for automation on Linux. By writing a script, I created a repeatable, reliable process that eliminates the chance of human error that comes with typing commands manually.
-   **`zip` Command:** Compresses files into a single archive. Using `-r` ensures all contents of `/var/www/html/news` are included, making storage and transfer easier.
-   **`scp` (Secure Copy):** Copies files between servers securely over SSH. It’s the standard tool for simple, safe file transfers.

---

### Deep Dive: Why Password-less SSH is Non-Negotiable for Automation
<a name="deep-dive-why-password-less-ssh-is-non-negotiable-for-automation"></a>
Automation must run without human intervention — a script that stops for a password is broken.

- **Public Key Authentication** → The industry-standard solution.
- **The Trust Relationship** → Using `ssh-copy-id`, I placed a “public lock” from App Server 2 onto the Backup Server.
- The** Secure Handshake** → When `scp` runs, App Server 2 proves its identity using its private key.
- **Seamless Execution** → The Backup Server verifies it and allows the file transfer instantly, no password needed.

This is how tools like Ansible, Jenkins, and scripts can manage servers automatically.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Forgetting to Install `zip`:** The script would fail immediately at the zip command.
-   **Incorrect Permissions:** Without `chown` on `/scripts` and `/backup`, `steve` couldn’t create the script or archive, causing “Permission denied” errors.
-   **Skipping the SSH Key Setup:** Without keys, `scp` would stop and ask for a password, breaking automation.
-   **Using `sudo` in the Script:** Proper ownership and permissions are safer and cleaner than embedding sudo.

---

### Exploring the Commands Used
<a name="exploring-the-commands-used"></a>
-   `sudo yum install -y zip`: Installs the zip utility.
-   `sudo mkdir -p /path`: Creates a directory and any parent directories that don't exist.
-   `sudo chown user:group /path`: Changes the owner and group of a file or directory.
-   `ssh-keygen -t rsa`: Generates a new SSH key pair.
-   `ssh-copy-id user@host`: Copies the public key to a remote host to enable password-less login.
-   `chmod +x /path/to/script.sh`: Makes a script executable.
-   `zip -r [archive.zip] [directory_to_zip]`: Recursively creates a zip archive.
-   `scp [source_file] [user@host:destination_path]`: Securely copies a file to a remote host.
  