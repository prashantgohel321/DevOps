# DevOps Day 68: Installing and Configuring a Jenkins CI/CD Server

Today's task was to build the very foundation of a modern DevOps environment: the Jenkins automation server. This is the "engine" that will run all our future CI/CD pipelines. The objective was a two-part process: first, install and run the Jenkins software on the server's command line, and second, complete the initial security setup and user creation through the web UI.

This was a fantastic real-world exercise because the installation process is notoriously famous for failing due to prerequisite issues, like missing tools or incorrect Java versions. This document is my detailed, first-person account of the entire journey, including the common failures I've learned to look for and the final, successful setup.

## Table of Contents
- [DevOps Day 68: Installing and Configuring a Jenkins CI/CD Server](#devops-day-68-installing-and-configuring-a-jenkins-cicd-server)
  - [Table of Contents](#table-of-contents)
    - [The Task](#the-task)
    - [My Step-by-Step Solution](#my-step-by-step-solution)
      - [Phase 1: Server-Side Installation (Command Line)](#phase-1-server-side-installation-command-line)
      - [Phase 2: Initial Setup (Web UI)](#phase-2-initial-setup-web-ui)
    - [Common Failures \& Troubleshooting](#common-failures--troubleshooting)
    - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
    - [Deep Dive: The Two-Part Jenkins Setup](#deep-dive-the-two-part-jenkins-setup)
    - [Exploring the Commands and UI I Used](#exploring-the-commands-and-ui-i-used)
      - [**Server-Side Commands**](#server-side-commands)
      - [**Client-Side (Web UI) Steps**](#client-side-web-ui-steps)

---

### The Task
<a name="the-task"></a>
My objective was to set up a new, fully functional Jenkins server. The requirements were:
1.  **Server-Side:** Connect to the `jenkins` server as `root`, install Jenkins using `yum`, and start the service.
2.  **Client-Side (UI):** Access the Jenkins web UI, unlock the server, and create a new admin user with the following details:
    -   Username: `theadmin`
    -   Password: `Adm!n321`
    -   Full name: `Jim`
    -   Email: `jim@jenkins.stratos.xfusioncorp.com`

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
My successful process involved proactively handling the dependencies that I know can cause this installation to fail.

#### Phase 1: Server-Side Installation (Command Line)
I performed these steps as the `root` user on the Jenkins server.

1.  **Connect to the Jenkins Server:** From the jump host, I connected as `root`.
    ```bash
    ssh root@jenkins.stratos.xfusioncorp.com
    # Entered password: S3curePass
    ```

2.  **Install Prerequisites:** I've learned that a minimal server often lacks two key things: a download tool (`wget`) and the *correct* version of Java.
    ```bash
    # Install wget, which is needed to download the repository file
    yum install -y wget
    
    # Jenkins now requires Java 17 or 21. The default (Java 11) will fail.
    # I installed Java 17 to be safe.
    yum install -y java-17-openjdk-devel
    ```

3.  **Add the Jenkins Repository:** I told `yum` where to find the official Jenkins package.
    ```bash
    # Import the official GPG key for security
    rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    
    # Download the repository definition file to the correct location
    wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    ```

4.  **Install Jenkins:** Now that the prerequisites and repository were ready, I could safely install Jenkins.
    ```bash
    yum install -y jenkins
    ```

5.  **Start and Enable Jenkins:** I started the service and enabled it to launch on boot.
    ```bash
    systemctl start jenkins
    systemctl enable jenkins
    ```

6.  **Retrieve Initial Password:** I ran a quick `systemctl status jenkins` to ensure it was `active (running)`. Then, I retrieved the one-time password needed for the UI setup.
    ```bash
    cat /var/lib/jenkins/secrets/initialAdminPassword
    ```
    I copied the long alphanumeric string that this command printed.

#### Phase 2: Initial Setup (Web UI)
With the server running, I switched to my browser.
1.  I clicked the **Jenkins** button in the lab UI to open the web page.
2.  On the "Unlock Jenkins" screen, I pasted the password from Phase 1.
3.  I chose **"Install suggested plugins"** and waited for all the standard plugins to install.
4.  On the "Create First Admin User" screen, I entered the exact details from the task:
    -   Username: `theadmin`
    -   Password: `Adm!n321`
    -   Full name: `Jim`
    -   E-mail: `jim@jenkins.stratos.xfusioncorp.com`
5.  I clicked "Save and Continue," confirmed the instance URL on the next page, and finally clicked "Start using Jenkins." I was then logged into the main Jenkins dashboard as `theadmin`, successfully completing the task.

---

### Common Failures & Troubleshooting
<a name="common-failures--troubleshooting"></a>
This installation can fail in two main places, both of which I've learned to check for.

* **Failure 1: `wget: command not found`**
    -   **Symptom:** The command to add the Jenkins repo fails.
    -   **Diagnosis:** The server is a minimal install and doesn't have the `wget` download utility.
    -   **Solution:** `sudo yum install -y wget`.

* **Failure 2: `Job for jenkins.service failed...` (The Big One)**
    -   **Symptom:** `systemctl start jenkins` fails immediately. `systemctl status jenkins` shows `Active: failed`.
    -   **Diagnosis:** This is almost always a Java problem. The best way to confirm is to check the system logs for Jenkins:
        ```bash
        journalctl -xeu jenkins.service
        ```
    -   By reading the log, I would find the "smoking gun" error: `Running with Java 11 ... which is older than the minimum required version (Java 17)`.
    -   **Solution:** The version of Jenkins I installed requires Java 17 or 21. The server's default Java 11 is too old. The fix is to install a compatible version **before** starting the service: `sudo yum install -y java-17-openjdk-devel`.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **Jenkins**: This is an open-source automation server that acts as the heart of a **CI/CD pipeline**. CI/CD (Continuous Integration / Continuous Deployment) is the practice of automating the software delivery process. Jenkins can watch my code repository, and whenever a developer pushes a change, it can automatically build, test, and deploy the application.
-   **Java Prerequisite**: Jenkins is a Java application, meaning it's written in the Java programming language. It cannot run without a **Java Runtime Environment (JRE)** or **Java Development Kit (JDK)** installed on the server. My troubleshooting proved how critical it is to have the *correct version* of this dependency.
-   **`yum` and Repositories**: `yum` is the package manager for this server. By default, it only knows about a standard set of software. To install third-party software like Jenkins, I first had to add the official Jenkins "repository" to `yum`'s list of sources. This tells `yum` where to find and download the Jenkins package.
-   **Initial Admin Password**: This is a crucial security feature. When Jenkins is first installed, it's in an unlocked state. It generates a long, random, one-time-use password and stores it on the server. This ensures that only someone with file-system access to the server can perform the initial setup and secure the instance.

---

### Deep Dive: The Two-Part Jenkins Setup
<a name="deep-dive-the-two-part-jenkins-setup"></a>
This task showed me that a Jenkins setup is a two-phase process:

[Image of the Jenkins installation process]

1.  **Server-Side Installation (The "Engine"):** This is what I did on the command line as `root`. My job was to be the **System Administrator**. I installed the software, managed the system dependencies (Java), and started the `systemd` service. My deliverable was a running Jenkins service.
2.  **Client-Side Configuration (The "Cockpit"):** This is what I did in the web browser. My job was to be the **Jenkins Administrator**. I used the one-time password to access the setup wizard, installed the necessary plugins, and created the first permanent admin user. My deliverable was a secured and usable Jenkins dashboard.

---

### Exploring the Commands and UI I Used
<a name="exploring-the-commands-and-ui-i-used"></a>
#### **Server-Side Commands**
-   `ssh root@...`: Connects to the server as the `root` user.
-   `yum install -y [package]`: Installs a software package and its dependencies. I used it for `wget` and `java-17-openjdk-devel`.
-   `rpm --import [url]`: Imports a GPG key to verify the authenticity of a software repository.
-   `wget -O [file] [url]`: Downloads a file from a URL and saves it to a specific location (`-O`).
-   `systemctl start/enable jenkins`: The standard commands to start a service and configure it to launch on boot.
-   `systemctl status jenkins`: My verification command to check if the service was `active (running)`.
-   `journalctl -xeu jenkins.service`: The essential troubleshooting command to see *why* a service failed to start.
-   `cat /var/lib/jenkins/secrets/initialAdminPassword`: Displays the content of the initial password file.

#### **Client-Side (Web UI) Steps**
-   **Unlock Jenkins:** Pasted the password from the `cat` command.
-   **Install suggested plugins:** The one-click button to install the standard suite of plugins.
-   **Create First Admin User:** The web form where I entered the new user's details (`theadmin`, `Jim`, etc.) as required by the task.
   