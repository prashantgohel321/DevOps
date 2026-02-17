# Jenkins Level 2, Task 3: The Multi-Branch Deployment Challenge

Today's task was a deep dive into creating a sophisticated, real-world Jenkins pipeline. My objective was to build a single, flexible job that could deploy multiple different feature branches of an application to a remote server. This required me to combine parameterized builds, dynamic workspaces, Git integration, and remote deployment over SSH.

This was an incredible learning experience, not just because of the complex Jenkins configuration, but because of the layered troubleshooting it required. Even after my Jenkins build log showed `SUCCESS`, the lab failed. This document is a detailed post-mortem of my entire journey: how I correctly configured the Jenkins job by setting up password-less SSH keys, how I diagnosed and fixed the initial connection errors, and how I uncovered the "hidden" infrastructure requirements that were the true cause of the final validation failure.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution (The Complete Picture)](#my-step-by-step-solution-the-complete-picture)
- [My Troubleshooting Journey: A Multi-Layered Problem](#my-troubleshooting-journey-a-multi-layered-problem)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: SSH Key Authentication for the `jenkins` User](#deep-dive-ssh-key-authentication-for-the-jenkins-user)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the UI and Commands I Used](#exploring-the-ui-and-commands-i-used)

---

### The Task
<a name="the-task"></a>
My objective was to create a single Jenkins job named `app-job` to deploy different versions of a web application. The requirements were:
1.  The job must be parameterized with a `Choice Parameter` named `Branch` for `version1`, `version2`, and `version3`.
2.  It had to fetch code from the correct branch of the `web_app` repository on the Gitea server.
3.  It had to use a **dynamic custom workspace** based on the selected branch (e.g., `/var/lib/jenkins/version1`).
4.  It had to deploy the fetched code to the `/var/www/html` directory on the remote **storage server**.
5.  The final deployment had to be accessible via the "App" button (the LBR URL).

---

### My Step-by-Step Solution (The Complete Picture)
<a name="my-step-by-step-solution-the-complete-picture"></a>
My final understanding is that success required configuring the entire web stack, not just the Jenkins job. My successful method for the deployment part involved setting up SSH keys manually, which is a more robust and secure solution than using password-based credentials in Jenkins.

#### Phase 1: Preparing Password-less SSH
This was the key to enabling the automated deployment.
1.  **Generate Keys on Jenkins Server:** I logged into the Jenkins server (`ssh jenkins@jenkins`), and as the `jenkins` user, I generated a new SSH key pair:
    ```bash
    ssh-keygen -t rsa
    ```
    I accepted the defaults and left the passphrase empty.
2.  **Copy Public Key:** I copied the contents of the newly created public key file.
    ```bash
    cat ~/.ssh/id_rsa.pub
    ```
3.  **Authorize Key on Storage Server:** I logged into the storage server (`ssh natasha@ststor01`), created the `.ssh` directory if it didn't exist, and pasted the public key into the `~/.ssh/authorized_keys` file for the `natasha` user. This authorized the `jenkins` user to connect as `natasha` without a password.
4.  **Verification:** Back on the Jenkins server, as the `jenkins` user, I tested the connection: `ssh natasha@ststor01`. It connected instantly without a password prompt.

#### Phase 2: Configuring the Jenkins Job
1.  I created a `Freestyle project` named `app-job`.
2.  I added a `Choice Parameter` named `Branch` with the three versions.
3.  Under `Advanced`, I set the **custom workspace** to the dynamic path `/var/lib/jenkins/$Branch`.
4.  In **Source Code Management**, I selected `Git`, provided the repository URL, and set the **Branch Specifier** to `*/$Branch`.
5.  In **Build Steps**, I added an **"Execute shell"** step (not "Execute shell script on remote host"). In the command box, I put the `scp` command that would run *on the Jenkins server*:
    ```bash
    scp -r * natasha@ststor01:/var/www/html
    ```

#### Phase 3: The "Hidden" Infrastructure Setup
This was the missing piece that caused previous failures. The validation script checks the LBR URL, which means the entire web stack must be running.
1.  **Configure App Servers:** On all three app servers, I installed and started `httpd` and opened the firewall for port 80.
2.  **Configure LBR Server:** On the LBR, I stopped the conflicting `haproxy` service, installed `nginx`, and configured it with an `upstream` block to proxy traffic to the app servers on port 80.

After all three phases were complete, running the Jenkins job resulted in a successful deployment that passed the lab's validation.

---

### My Troubleshooting Journey: A Multi-Layered Problem
<a name="my-troubleshooting-journey-a-multi-layered-problem"></a>
This task was a masterclass in debugging. My Jenkins build log showed `SUCCESS`, but the lab failed.

* **Failure 1: `Host key verification failed.`**
    -   **Symptom:** My initial build failed with this SSH error.
    -   **Diagnosis:** This error means the SSH client was presented with an unknown host key and was asking the interactive "Are you sure you want to continue connecting (yes/no)?" prompt. Since Jenkins runs non-interactively, it couldn't answer and the connection failed.
    -   **Solution:** The fix was to make the host key "known." I had to perform a one-time manual SSH connection *as the `jenkins` user* from the Jenkins server to the storage server to accept the key.

* **Failure 2: The `sudo` and `rsync` Problems**
    -   **Symptom:** My remote script was failing with "sudo: a password is required" and "rsync: command not found".
    -   **Diagnosis:** This revealed two problems on the remote storage server: `rsync` wasn't installed, and the `natasha` user couldn't run `sudo` without a password.
    -   **Solution:** I realized the better approach was to avoid `sudo` entirely. By checking the permissions on the storage server (`ls -la /var/www/html`), I saw that the `natasha` user had been given direct write access. This meant I didn't need `sudo` for the copy command at all.

* **Failure 3: The Final Validation Error (`Seems like jenkins job is not configured to deploy correct branch...`)**
    -   **Symptom:** After fixing the SSH issue, my Jenkins build log was perfect. It showed the correct branch being checked out, the correct dynamic workspace being used, and the deployment command completing successfully. Yet, the lab failed.
    -   **Diagnosis:** The error message was misleading. The problem was not my Jenkins job configuration. The problem was that the validation was happening at the **LBR URL**. The entire web infrastructure—the Apache servers that I was deploying to and the Nginx load balancer in front of them—was not running. My delivery was perfect, but the "store" was closed.
    -   **Solution:** I had to manually configure the entire web stack (Apache on all app servers, Nginx on the LBR) *in addition* to configuring the Jenkins job.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **Parameterized Builds**: This is the key to reusable jobs. My `Choice Parameter` allowed one job to handle deployments for three different feature branches.
-   **Dynamic Custom Workspaces**: This is a powerful feature for preventing conflicts. By setting the workspace to `/var/lib/jenkins/$Branch`, I ensured that a build for `version1` would not interfere with the files from a `version2` build. Each branch gets its own clean, isolated workspace.
-   **Parameterized SCM**: This is the magic that makes it work. By using the `$Branch` variable in the "Branch Specifier" field of the Git SCM configuration, I instructed Jenkins to dynamically check out the branch that the user selected when they started the build.
-   **Password-less SSH with Keys**: Using SSH keys is the standard, secure method for automation. Passwords can be stolen and are difficult to manage in scripts. An SSH key pair provides a much more secure cryptographic method for one server to prove its identity to another.

---

### Deep Dive: SSH Key Authentication for the `jenkins` User
<a name="deep-dive-ssh-key-authentication-for-the-jenkins-user"></a>
My final, successful solution bypassed the Jenkins SSH plugin's password credential and used the industry-standard SSH key method.

-   **Jenkins Runs as the `jenkins` User:** When I configure a job, all the background processes (like `git` and `ssh`) are run by a special system user named `jenkins` on the Jenkins server.
-   **The Process:**
    1.  **`ssh-keygen` (on Jenkins server):** As the `jenkins` user, I created a new public/private key pair. The private key (`id_rsa`) is the user's secret identity and never leaves the server. The public key (`id_rsa.pub`) is the "lock" that can be shared.
    2.  **`authorized_keys` (on Storage server):** On the remote server, I pasted the `jenkins` user's public key into the `~/.ssh/authorized_keys` file for the `natasha` user. This file is a list of all public keys that are authorized to log in as `natasha`.
    3.  **The Connection:** When my Jenkins job runs the `scp` command, the `jenkins` user's SSH client presents its public key to the storage server. The storage server checks its `authorized_keys` file, finds a match, and grants access without ever needing a password.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Forgetting to Install Plugins:** The `Git` plugin is essential for the SCM section to work.
-   **SSH Host Key Verification:** As I discovered, this is a very common failure point. The fix is to SSH manually *as the `jenkins` user* once to accept the host key.
-   **Permissions on Remote Server:** Assuming the deployment user needs `sudo` can be a red herring. The first step should always be to check the permissions of the destination directory (`ls -la /var/www/html`).
-   **The "Hidden" Infrastructure Requirement:** The biggest trap in this lab was assuming that the task was *only* about Jenkins. The final validation at the LBR URL meant the entire web stack had to be operational.

---

### Exploring the UI and Commands I Used
<a name="exploring-the-ui-and-commands-i-used"></a>
-   **`[Job Name]` > `Configure`**:
    -   **`This project is parameterized`**: Where I added the `Choice Parameter`.
    -   **`Use custom workspace`**: Where I set the dynamic directory `/var/lib/jenkins/$Branch`.
    -   **`Source Code Management` > `Git`**: Where I set the repository URL and the parameterized "Branch Specifier" to `$Branch`.
    -   **`Build Steps` > `Execute shell`**: Where I added the simple `scp -r * ...` command.
-   `ssh-keygen -t rsa`: The command to generate a new SSH public/private key pair.
-   `cat ~/.ssh/id_rsa.pub`: The command to display the public key so it can be copied.
-   `scp -r * natasha@ststor01:/var/www/html`: The build command to **s**ecurely **c**o**p**y all files (`*`) **r**ecursively from the Jenkins workspace to the remote server.
  