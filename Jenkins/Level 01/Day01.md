# Jenkins Level 1, Task 1: My First Jenkins Server Installation

Today, I took the first and most crucial step into the world of CI/CD by installing a Jenkins automation server. This task was a fantastic, real-world experience because it wasn't just a simple installation. I encountered and had to solve several prerequisite and dependency issues, which is a core part of any system administrator's job.

This document details my entire journey, from the initial commands to the troubleshooting process and the final UI setup. I'm not just recording what I did, but why I did it and what I learned from the failures along the way.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [My Troubleshooting Journey: A Detective Story](#my-troubleshooting-journey-a-detective-story)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: The Jenkins Startup Process](#deep-dive-the-jenkins-startup-process)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands Used](#exploring-the-commands-used)

---

### The Task
<a name="the-task"></a>
My objective was to set up a fully functional Jenkins server. The process was divided into two main parts:
1.  **Server-Side Installation:** Log into the dedicated Jenkins server, install Jenkins using `yum`, and start the service.
2.  **UI Setup:** Access the Jenkins web interface, unlock it with the initial password, and create a permanent admin user with specific credentials.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
My path to success involved a critical troubleshooting phase, but the final, correct sequence of commands on the server was as follows.

#### Phase 1: Server-Side Installation (The Corrected Path)
I performed these steps as the `root` user on the Jenkins server.

1.  **Connect to the Jenkins Server:** First, I had to get from the jump host to the Jenkins server.
    ```bash
    ssh root@jenkins.stratos.xfusioncorp.com
    ```

2.  **Install `wget`:** My first attempt failed because `wget` wasn't installed. The first step in the corrected process was to install this dependency.
    ```bash
    sudo yum install -y wget
    ```

3.  **Install Correct Java Version:** My second failure was due to an incorrect Java version. The key to success was installing Java 17 (or newer) *before* installing Jenkins.
    ```bash
    sudo yum install -y java-17-openjdk
    ```

4.  **Add Jenkins Repository:** With the prerequisites in place, I added the official Jenkins repository so `yum` could find the package.
    ```bash
    sudo wget -O /etc/yum.repos.d/jenkins.repo [https://pkg.jenkins.io/redhat/jenkins.repo](https://pkg.jenkins.io/redhat/jenkins.repo)
    sudo rpm --import [https://pkg.jenkins.io/redhat/jenkins.io-2023.key](https://pkg.jenkins.io/redhat/jenkins.io-2023.key)
    ```
    
5.  **Install Jenkins Dependencies and Jenkins:** The installation required some extra dependencies like `fontconfig` and `java-21-openjdk`.
    ```bash
    sudo yum upgrade
    sudo yum install fontconfig java-21-openjdk
    sudo yum install jenkins
    ```

6.  **Start and Enable Jenkins:** With all dependencies met, the service started successfully.
    ```bash
    sudo systemctl start jenkins
    sudo systemctl enable jenkins
    ```

7.  **Retrieve Initial Password:** I got the temporary password needed to unlock the UI.
    ```bash
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword
    ```

---

### Phase 2: Initial Setup (Web UI)
This part of the process was smooth once the server-side issues were resolved.

1. I clicked the Jenkins button in the lab UI to open the web page.

2. On the "Unlock Jenkins" screen, I pasted the password from the step above.

3. I chose "Install suggested plugins" and waited for the process to complete.

4. On the "Create First Admin User" screen, I entered the exact details required:

    - Username: theadmin

    - Password: Adm!n321

    - Full name: Siva

    - E-mail: siva@jenkins.stratos.xfusioncorp.com

5. I clicked "Save and Continue," confirmed the instance URL on the next page, and finally clicked "Start using Jenkins." I was then logged into the main Jenkins dashboard.

---

### My Troubleshooting Journey: A Detective Story
<a name="my-troubleshooting-journey-a-detective-story"></a>
This task was a fantastic lesson in methodical troubleshooting. My installation didn't work on the first try, and I had to peel back the layers to find the root cause.

#### Failure 1: wget: command not found

- **Symptom**: When I tried to download the Jenkins repository file, the shell told me the `wget` command didn't exist.

