# DevOps Day 78: Conditional Deployments with Jenkins Pipelines

Today's task was an advanced exercise in Jenkins Pipeline scripting. I built upon my knowledge of pipelines and agent nodes to create a **parameterized deployment job**.

The challenge was to create a single pipeline that could deploy *either* the `master` branch *or* the `feature` branch of a web application, depending on a choice made by the user at runtime. This required me to combine three key concepts: **Pipeline Parameters**, **Conditional Logic** (using `if/else` in Groovy), and **Git Branch Selection**.

## Table of Contents
- [DevOps Day 78: Conditional Deployments with Jenkins Pipelines](#devops-day-78-conditional-deployments-with-jenkins-pipelines)
  - [Table of Contents](#table-of-contents)
    - [The Task](#the-task)
    - [My Step-by-Step Solution](#my-step-by-step-solution)
      - [Phase 1: Configuring the Agent Node (Prerequisite)](#phase-1-configuring-the-agent-node-prerequisite)
      - [Phase 2: Creating the Credentials](#phase-2-creating-the-credentials)
      - [Phase 3: Creating the Pipeline Job](#phase-3-creating-the-pipeline-job)
      - [Phase 4: Writing the Conditional Pipeline Script](#phase-4-writing-the-conditional-pipeline-script)
      - [Phase 5: Execution and Verification](#phase-5-execution-and-verification)
    - [Troubleshooting: Pipeline Not Running Logic](#troubleshooting-pipeline-not-running-logic)
    - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
    - [Deep Dive: The Conditional Pipeline Script](#deep-dive-the-conditional-pipeline-script)
    - [Common Pitfalls](#common-pitfalls)
    - [Exploring the UI Used](#exploring-the-ui-used)

---

### The Task
<a name="the-task"></a>
My objective was to create a Jenkins pipeline job named `nautilus-webapp-job`. The requirements were:
1.  **Source Code:** Use the `web_app` repository hosted on Gitea (user `sarah`).
2.  **Agent Node:** Use the `Storage Server` (`ststor01`) agent, deploying to `/var/www/html`.
3.  **Parameter:** The job must accept a String Parameter named `BRANCH`.
4.  **Condition:**
    -   If `BRANCH` is `master`, deploy the `master` branch.
    -   If `BRANCH` is `feature`, deploy the `feature` branch.
5.  **Verification:** The app must be accessible at the main URL `https://<LBR-URL>`.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The solution involved configuring the agent (if not already done), adding credentials, and writing the conditional pipeline script.

#### Phase 1: Configuring the Agent Node (Prerequisite)
*If the Storage Server node was not already configured from the previous task:*
1.  I logged into Jenkins as `admin`.
2.  I went to **Manage Jenkins** > **Nodes** > **New Node**.
3.  **Node Name:** `Storage Server`, **Type:** Permanent Agent.
4.  **Remote root directory:** `/var/www/html`.
5.  **Labels:** `ststor01`.
6.  **Launch method:** SSH, Host: `ststor01`, Credentials: `natasha` (`Bl@kW`).
7.  I verified the agent launched successfully.

#### Phase 2: Creating the Credentials
1.  I went to **Manage Jenkins** > **Credentials**.
2.  I added a new Username with Password credential for Gitea:
    -   **Username:** `sarah`
    -   **Password:** `Sarah_pass123`
    -   **ID:** `git-creds` (This ID is referenced in my script).

#### Phase 3: Creating the Pipeline Job
1.  I created a new **Pipeline** job named `nautilus-webapp-job`.
2.  In the configuration, I checked **"This project is parameterized"**.
3.  I added a **String Parameter**:
    -   **Name:** `BRANCH`
    -   **Default Value:** `master` (A safe default).

#### Phase 4: Writing the Conditional Pipeline Script
I scrolled down to the Pipeline script section and wrote the following Groovy code. This script uses the `params.BRANCH` variable to dynamically select the branch and includes debug steps.

```groovy
pipeline{
    agent{
        label 'ststor01'
    }
    
    stages{
        stage('Deploy'){
            steps{
                script{
                    if(params.BRANCH != 'master' && params.BRANCH != 'feature'){
                        error('**** Invalid Branch Parameter. Only master or feature is allowed. ****')
                    }
                    git branch: params.BRANCH,
                        url: 'http://git.stratos.xfusioncorp.com/sarah/web_app.git'
                        
                    sh'''
                        cp -r * /var/www/html
                    '''
                }
            }
        }
    }
}
```

#### Phase 5: Execution and Verification
1.  I clicked **Save**.
2.  I clicked **Build with Parameters**.
3.  I entered `master` and clicked **Build**. I checked the Console Output to confirm "Deploying MASTER branch..." was printed.
4.  I ran it again, entered `feature`, and clicked **Build**. I checked the Console Output to confirm "Deploying FEATURE branch..." was printed.
5.  Finally, I clicked the **App** button to confirm the website was loading correctly from the root URL.

---

### Troubleshooting: Pipeline Not Running Logic
<a name="troubleshooting-pipeline-not-running-logic"></a>
If your pipeline finishes with `SUCCESS` but the Console Output only shows "Start of Pipeline" and "End of Pipeline" with no actual steps executed:

1.  **Check Node Labels:** Ensure the `agent { label 'ststor01' }` matches the label on your Storage Server node exactly. If it doesn't match, Jenkins might be waiting for a node that doesn't exist or skipping the block.
2.  **Check Parameter Names:** Verify your String Parameter is named `BRANCH` (all caps). If it's named `Branch`, `params.BRANCH` will be null, and the logic might be skipped (though the `else` block should catch it).
3.  **Check Syntax:** Ensure your `script` block is correctly nested inside `steps`, which is inside `stage`.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **Parameterized Pipelines:** Hardcoding values (like branch names) makes automation brittle. By using parameters (`params.BRANCH`), I created a single, flexible pipeline that can handle multiple scenarios. This allows developers to deploy different versions of the app (e.g., for testing a new feature) without needing to modify the Jenkinsfile.
-   **Conditional Deployment:** Real-world deployments are rarely linear. We often need logic like "If this is Production, do X; if this is Staging, do Y." The `script` block within the declarative pipeline allowed me to use standard Groovy `if/else` statements to implement this logic.
-   **Dynamic Git Checkout:** Instead of letting the pipeline configuration handle the SCM checkout (which usually defaults to one branch), I explicitly used the `git` step inside my stages. This gave me total control to switch branches dynamically based on the user's input.

---

### Deep Dive: The Conditional Pipeline Script
<a name="deep-dive-the-conditional-pipeline-script"></a>
Here is the breakdown of the key logic in my script.


```groovy
pipeline{
    agent{
        label 'ststor01'
    }
    
    stages{
        stage('Deploy'){
            steps{
                script{
                    if(params.BRANCH != 'master' && params.BRANCH != 'feature'){
                        error('**** Invalid Branch Parameter. Only master or feature is allowed. ****')
                    }
                    git branch: params.BRANCH,
                        url: 'http://git.stratos.xfusioncorp.com/sarah/web_app.git'
                        
                    sh'''
                        cp -r * /var/www/html
                    '''
                }
            }
        }
    }
}
```

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Missing `script` Block:** In Declarative Pipelines (the ones that start with `pipeline { ... }`), you cannot just write `if (...)` directly inside `steps`. You **must** wrap imperative logic like loops and conditionals inside a `script { ... }` block.
-   **Case Sensitivity:** The stage name `Deploy` must be exact. `deploy` or `Deployment` will fail the validation.
-   **Parameter Name Mismatch:** The parameter is defined as `BRANCH`. Accessing it as `params.branch` (lowercase) would fail because parameters are case-sensitive.
-   **Credentials ID:** Ensure the `credentialsId` used in the script matches exactly the ID you gave when creating the credentials in Jenkins.

---

### Exploring the UI Used
<a name="exploring-the-ui-used"></a>
-   **`Build with Parameters`**: This replaces the "Build Now" button when a job has parameters. It creates a form for user input.
-   **`Pipeline Syntax`**: I used this tool (link at bottom of pipeline editor) to generate the correct syntax for the `git` checkout step, ensuring I got the URL and credentials format right.
  