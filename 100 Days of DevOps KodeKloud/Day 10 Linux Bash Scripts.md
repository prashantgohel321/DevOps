# DevOps Day 10: Automating Backups with a Bash Script

Today's task was a practical and exciting challenge that brought together many of the skills I've been learning. I was tasked with creating a bash script to automate the process of backing up a website. This wasn't just about writing code; it was about preparing the server environment to allow the automation to run seamlessly, which is a core concept in DevOps.

I learned that successful automation is often a two-part process: first, the one-time setup of prerequisites (like permissions and SSH keys), and second, the writing of the script itself. Getting the foundation right is the key to making the automation work.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
    - [Part 1: The Critical Prerequisite Setup](#part-1-the-critical-prerequisite-setup)
    - [Part 2: Writing the Backup Script](#part-2-writing-the-backup-script)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: Why Password-less SSH is Non-Negotiable for Automation](#deep-dive-why-password-less-ssh-is-non-negotiable-for-automation)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands Used](#exploring-the-commands-used)

---

### The Task
<a name="the-task"></a>
My objective was to create a bash script named `news_backup.sh` on **App Server 2** that would perform a multi-step backup process. The requirements were:
1.  The script must live in the `/scripts` directory.
2.  It needed to create a `.zip` archive of the website's files located at `/var/www/html/news`.
3.  The archive must be named `xfusioncorp_news.zip` and saved locally in `/backup`.
4.  The script then had to copy this archive to the **Nautilus Backup Server** into its `/backup` directory.
5.  Crucially, the script must run without any password prompts, and my user (`steve`) must be able to execute it.
6.  The `zip` utility had to be installed manually before running the script.
7.  I was not allowed to use `sudo` inside the script.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
I broke my approach into two distinct phases: preparing the environment and then writing the script.

#### Part 1: The Critical Prerequisite Setup
<a name="part-1-the-critical-prerequisite-setup"></a>
I performed these one-time setup steps on **App Server 2** as the `steve` user.

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
With the environment fully prepared, I was ready to write the script.

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
-   **`zip` Command:** Archiving is a standard part of any backup process. It compresses many files and directories into a single, manageable file, making it much easier and faster to store and transfer. The `-r` (recursive) flag was essential to include all the contents of the `news` directory.
-   **`scp` (Secure Copy):** This command copies files between servers over a secure SSH connection. It's the standard tool for simple, secure file transfers.

---

### Deep Dive: Why Password-less SSH is Non-Negotiable for Automation
<a name="deep-dive-why-password-less-ssh-is-non-negotiable-for-automation"></a>
This task drove home a lesson I first learned on Day 7. Automation, by definition, must run without human intervention. A script that stops and waits for a password is a broken script.

The Public Key Authentication I set up is the industry-standard solution.

1.  **The Trust Relationship:** By using `ssh-copy-id`, I established a one-way trust. I placed a "public lock" from App Server 2 onto the Backup Server.
2.  **The Secure Handshake:** When my script runs `scp`, App Server 2 uses its "private key" to prove its identity to the Backup Server.
3.  **Seamless Execution:** The Backup Server verifies this proof and allows the file transfer to happen instantly and securely, without ever needing a password.

This is the fundamental mechanism that allows tools like Ansible, Jenkins, and custom scripts to manage entire fleets of servers automatically.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Forgetting to Install `zip`:** The script would fail immediately at the `zip` command if the package wasn't installed first.
-   **Incorrect Permissions:** If I hadn't used `chown` on the `/scripts` and `/backup` directories, my script (running as `steve`) would have failed with a "Permission denied" error when trying to create the script or the archive.
-   **Skipping the SSH Key Setup:** Without setting up the SSH keys, the `scp` command in the script would have stopped and prompted for a password, failing the automation requirement.
-   **Using `sudo` in the Script:** The task explicitly forbade this. Relying on correct ownership and permissions for the user running the script is a much cleaner and more secure approach than embedding `sudo` commands within it.

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
  