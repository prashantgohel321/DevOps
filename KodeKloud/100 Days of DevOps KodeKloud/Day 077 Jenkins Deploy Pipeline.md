# DevOps Day 77: Deploying a Static Website with a Jenkins Pipeline

Today's task was a major milestone: creating a **Jenkins Pipeline** to automate the deployment of a real application. I moved beyond simple "Freestyle" jobs and wrote a Groovy-based pipeline script that integrates with a Git repository (Gitea) and deploys code to a remote server.

The goal was to deploy a static website from a Gitea repository to an Apache web server running on a specific storage node. This required me to configure a new agent node in Jenkins, understand the application's architecture (where files are stored vs. where they are served), and write a pipeline script to orchestrate the deployment. This document is my detailed guide to that entire process.

## Table of Contents
- [DevOps Day 77: Deploying a Static Website with a Jenkins Pipeline](#devops-day-77-deploying-a-static-website-with-a-jenkins-pipeline)
  - [Table of Contents](#table-of-contents)
    - [The Task](#the-task)
    - [My Step-by-Step Solution](#my-step-by-step-solution)
      - [Phase 1: Configuring the Agent Node](#phase-1-configuring-the-agent-node)
      - [Phase 2: Creating the Pipeline Job](#phase-2-creating-the-pipeline-job)
      - [Phase 3: Writing the Pipeline Script](#phase-3-writing-the-pipeline-script)
      - [Phase 4: Execution and Verification](#phase-4-execution-and-verification)
    - [Troubleshooting: Agent Permission Denied](#troubleshooting-agent-permission-denied)
    - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
    - [Deep Dive: The Jenkins Pipeline Script](#deep-dive-the-jenkins-pipeline-script)
    - [Common Pitfalls](#common-pitfalls)
    - [Exploring the UI Used](#exploring-the-ui-used)

---

### The Task
<a name="the-task"></a>
My objective was to create a Jenkins pipeline job named `devops-webapp-job`. The requirements were:
1.  **Source Code:** Use the `web_app` repository hosted on the internal Gitea server (user `sarah`).
2.  **Agent Node:** Add the `Storage Server` (`ststor01`) as a Jenkins agent, as this server has the repository cloned and the web root mounted.
3.  **Deployment Target:** Deploy the code to `/var/www/html` on the `Storage Server`.
4.  **Pipeline:** Use a single stage named `Deploy` (case-sensitive).
5.  **Verification:** The app must be accessible at the main URL `https://<LBR-URL>` (not a sub-directory).

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The solution involved configuring the agent node first, and then creating the pipeline job.

#### Phase 1: Configuring the Agent Node
Before creating the job, I had to register the Storage Server as a worker node so Jenkins could run commands on it.
1.  I logged into Jenkins as `admin` (`Adm!n321`).
2.  I went to **Manage Jenkins** > **Nodes** > **New Node**.
3.  **Node Name:** `Storage Server`, Type: **Permanent Agent**.
4.  I configured the node details:
    -   **Remote root directory:** `/var/www/html` (This is crucial as it's the deployment target).
    -   **Labels:** `ststor01` (This is how my pipeline will select this specific node).
    -   **Launch method:** "Launch agents via SSH".
    -   **Host:** `ststor01`.
    -   **Credentials:** I added a new "Username with password" credential for `natasha` (password `Bl@kW`).
    -   **Host Key Verification Strategy:** "Non verifying Verification Strategy".
5.  I clicked **Save**.

#### Phase 2: Creating the Pipeline Job
1.  From the Dashboard, I clicked **New Item**.
2.  **Name:** `devops-webapp-job`.
3.  **Type:** `Pipeline`.
4.  I clicked **OK**.

#### Phase 3: Writing the Pipeline Script
In the job configuration, I scrolled down to the **Pipeline** section. I chose **"Pipeline script"** and wrote the following Groovy code. Note that I also added credentials for Gitea (`sarah`/`Sarah_pass123`) with ID `git-creds` before this step.

```groovy
pipeline {
    agent {
        label 'ststor01' // Runs this pipeline on the Storage Server agent
    }
    stages {
        stage('Deploy') { // The required stage name
            steps {
                // Checkout code from Gitea to the workspace on the agent
                git url: '[http://git.stratos.xfusioncorp.com/sarah/web_app.git](http://git.stratos.xfusioncorp.com/sarah/web_app.git)',
                    credentialsId: 'git-creds',
                    branch: 'master'

                // Copy the files from the workspace to the Apache document root
                // The workspace is inside /var/www/html (because that's the node's root dir)
                // We use sudo if needed, or ensure permissions are correct (see Troubleshooting below)
                sh 'cp -r * /var/www/html/' 
            }
        }
    }
}
```

#### Phase 4: Execution and Verification
1.  I clicked **Save** and then **Build Now**.
2.  I watched the stage view showing the "Deploy" stage turning green.
3.  I verified by clicking the **App** button. The website loaded at the root URL (e.g., `https://.../index.html`), not inside a `/web_app` subfolder, confirming the copy command worked correctly.

---

### Troubleshooting: Agent Permission Denied
<a name="troubleshooting-agent-permission-denied"></a>
If the agent fails to launch with `java.io.IOException: Could not copy remoting.jar` and `Permission denied`, it means the user (`natasha`) cannot write to the remote root directory (`/var/www/html`).

**The Fix:**
1.  **SSH into the Storage Server:**
    ```bash
    ssh natasha@ststor01
    # Password: Bl@kW
    ```
2.  **Change Directory Ownership:** Give `natasha` ownership of the web root so Jenkins can write its agent files there.
    ```bash
    sudo chown -R natasha:natasha /var/www/html
    ```
3.  **Relaunch Agent:** Go back to Jenkins -> Nodes, click `Storage Server`, and click **Launch agent**. It should now connect.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **Jenkins Pipeline:** This is the modern way to define CI/CD jobs. Unlike Freestyle jobs (which are UI-based configuration), Pipelines are defined as code (Groovy). This allows the build process to be versioned, reviewed, and managed just like the application code itself.
-   **Agent Labels:** By labeling the node `ststor01` and using `agent { label 'ststor01' }`, I explicitly told Jenkins *where* to run this job. This is critical in this architecture because the Storage Server is the only machine that has the shared storage mounted. If the job ran on the Jenkins master or another node, the copy command would fail or copy files to the wrong place.
-   **Shared Storage Architecture:** This task relied on a common NFS-style setup. The Storage Server holds the files at `/var/www/html`. The App Servers (where Apache runs) mount that directory. By deploying code to the Storage Server, I automatically updated all App Servers simultaneously.

---

### Deep Dive: The Jenkins Pipeline Script
<a name="deep-dive-the-jenkins-pipeline-script"></a>
This is the declarative pipeline syntax I used.


```groovy
pipeline {
    agent {
        label 'ststor01' // 1. Select the correct worker node
    }
    stages {
        stage('Deploy') { // 2. Define the stage (Case Sensitive Name!)
            steps {
                // 3. The Git Step: Downloads the code from Gitea
                git url: '[http://git.stratos.xfusioncorp.com/sarah/web_app.git](http://git.stratos.xfusioncorp.com/sarah/web_app.git)',
                    credentialsId: 'git-creds', // ID of the credentials I added
                    branch: 'master'

                // 4. The Shell Step: Deploys the code
                // Because the node's root dir is /var/www/html, Jenkins puts the code in
                // /var/www/html/workspace/job-name/
                // We copy it UP two levels to /var/www/html/ to be served by Apache.
                sh 'cp -rf ./* /var/www/html/'
            }
        }
    }
}
```

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Agent Root Directory:** Setting the agent's remote root directory to `/var/www/html` is dangerous if not handled carefully. Jenkins will create workspace folders there. If you run a command like `rm -rf *` in the wrong place, you could wipe the entire web server root.
-   **Sub-directory Deployment:** A common mistake is copying the *folder* `web_app` instead of its *contents*. If you do `cp -r web_app /var/www/html`, the site loads at `.../web_app/`, which violates the requirement. Using `cp -r *` (contents) ensures it loads at the root URL.
-   **Case Sensitivity:** The requirement for the stage name `Deploy` is strict. Naming it `deploy` or `Deployment` would cause the task verification to fail.

---

### Exploring the UI Used
<a name="exploring-the-ui-used"></a>
-   **`Manage Jenkins` > `Nodes`**: Where I added the specific `Storage Server` agent.
-   **`New Item` > `Pipeline`**: The job type selection.
-   **`Pipeline` section**: The text area in the job configuration where I wrote the Groovy script. This replaces the "Build Steps" section of Freestyle jobs.
-   **`Pipeline Syntax` generator**: A link at the bottom of the script editor. It's an incredibly useful tool that helps write valid Groovy code for steps like `git` or `sh` without having to memorize the syntax.
   