- **Diagnosis**: This was a simple missing dependency. The minimal server OS didn't include this common download utility.

- Solution: I solved it by running `sudo yum install -y wget`.

#### Failure 2: Jenkins Service Fails to Start

- **Symptom**: After installing Jenkins, `sudo systemctl start jenkins` failed with a generic error.

- **Diagnosis**: I used the command the system suggested: `journalctl -xeu jenkins.service`. By reading the logs carefully, I found the "smoking gun":
Running with Java 11 ... which is older than the minimum required version (Java 17).

- **Solution**: This told me everything. The Jenkins version I installed requires at least Java 17, but the server only had Java 11. The fix was to install the correct version: `sudo yum install -y java-17-openjdk`. After this, the Jenkins service started perfectly.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>

- **Jenkins**: This is an open-source automation server that acts as the heart of a CI/CD pipeline. CI/CD (Continuous Integration / Continuous Deployment) is the practice of automating the software delivery process. Jenkins can watch my code repository, and whenever a developer pushes a change, it can automatically build, test, and deploy the application.

- **Java Prerequisite**: Jenkins is a *Java* application, meaning it's written in the Java programming language. It cannot run without a Java Runtime Environment (JRE) or Java Development Kit (JDK) installed on the server. My troubleshooting proved how critical this dependency is.

- **yum and Repositories**: `yum` is the *package manager* for this server. By default, it only knows about a standard set of software. To install third-party software like Jenkins, I first had to add the official Jenkins "repository" to yum's list of sources. This tells `yum` where to find and download the Jenkins package.

- **Initial Admin Password**: This is a crucial security feature. When Jenkins is first installed, it's in an unlocked state. It generates a long, random, one-time-use password and stores it on the server. This ensures that only someone with access to the server's file system can perform the initial setup and secure the instance.

---

### Deep Dive: The Jenkins Startup Process
<a name="deep-dive-the-jenkins-startup-process"></a>
My troubleshooting journey gave me a clear insight into how a service like Jenkins starts.

1. `systemctl start jenkins` is executed. `systemd` (the service manager) reads the jenkins.service file.

2. The service file executes the main command, which is typically a script that starts the Java process (java -jar jenkins.war ...).

3. Jenkins' internal checks run. Before it even tries to start the web server, Jenkins performs pre-flight checks. My log analysis showed one of these checks is for the Java version.

4. **Failure Point**: When the Java version check failed, Jenkins printed the error message to its log and exited with a non-zero status code (status=1/FAILURE).

5. `systemd` reports the failure. systemd sees that the main process exited with an error and marks the service as failed.

This showed me that reading the specific application's logs (journalctl) is far more valuable than just looking at the generic systemctl status output.

---

### Common Pitfalls
<a name="common-pitfalls"></a>

- **Missing Prerequisites**: As I discovered, the most common reason for a Jenkins installation to fail is a missing or incorrect Java version.

- **Port Conflicts**: If another service were running on port 8080, Jenkins would have failed with an "Address already in use" error.

- **Firewall Issues**: If the server's firewall was blocking port 8080, the service might be running, but I wouldn't be able to access the UI from my browser.

- **Forgetting to Copy the Initial Password**: Trying to guess or find the password later can be a hassle. Copying it immediately after starting the service is the most efficient workflow.

---

### Exploring the Commands Used
<a name="exploring-the-commands-used"></a>

- **`sudo yum install -y [package]`**: Installs a software package and its dependencies. I used it for `wget` and `java-17-openjdk`.

- **`sudo rpm --import [url]`**: Imports a GPG key to verify the authenticity of a software repository.

- **`sudo wget -O [file] [url]`**: Downloads a file from a URL and saves it to a specific location.

- **`sudo systemctl start/enable [service]`**: The standard commands to start a service and configure it to launch on boot.

- **`sudo systemctl status [service]`**: Shows the current status of a service, including recent log snippets.

- **`sudo journalctl -xeu [service]`**: It shows the detailed, full logs for a specific service, which is essential for deep troubleshooting.

- **`sudo cat /var/lib/jenkins/secrets/initialAdminPassword`**: Displays the content of the initial password file.