# DevOps Day 71: The CI/CD "Remote Control"

Today's task was a huge leap forward in my Jenkins journey. I moved from managing Jenkins itself to using Jenkins to manage *other servers*. The goal was to create a reusable, parameterized job that could install any software package on a remote storage server.

This was a fantastic, multi-layered task that taught me about some of the most powerful features in Jenkins: parameters, remote execution via SSH, and secure credential management. It was also a masterclass in real-world troubleshooting, as my initial job failed not because of a Jenkins issue, but because of a permissions problem on the remote server. This document is my detailed story of that entire process.

## Table of Contents
- [DevOps Day 71: The CI/CD "Remote Control"](#devops-day-71-the-cicd-remote-control)
  - [Table of Contents](#table-of-contents)
    - [The Task](#the-task)
    - [My Step-by-Step Solution](#my-step-by-step-solution)
      - [Phase 1: Preparing Jenkins](#phase-1-preparing-jenkins)
      - [Phase 2: Preparing the Remote Server](#phase-2-preparing-the-remote-server)
      - [Phase 3: Creating and Configuring the Jenkins Job](#phase-3-creating-and-configuring-the-jenkins-job)
    - [My Troubleshooting Journey: A Two-Part Problem](#my-troubleshooting-journey-a-two-part-problem)
    - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
    - [Deep Dive: Password-less `sudo` and the `/etc/sudoers` File](#deep-dive-password-less-sudo-and-the-etcsudoers-file)
    - [Common Pitfalls](#common-pitfalls)
    - [Exploring the UI and Commands Used](#exploring-the-ui-and-commands-used)

---

### The Task
<a name="the-task"></a>
My objective was to create a flexible Jenkins job to automate package installation on the remote storage server. The requirements were:
1.  Create a new Freestyle project named `install-packages`.
2.  The job must be **parameterized** with a String Parameter named `PACKAGE`.
3.  The job must connect to the **storage server** via SSH and execute a command to install the package specified by the `$PACKAGE` parameter.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
My path to success required configuring both Jenkins and the remote server.

#### Phase 1: Preparing Jenkins
First, I had to prepare Jenkins with the necessary plugins, credentials, and global configuration.

1.  **Install SSH Plugin:** I logged into Jenkins as `admin`, went to `Manage Jenkins` > `Plugins` > `Available plugins`, searched for `SSH Plugin`, and installed it with a restart.
2.  **Add Credentials:** I went to `Manage Jenkins` > `Credentials` > `(global)` > `Add Credentials`. I created a `Username with password` credential for the `natasha` user on the storage server, giving it the ID `storage-server-creds`.
3.  **Configure Global SSH Site:** This was a critical step I missed on my first try. I went to `Manage Jenkins` > `System`, scrolled to the **"SSH remote hosts"** section, and added a new site. I entered the hostname `ststor01`, selected the `storage-server-creds` credential, and used the **"Test Connection"** button to confirm it worked.

#### Phase 2: Preparing the Remote Server
This was the solution to my second failure. The Jenkins job was failing because the `natasha` user couldn't run `sudo` without a password.
1.  I connected to the **storage server** (`ststor01`) as an admin user.
2.  I safely edited the `sudoers` file using `sudo visudo`.
3.  At the bottom of the file, I added the following line to grant password-less `yum` access to the `natasha` user:
    ```
    natasha ALL=(ALL) NOPASSWD: /usr/bin/yum
    ```

#### Phase 3: Creating and Configuring the Jenkins Job
With both Jenkins and the remote server prepared, I could now create the job.
1.  From the dashboard, I created a `New Item`, named it `install-packages`, and chose `Freestyle project`.
2.  In the job configuration, I checked **"This project is parameterized"** and added a **String Parameter** named `PACKAGE` with a default value of `tree`.
3.  Under **"Build Steps"**, I added **"Execute shell script on remote host using ssh"**.
4.  From the **"SSH Site"** dropdown, I selected the `natasha@ststor01:22` site that I had configured globally.
5.  In the **"Command"** box, I entered the script:
    ```bash
    sudo yum install -y $PACKAGE
    ```
6.  I saved the job, ran it with the default parameter, and checked the console output. It was a success!

---

### My Troubleshooting Journey: A Two-Part Problem
<a name="my-troubleshooting-journey-a-two-part-problem"></a>
This task was a perfect example of how a CI/CD problem can span multiple systems.

* **Failure 1: The Missing "SSH Site"**
    -   **Symptom:** When I first tried to configure the job's build step, the "SSH Site" dropdown was empty, and Jenkins showed an error `SSH Site not specified`.
    -   **Diagnosis:** I realized that the build step is for *selecting* a pre-configured server, not for *defining* one. I hadn't told Jenkins about the storage server yet.
    -   **Solution:** I fixed this by going to `Manage Jenkins` > `System`, adding the `ststor01` host in the "SSH remote hosts" section, and linking it to my credential. After this, the server appeared in the job's dropdown menu.

* **Failure 2: The `sudo: a password is required` Error**
    -   **Symptom:** My job connected to the remote server, but the build failed. The console output showed `sudo: a terminal is required to read the password` and `sudo: a password is required`.
    -   **Diagnosis:** This was not a Jenkins error. This was the remote operating system on `ststor01` telling me that the `natasha` user tried to use `sudo`, but since the script was running in a non-interactive session, there was no way for Jenkins to enter the password.
    -   **Solution:** The fix had to be made on the **storage server**. I edited the `/etc/sudoers` file (using `visudo`) to add a rule that specifically allowed the `natasha` user to run the `yum` command without being prompted for a password.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
-   **Parameterized Builds**: This is a core concept for making Jenkins jobs reusable. Instead of creating a separate job for every package I might want to install, I created one flexible job. The **String Parameter** `PACKAGE` acts as a variable that I can change every time I run the build.
-   **Remote Execution via SSH**: Jenkins is an orchestrator. Its job is to tell other servers what to do. The **SSH Plugin** is the tool that gives Jenkins this "remote control" capability, allowing it to securely connect to other machines and run scripts.
-   **Jenkins Credentials Manager**: Hardcoding a password in a job's configuration is a terrible security practice. The **Credentials Manager** is Jenkins's secure vault. I stored the `natasha` user's password there once. Jenkins encrypts it and protects it. My job then only refers to the credential by its ID (`storage-server-creds`), never exposing the actual secret in the job's configuration or logs.

---

### Deep Dive: Password-less `sudo` and the `/etc/sudoers` File
<a name="deep-dive-password-less-sudo-and-the-etcsudoers-file"></a>
The solution to my second failure was the most advanced and interesting part of this task. It involved configuring `sudo` permissions on the remote server.

-   **What is the `/etc/sudoers` file?** This file is the master configuration for the `sudo` command. It contains a list of rules that define which users can run which commands with which privileges.
-   **Why use `visudo`?** You should **never** edit the `/etc/sudoers` file directly with `vi` or `nano`. The `visudo` command is a special, safe editor. It locks the file so no one else can edit it at the same time, and most importantly, it performs a **syntax check** before saving. This prevents you from making a typo that could break `sudo` for the entire system, locking you out of your server.
-   **Breaking down my `sudoers` rule:**
    ```
    natasha   ALL=(ALL)   NOPASSWD: /usr/bin/yum
    ```
    -   **`natasha`**: The user this rule applies to.
    -   **`ALL=`**: The rule applies when the user is logged in from **any** host.
    -   **`(ALL)`**: The user can run the command as **any** user (e.g., as `root`).
    -   **`NOPASSWD:`**: The critical part. This tells `sudo` **not** to ask for a password when the user runs the specified command.
    -   **`/usr/bin/yum`**: The specific command that this rule applies to. I gave `natasha` password-less access only to the `yum` command, not to everything. This is another example of the Principle of Least Privilege.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Configuring SSH in the Job:** As I first discovered, trying to configure the SSH connection inside the job's build step is wrong. The SSH site must be defined globally first in `Manage Jenkins` > `System`.
-   **The `sudo` Password Prompt:** Forgetting that CI/CD tools run in non-interactive sessions is a common mistake. Any command that prompts for input will cause the build to fail. This is why password-less `sudo` is a requirement for this kind of automation.
-   **Not Using `visudo`:** Editing `/etc/sudoers` directly is very dangerous. A single syntax error could make it impossible to use `sudo` on the server again.

---

### Exploring the UI and Commands Used
<a name="exploring-the-ui-and-commands-used"></a>
-   **`Manage Jenkins` > `Plugins`**: Where I went to install the `SSH Plugin`.
-   **`Manage Jenkins` > `Credentials`**: The secure vault where I stored the password for the `natasha` user.
-   **`Manage Jenkins` > `System`**: The main configuration page where I had to globally define the "SSH remote host" for the storage server.
-   **`[Job Name]` > `Configure`**: The page where I configured the job's parameters and build steps.
-   **`sudo visudo` (on the remote host)**: The safe command for editing the `/etc/sudoers` file.
-   **`sudo yum install -y $PACKAGE` (in the Jenkins job)**: The final command executed remotely by Jenkins. The `$PACKAGE` variable is automatically replaced by Jenkins with the value I provide when I start the build.
  