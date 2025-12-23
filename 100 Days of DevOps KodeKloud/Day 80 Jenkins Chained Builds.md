# DevOps Day 80: Chained Builds and Downstream Jobs

Today's task was an advanced automation scenario involving **Build Chaining**. The goal was to create a deployment pipeline where one job deploys code, and if (and only if) it succeeds, it triggers a second "downstream" job to restart the application services.

This ensures that we don't restart services if the code deployment failed, preventing downtime. I used the **Publish Over SSH** plugin to manage connections to multiple servers and configured a parameterized downstream job to handle service restarts securely.

## Table of Contents
- [DevOps Day 80: Chained Builds and Downstream Jobs](#devops-day-80-chained-builds-and-downstream-jobs)
  - [Table of Contents](#table-of-contents)
    - [The Task](#the-task)
    - [My Step-by-Step Solution](#my-step-by-step-solution)
      - [Phase 1: Configuring "Publish Over SSH"](#phase-1-configuring-publish-over-ssh)
      - [Phase 2: Creating the Deployment Job (Upstream)](#phase-2-creating-the-deployment-job-upstream)
      - [Phase 3: Creating the Service Management Job (Downstream)](#phase-3-creating-the-service-management-job-downstream)
      - [Phase 4: Verification](#phase-4-verification)
    - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
    - [Deep Dive: Upstream vs. Downstream Jobs](#deep-dive-upstream-vs-downstream-jobs)
    - [Common Pitfalls](#common-pitfalls)
    - [Exploring the UI Used](#exploring-the-ui-used)

---

### The Task
<a name="the-task"></a>
My objective was to configure two linked Jenkins jobs:
1.  **`nautilus-app-deployment` (Upstream):** Pulls code from the `web` repository to the shared storage `/var/www/html` on the Storage Server.
2.  **`manage-services` (Downstream):** Restarts the `httpd` service on all three App Servers (`stapp01`, `stapp02`, `stapp03`), but only if the deployment job is stable.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The solution involved configuring the global SSH plugin settings and then setting up the two interdependent jobs.

#### Phase 1: Configuring "Publish Over SSH"
Before creating jobs, I needed to teach Jenkins how to talk to all four servers (Storage + 3 App Servers).
1.  **Install Plugin:** I went to **Manage Jenkins** > **Plugins** and installed **"Publish Over SSH"**. I restarted Jenkins.
2.  **Configure Servers:** I went to **Manage Jenkins** > **System**.
3.  I scrolled down to the **Publish over SSH** section.
4.  **Storage Server:**
    -   Name: `ststor01`
    -   Hostname: `ststor01.stratos.xfusioncorp.com`
    -   Username: `natasha`
    -   Remote Directory: `/`
    -   **Advanced** > Check **Use password authentication**.
    -   Password: `Bl@kW`
    -   Clicked **Test Configuration** -> Success.
5.  **App Servers:** I clicked "Add" and repeated the process for all three app servers:
    -   **stapp01:** User `tony` (`Ir0nM@n`).
    -   **stapp02:** User `steve` (`Am3ric@`).
    -   **stapp03:** User `banner` (`BigGr33n`).
6.  I clicked **Save**.

#### Phase 2: Creating the Deployment Job (Upstream)
1.  **New Item:** Created a Freestyle project named `nautilus-app-deployment`.
2.  **Build Steps:** Added **"Send files or execute commands over SSH"**.
    -   **Name:** `ststor01` (Selected from the dropdown).
    -   **Exec command:**
        ```bash
        cd /var/www/html
        # The repo is already there, just need to update it
        git pull origin master
        ```
3.  **Post-build Actions:** Added **"Build other projects"**.
    -   **Projects to build:** `manage-services`.
    -   **Trigger only if build is stable:** Checked.
4.  I clicked **Save**.

#### Phase 3: Creating the Service Management Job (Downstream)
1.  **New Item:** Created a Freestyle project named `manage-services`.
2.  **Parameters:** I checked **"This project is parameterized"** to securely handle sudo passwords.
    -   Added **Password Parameter**: `STAPP01_PASS` (Default: `Ir0nM@n`).
    -   Added **Password Parameter**: `STAPP02_PASS` (Default: `Am3ric@`).
    -   Added **Password Parameter**: `STAPP03_PASS` (Default: `BigGr33n`).
3.  **Build Steps:** Added **"Send files or execute commands over SSH"**.
    -   **Server 1:** `stapp01`.
    -   **Command:** `echo $STAPP01_PASS | sudo -S systemctl restart httpd`
    -   **Server 2:** `stapp02` (Added another "Transfer Set").
    -   **Command:** `echo $STAPP02_PASS | sudo -S systemctl restart httpd`
    -   **Server 3:** `stapp03` (Added another "Transfer Set").
    -   **Command:** `echo $STAPP03_PASS | sudo -S systemctl restart httpd`
4.  I clicked **Save**.

#### Phase 4: Verification
1.  I manually triggered `nautilus-app-deployment`.
2.  I watched it complete successfully.
3.  I verified that `manage-services` started automatically right after.
4.  I checked the console output of `manage-services` to confirm the restart commands were sent successfully.
5.  I refreshed the main website URL (`https://<LBR-URL>`) to confirm the app was live.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **Chained Builds:** In complex systems, you rarely want one giant job that does everything. By splitting "Deployment" and "Restart" into two jobs, I kept them modular. If I just want to restart services without deploying code, I can run `manage-services` independently.
-   **Downstream Triggers:** This ensures order and safety. We never want to restart the web server if the code deployment failed (leaving the site in a broken state). The "Trigger only if stable" condition acts as a safety gate.
-   **`sudo -S`:** SSH commands run non-interactively. `sudo` usually asks for a password from the keyboard. The `-S` flag tells `sudo` to read the password from Standard Input (stdin), which allowed me to pipe the password (`echo $PASS | ...`) securely into the command.

---

### Deep Dive: Upstream vs. Downstream Jobs
<a name="deep-dive-upstream-vs-downstream-jobs"></a>
This relationship creates a dependency pipeline.

[Image of Jenkins Upstream Downstream flow]

1.  **Upstream (`nautilus-app-deployment`):** The parent job. It initiates the process. It has no idea *how* to restart services; it just knows *who* to call when it's done.
2.  **Downstream (`manage-services`):** The child job. It waits for a signal. It doesn't care *where* the code came from; its only job is to ensure the services pick up the changes.

This separation of concerns makes debugging easier. If the code didn't update, I check the Upstream logs. If the server didn't restart, I check the Downstream logs.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Parameter Names:** When using `echo $VAR`, the variable name in the shell command MUST match the Parameter Name defined in the job exactly. Case matters.
-   **Hidden Spaces:** Copy-pasting passwords into the "Default Value" field can sometimes include a trailing space, which causes `sudo` to reject the password.
-   **SSH Exec Timeout:** If `systemctl restart` takes too long, the SSH command might timeout. Increasing the timeout in the "Publish Over SSH" global settings prevents this.

---

### Exploring the UI Used
<a name="exploring-the-ui-used"></a>
-   **`Manage Jenkins` > `System`**: The location for configuring global tools like the "Publish Over SSH" servers.
-   **`Post-build Actions`**: The section in a Job configuration where you define what happens *after* the main work is done (e.g., triggering another job).
-   **`Send files or execute commands over SSH`**: A build step provided by the plugin that allows running shell commands on remote servers without needing a full Jenkins agent setup on them.
   