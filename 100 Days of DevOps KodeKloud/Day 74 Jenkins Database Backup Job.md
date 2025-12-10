# DevOps Day 74: Automating a Multi-Server Database Backup

Today's task was a fantastic, real-world challenge that perfectly showcased the power of Jenkins as an orchestrator. My objective was to create an automated, scheduled job that would take a database backup from one server and store it on a separate backup server.

This was more than just a simple shell script; it required me to configure Jenkins to securely communicate with two different remote hosts and to handle a multi-step workflow. The solution I found, using a single remote execution step with `sshpass`, was a clever and efficient way to solve the problem. This document is my very detailed, first-person guide to that entire successful process.

## Table of Contents
- [DevOps Day 74: Automating a Multi-Server Database Backup](#devops-day-74-automating-a-multi-server-database-backup)
  - [Table of Contents](#table-of-contents)
    - [The Task](#the-task)
    - [My Step-by-Step Solution](#my-step-by-step-solution)
      - [Phase 1: Preparing Jenkins](#phase-1-preparing-jenkins)
      - [Phase 2: The Jenkins Job Configuration](#phase-2-the-jenkins-job-configuration)
    - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
    - [Deep Dive: The "Push" Backup Strategy and `sshpass`](#deep-dive-the-push-backup-strategy-and-sshpass)
    - [Common Pitfalls](#common-pitfalls)
    - [Exploring the UI and Commands I Used](#exploring-the-ui-and-commands-i-used)

---

### The Task
<a name="the-task"></a>
My objective was to create a scheduled Jenkins job named `database-backup` to automate a multi-server backup process. The requirements were:
1.  Connect to the **Database server** and create a `mysqldump` of the `kodekloud_db01` database.
2.  The dump file had to be named dynamically with the current date (e.g., `db_2025-10-14.sql`).
3.  This dump file then had to be copied to the **Backup Server** into the `/home/clint/db_backups` directory.
4.  The entire job had to be scheduled to run every 10 minutes (`*/10 * * * *`).

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
My successful solution involved preparing Jenkins to communicate with both servers and then writing a clever, two-part script within a single build step.

#### Phase 1: Preparing Jenkins
Before creating the job, I had to configure Jenkins to securely connect to both the DB and Backup servers.
1.  **Install SSH Plugin:** I logged into Jenkins as `admin`, went to `Manage Jenkins` > `Plugins`, and installed the **`SSH Plugin`** with a restart.
2.  **Add Credentials:** I went to `Manage Jenkins` > `Credentials` and added two `Username with password` credentials:
    -   One for the DB server (`peter`/`Sp!dy`), with ID `db-server-creds`.
    -   One for the Backup server (`clint`/`H@wk3y3`), with ID `backup-server-creds`.
3.  **Configure Global SSH Sites:** I went to `Manage Jenkins` > `System` and, in the "SSH remote hosts" section, added both `stdb01` and `stbkp01`, linking them to their respective credentials and testing the connection for each.

#### Phase 2: The Jenkins Job Configuration
1.  I created a `Freestyle project` named `database-backup`.
2.  In the **"Build Triggers"** section, I checked "Build periodically" and entered the schedule: `*/10 * * * *`.
3.  **This was the core of my solution:** In the **"Build Steps"** section, I added a single **"Execute shell script on remote host using ssh"** step.
    -   For the **SSH Site**, I selected the DB server: `peter@stdb01:22`.
    -   In the **Command** box, I wrote a script that would run entirely on the DB server. This script first creates the backup and then *pushes* it to the backup server using `sshpass`.
        ```bash
        # Define the dynamic filename
        DUMP_FILE="db_$(date +%F).sql"
        
        # Create the database dump locally on the DB server
        mysqldump -u kodekloud_roy -p'asdfgdsd' kodekloud_db01 > /tmp/$DUMP_FILE
        
        # Use sshpass to provide the password non-interactively and scp to push the file
        # The password for the 'clint' user on the backup server is 'H@wk3y3'
        sshpass -p 'H@wk3y3' scp -o StrictHostKeyChecking=no /tmp/$DUMP_FILE clint@stbkp01:/home/clint/db_backups/
        
        # Clean up the temporary file from the DB server
        rm /tmp/$DUMP_FILE
        ```
4.  I saved the job, ran it manually once, and checked the console output, which showed `Finished: SUCCESS`. A final check on the backup server confirmed the file was there.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **Jenkins as an Orchestrator**: This task perfectly demonstrated Jenkins's role as a central controller. It didn't just run a script; it connected to one server, performed a task, and then coordinated a file transfer to a second server.
-   **`mysqldump`**: This is the standard command-line utility for creating a logical backup (a `.sql` script) of a MySQL or MariaDB database. It's the foundation of most database backup strategies.
-   **Dynamic Filenames**: Hardcoding a backup filename is a bad practice, as each run would overwrite the previous backup. By using `db_$(date +%F).sql`, I created a new, uniquely named file for each day's backup (e.g., `db_2025-10-14.sql`), which is essential for maintaining a history of backups.
-   **`sshpass`**: This is a utility that allows you to provide a password for an SSH or SCP connection non-interactively. This was the key to my solution. It allowed the DB server to connect to the backup server without being prompted for a password, which would have caused the automated Jenkins job to fail.

---

### Deep Dive: The "Push" Backup Strategy and `sshpass`
<a name="deep-dive-the-push-backup-strategy-and-sshpass"></a>
My initial thought was to use two Jenkins build steps: one on the DB server to create the dump, and a second on the backup server to `scp` and "pull" the file. However, this often fails in lab environments due to complex network firewall rules between servers.

[Image of Jenkins orchestrating a multi-server backup]

The solution I implemented is a more robust **"push" strategy**:
1.  Jenkins connects to the DB server.
2.  The DB server does all the work: it creates the dump and then *initiates* the connection to the backup server to push the file.
This often works better because outbound connections are less likely to be blocked by firewalls than inbound ones.

The key to making this work was `sshpass`.
-   **The Problem:** The `scp` command, when run in a script, will still prompt for a password, which Jenkins cannot provide.
-   **The `sshpass` Solution:**
    ```bash
    sshpass -p 'H@wk3y3' scp ...
    ```
    -   `sshpass`: This utility acts as a wrapper around the `scp` command.
    -   `-p 'H@wk3y3'`: The `-p` flag tells `sshpass` to provide the specified password to the command it is running.
-   **Security Note:** While `sshpass` is incredibly useful for labs and simple automation, it is a **security risk in production**. The password is a plain-text string in my Jenkins job configuration, which is not ideal. The most secure method is always to use **password-less SSH Key Authentication**, but `sshpass` is a fantastic and quick workaround.
-   **`-o StrictHostKeyChecking=no`**: This is another important piece. It tells the `scp` command to automatically trust the host key of the backup server if it's the first time connecting, preventing the interactive "Are you sure you want to continue connecting?" prompt that would also cause the job to fail.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Inter-Server Connectivity:** The biggest issue is often a firewall blocking the connection between the DB and backup servers. The "push" strategy helps mitigate this but doesn't solve all network issues.
-   **Missing `sshpass`:** The `sshpass` utility is not always installed by default. My script would have failed if I hadn't first manually installed it on the DB server (`sudo yum install -y sshpass`).
-   **Incorrect Passwords or Usernames:** A simple typo in the `mysqldump` credentials or the `sshpass` password would cause the script to fail.
-   **Incorrect Cron Syntax:** The schedule `*/10 * * * *` must be exact to run every 10 minutes.

---

### Exploring the UI and Commands I Used
<a name="exploring-the-ui-and-commands-i-used"></a>
-   **`Manage Jenkins` > `System`**: Where I globally configured the "SSH remote hosts" for both servers.
-   **`[Job Name]` > `Configure`**:
    -   **`Build Triggers` > `Build periodically`**: Where I set the cron schedule.
    -   **`Build Steps` > `Execute shell script on remote host...`**: Where I selected the DB server and provided my multi-line script.
-   **`mysqldump -u [user] -p'[pass]' [db] > [file]`**: The command to create a database backup. Note the lack of a space between `-p` and the password.
-   `sshpass -p '[pass]' scp -o StrictHostKeyChecking=no [source] [dest]`: The core of my solution. It uses `sshpass` to provide a password to the `scp` command non-interactively.
-   `rm [file]`: The standard command to **r**e**m**ove the temporary dump file from the DB server after it has been copied.
  