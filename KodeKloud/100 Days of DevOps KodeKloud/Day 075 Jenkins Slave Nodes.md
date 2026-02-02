# DevOps Day 75: Distributed Builds with Jenkins Agent Nodes

Today's task was a crucial step in scaling a CI/CD infrastructure. I moved away from running everything on the single Jenkins server (the "Master" or "Controller") and set up a **Distributed Build Architecture**. I connected three external application servers to Jenkins as **Agent Nodes** (often called Slaves) using SSH.

This allows Jenkins to offload work. Instead of the Jenkins server compiling code, running tests, and deploying apps itself, it delegates these heavy tasks to the agents (`stapp01`, `stapp02`, `stapp03`). This improves performance, security, and isolation. This document is my detailed guide to configuring these nodes via the Jenkins UI, including a fix for the common "Java not found" error.

## Table of Contents
- [DevOps Day 75: Distributed Builds with Jenkins Agent Nodes](#devops-day-75-distributed-builds-with-jenkins-agent-nodes)
  - [Table of Contents](#table-of-contents)
    - [The Task](#the-task)
    - [My Step-by-Step Solution](#my-step-by-step-solution)
      - [Phase 1: Prerequisites \& Plugin Check](#phase-1-prerequisites--plugin-check)
      - [Phase 2: Adding Credentials](#phase-2-adding-credentials)
      - [Phase 3: Configuring App Server 1](#phase-3-configuring-app-server-1)
      - [Phase 4: Configuring App Servers 2 \& 3](#phase-4-configuring-app-servers-2--3)
    - [Troubleshooting: Agent Launch Failure (Java Not Found)](#troubleshooting-agent-launch-failure-java-not-found)
    - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
    - [Deep Dive: The Jenkins Master/Agent Architecture](#deep-dive-the-jenkins-masteragent-architecture)
    - [Common Pitfalls](#common-pitfalls)
    - [Exploring the UI Used](#exploring-the-ui-used)

---

### The Task
<a name="the-task"></a>
My objective was to add three new agent nodes to the Jenkins environment. The requirements were:
1.  **App Server 1:** Name `App_server_1`, Label `stapp01`, Root Dir `/home/tony/jenkins`.
2.  **App Server 2:** Name `App_server_2`, Label `stapp02`, Root Dir `/home/steve/jenkins`.
3.  **App Server 3:** Name `App_server_3`, Label `stapp03`, Root Dir `/home/banner/jenkins`.
4.  Ensure all nodes are connected via SSH and are online.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The entire process involved both command-line preparation and Jenkins UI configuration.

#### Phase 1: Prerequisites & Plugin Check
1.  I logged into Jenkins as `admin` (`Adm!n321`).
2.  I navigated to **Manage Jenkins** > **Plugins** to ensure the **"SSH Agent Plugin"** or **"SSH Build Agents"** plugin was installed.

#### Phase 2: Adding Credentials
Before creating the nodes, I added the credentials for the users on the remote servers.
1.  I went to **Manage Jenkins** > **Credentials** > **(global)** > **Add Credentials**.
2.  I added three separate "Username with password" credentials:
    * **Tony:** User `tony`, Password `Ir0nM@n`, ID `tony-creds`.
    * **Steve:** User `steve`, Password `Am3ric@`, ID `steve-creds`.
    * **Banner:** User `banner`, Password `BigGr33n`, ID `banner-creds`.

#### Phase 3: Configuring App Server 1
1.  I went to **Manage Jenkins** > **Nodes** (or "Manage Nodes and Clouds").
2.  I clicked **"New Node"**.
3.  **Node Name:** `App_server_1`.
4.  **Type:** Selected **"Permanent Agent"** and clicked Create.
5.  I configured the node details:
    * **Remote root directory:** `/home/tony/jenkins`
    * **Labels:** `stapp01`
    * **Usage:** "Use this node as much as possible"
    * **Launch method:** "Launch agents via SSH"
    * **Host:** `stapp01`
    * **Credentials:** Selected the `tony` credential I created earlier.
    * **Host Key Verification Strategy:** Selected **"Non verifying Verification Strategy"**.
6.  I clicked **Save**.

#### Phase 4: Configuring App Servers 2 & 3
I repeated the exact same process for the other two servers, ensuring I swapped the details correctly.

* **App_server_2:**
    * Remote root: `/home/steve/jenkins`
    * Label: `stapp02`
    * Host: `stapp02`
    * Credentials: `steve`

* **App_server_3:**
    * Remote root: `/home/banner/jenkins`
    * Label: `stapp03`
    * Host: `stapp03`
    * Credentials: `banner`

---

### Troubleshooting: Agent Launch Failure (Java Not Found)
<a name="troubleshooting-agent-launch-failure-java-not-found"></a>
When I first tried to launch the agents, they failed to connect. Checking the logs revealed the following error:
```
[SSH] Starting agent process: cd "/home/banner/jenkins" && java -jar remoting.jar ...
bash: line 1: java: command not found
Agent JVM has terminated. Exit code=127
```

**The Problem:** Jenkins agents run as a Java application (`remoting.jar`). The remote server MUST have a Java Runtime Environment (JRE) installed for the agent to run. The app servers in this lab did not have Java pre-installed.

**The Fix:**
I had to manually install Java on all three app servers.

1.  **SSH into each app server:**
    ```bash
    ssh tony@stapp01  # password: Ir0nM@n
    ssh steve@stapp02 # password: Am3ric@
    ssh banner@stapp03 # password: BigGr33n
    ```
2.  **Install Java:**
    ```bash
    sudo yum install -y java-17-openjdk
    ```
3.  **Relaunch the Agent:** Back in the Jenkins UI, I clicked "Launch agent" for each node. This time, they connected successfully.

**Verification:** I refreshed the nodes list. All three servers showed free disk space and no red "X" marks, indicating they were online and ready to accept build tasks.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
-   **Scalability:** A single Jenkins server can only run so many builds at once before it runs out of CPU or RAM. By adding agents, I can run dozens or hundreds of builds in parallel.
-   **Security & Isolation:** It is a security best practice to **not** run builds on the Jenkins controller itself. If a build script is malicious or simply messy (deleting system files), it could destroy the Jenkins server. Running builds on agents isolates this risk to a replaceable worker node.
-   **Environment Specifics:** Different projects need different tools. I might need one agent with Java 17 for a backend project and another agent with Node.js and Chrome for a frontend project. Agents allow me to create specialized environments without polluting the main server.

---

### Deep Dive: The Jenkins Master/Agent Architecture
<a name="deep-dive-the-jenkins-masteragent-architecture"></a>
This task established the fundamental architecture of enterprise Jenkins.

[Image of Jenkins Master-Slave architecture diagram]

1.  **The Controller (Master):** This is the brain. It handles the UI, scheduling, user permissions, and orchestration. It tells the agents *what* to do.
2.  **The Agent (Slave):** This is the muscle. It receives instructions from the controller, executes the build steps (shell scripts, maven builds, etc.), and reports the results back.
3.  **Communication via SSH:** In this lab, the Controller connects to the Agents ("pushes" the connection). It logs in via SSH, copies a small `agent.jar` file to the `Remote root directory`, and starts it using Java. This Java process then communicates back to the Controller.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Java Version Mismatch:** The agent machine *must* have a compatible version of Java installed (usually Java 11 or 17). If the app servers didn't have Java, the connection would fail immediately.
-   **Host Key Verification:** If you choose "Known hosts file verification strategy" but the Jenkins server hasn't SSH'd into the agent before, the connection will fail because the host key isn't trusted. "Non verifying" is safer for quick labs.
-   **Directory Permissions:** The user (`tony`, `steve`, etc.) must have write permissions to the `Remote root directory`. If `/home/tony/jenkins` couldn't be created, the agent would fail to launch.

---

### Exploring the UI Used
<a name="exploring-the-ui-used"></a>
-   **`Manage Jenkins` > `Nodes`**: The control center for your build fleet.
-   **`New Node`**: The wizard for registering a new agent.
-   **`Launch agents via SSH`**: The specific launch method configuration where you define the Host IP/Hostname and select the Credentials.
   