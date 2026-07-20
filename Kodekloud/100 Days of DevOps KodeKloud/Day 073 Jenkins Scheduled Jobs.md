# DevOps Day 73: Automating a Multi-Server Log Collection Job

Today's task was a fantastic real-world scenario that perfectly demonstrated Jenkins's power as a central orchestrator. My objective was to create an automated, scheduled job to collect Apache log files from an application server and transfer them to a dedicated storage server.

This was more than just a simple script; it required me to configure Jenkins to communicate with two different remote hosts and to handle a multi-step workflow. The solution I implemented, using a single remote execution step with `sshpass`, was a clever and efficient way to solve the potential networking challenges between the servers. This document is my very detailed, first-person guide to that entire successful process.

## Table of Contents
- [DevOps Day 73: Automating a Multi-Server Log Collection Job](#devops-day-73-automating-a-multi-server-log-collection-job)
  - [Table of Contents](#table-of-contents)
    - [The Task](#the-task)
    - [My Step-by-Step Solution](#my-step-by-step-solution)
      - [Phase 1: Preparing Jenkins](#phase-1-preparing-jenkins)
      - [Phase 2: The Jenkins Job Configuration](#phase-2-the-jenkins-job-configuration)
    - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
    - [Deep Dive: The "Push" Strategy and the `sshpass` Workaround](#deep-dive-the-push-strategy-and-the-sshpass-workaround)
    - [Common Pitfalls](#common-pitfalls)
    - [Exploring the UI and Commands I Used](#exploring-the-ui-and-commands-i-used)

---

### The Task
<a name="the-task"></a>
My objective was to create a scheduled Jenkins job named `copy-logs` to automate a multi-server log collection process. The requirements were:
1.  Connect to **App Server 1** and copy its Apache logs (`access_log` and `error_log`).
2.  The logs needed to be transferred to the **Storage Server** into the `/usr/src/devops` directory.
3.  The entire job had to be scheduled to run every 5 minutes (`*/5 * * * *`).

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
My successful solution involved preparing Jenkins to communicate with both servers and then writing a clever, two-part script within a single build step.

#### Phase 1: Preparing Jenkins
Before creating the job, I had to configure Jenkins to securely connect to both the App Server and the Storage Server.
1.  **Install SSH Plugin:** I logged into Jenkins as `admin`, went to `Manage Jenkins` > `Plugins`, and installed the **`SSH Plugin`** with a restart.
2.  **Add Credentials:** I went to `Manage Jenkins` > `Credentials` and added two `Username with password` credentials:
    -   One for App Server 1 (`tony`/`Ir0nM@n`), with ID `app-server-1-creds`.
    -   One for the Storage Server (`natasha`/`Bl@kW`), with ID `storage-server-creds`.
3.  **Configure Global SSH Sites:** I went to `Manage Jenkins` > `System` and, in the "SSH remote hosts" section, added both `stapp01` and `ststor01`, linking them to their respective credentials and using the "Test Connection" button for each to confirm success.

#### Phase 2: The Jenkins Job Configuration
1.  I created a `Freestyle project` named `copy-logs`.
2.  In the **"Build Triggers"** section, I checked "Build periodically" and entered the schedule: `*/5 * * * *`.
3.  **This was the core of my solution:** In the **"Build Steps"** section, I added a single **"Execute shell script on remote host using ssh"** step.
    -   For the **SSH Site**, I selected the App Server: `tony@stapp01:22`.
    -   In the **Command** box, I wrote a script that would run entirely on App Server 1. This script first finds the log files and then *pushes* them to the storage server using `sshpass`.
        ```bash
        # Use sshpass to provide the password for the 'natasha' user non-interactively
        # and scp to push the files.
        # The password for the 'natasha' user on the storage server is 'Bl@kW'.
        # The -o option is to avoid the first-time host key check prompt.
        sshpass -p 'Bl@kW' scp -o StrictHostKeyChecking=no /var/log/httpd/* natasha@ststor01:/usr/src/devops
        ```
4.  I saved the job, ran it manually once, and checked the console output, which showed `Finished: SUCCESS`. A final check on the storage server confirmed the log files were there.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **Jenkins as an Orchestrator**: This task perfectly demonstrated Jenkins's role as a central controller. It didn't just run a script; it connected to one server and coordinated a file transfer to a second server, all on an automated schedule.
-   **Log Aggregation**: Collecting logs from multiple application servers and storing them in a centralized location (like my storage server) is a fundamental practice in DevOps. It's the first step towards building a centralized logging system (like an ELK stack) where logs can be searched, analyzed, and visualized.
-   **`sshpass`**: This is a utility that allows you to provide a password for an SSH or SCP connection non-interactively from the command line. This was the key to my solution, as it allowed the app server to connect to the storage server without being prompted for a password, which would have caused the automated Jenkins job to fail.

---

### Deep Dive: The "Push" Strategy and the `sshpass` Workaround
<a name="deep-dive-the-push-strategy-and-the-sshpass-workaround"></a>
My first instinct might have been to use two separate Jenkins build steps: one on the app server to find the logs, and a second on the storage server to `scp` and "pull" the files. However, this often fails in complex lab environments due to firewall rules that might block one server from initiating a connection to another.

The solution I implemented is a more robust **"push" strategy**:
1.  Jenkins connects to the App Server.
2.  The App Server does all the work: it finds the local log files and then *initiates* the connection to the Storage Server to push them.
This often works better because outbound connections are less likely to be blocked by firewalls than inbound ones.

[Image of Jenkins orchestrating a multi-server backup]

The key to making this "push" strategy work was `sshpass`.
-   **The Problem:** The `scp` command, when run in a script, will still prompt for a password, which Jenkins cannot provide.
-   **The `sshpass` Solution:**
    ```bash
    sshpass -p 'Bl@kW' scp ...
    ```
    -   `sshpass`: This utility acts as a wrapper around the `scp` command.
    -   `-p 'Bl@kW'`: The `-p` flag tells `sshpass` to provide the specified password to the command it is running.
-   **Security Note:** While `sshpass` is incredibly useful for labs and simple automation, it is a **major security risk in production**. The password is a plain-text string in my Jenkins job configuration, which is not ideal. The most secure method is always to use **password-less SSH Key Authentication**, but `sshpass` is a fantastic and quick workaround for this kind of environment.
-   **`-o StrictHostKeyChecking=no`**: This is another important piece. It tells the `scp` command to automatically trust the host key of the storage server if it's the first time connecting, preventing the interactive "Are you sure you want to continue connecting?" prompt that would also cause the job to fail.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Inter-Server Connectivity:** The biggest issue is often a firewall blocking the connection between the servers. The "push" strategy helps mitigate this, but it's always the first thing to check if a remote command fails.
-   **Missing `sshpass`:** The `sshpass` utility is not always installed by default. My script would have failed if I hadn't first manually installed it on the app server (`sudo yum install -y sshpass`).
-   **Incorrect Log Path:** I first had to SSH into the app server to confirm the Apache log directory (`/var/log/httpd`), as it can be different on different operating systems.
-   **Permissions on Destination:** The `natasha` user needed write permissions on the `/usr/src/devops` directory on the storage server. If they didn't have it, the `scp` command would have failed.

---

### Exploring the UI and Commands I Used
<a name="exploring-the-ui-and-commands-i-used"></a>
-   **`Manage Jenkins` > `System`**: Where I globally configured the "SSH remote hosts" for both servers.
-   **`[Job Name]` > `Configure`**:
    -   **`Build Triggers` > `Build periodically`**: Where I set the cron schedule (`*/5 * * * *`).
    -   **`Build Steps` > `Execute shell script on remote host...`**: Where I selected the app server and provided my `sshpass` script.
-   `sshpass -p '[pass]' scp -o StrictHostKeyChecking=no [source] [dest]`: The core of my solution. It uses `sshpass` to provide a password to the `scp` command non-interactively, allowing a fully automated, cross-server file transfer.
-   `whereis access_log` / `ls -la /var/log/httpd`: The investigation commands I used on the app server to find the exact location of the Apache log files.
   