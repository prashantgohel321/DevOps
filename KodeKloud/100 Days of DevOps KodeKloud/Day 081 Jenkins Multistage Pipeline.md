# DevOps Day 81: CI/CD Pipeline with Deployment and Test Stages

Today's task was to create a structured **Jenkins Pipeline** that not only deploys code but also verifies the deployment with a **Test stage**. This represents a true CI/CD workflow where quality assurance is automated.

I configured a pipeline to pull code from Gitea, deploy it to a storage server using `sshpass` (a robust way to handle SSH passwords in pipelines without key-based auth), and then validate the application by checking the HTTP response of the load balancer.

## Table of Contents
- [DevOps Day 81: CI/CD Pipeline with Deployment and Test Stages](#devops-day-81-cicd-pipeline-with-deployment-and-test-stages)
  - [Table of Contents](#table-of-contents)
    - [The Task](#the-task)
    - [My Step-by-Step Solution](#my-step-by-step-solution)
      - [Phase 1: Code Update \& Git Push](#phase-1-code-update--git-push)
      - [Phase 2: Jenkins Configuration](#phase-2-jenkins-configuration)
      - [Phase 3: Creating the Pipeline](#phase-3-creating-the-pipeline)
      - [Phase 4: Verification](#phase-4-verification)
    - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
    - [Deep Dive: The Pipeline Script \& `sshpass`](#deep-dive-the-pipeline-script--sshpass)
    - [Common Pitfalls](#common-pitfalls)
    - [Exploring the UI Used](#exploring-the-ui-used)

---

### The Task
<a name="the-task"></a>
My objective was to create a Jenkins pipeline job named `deploy-job` with two specific stages:
1.  **Deploy Stage:** Pull code from the `sarah/web` repo (master branch) and copy it to `/var/www/html` on the `Storage Server` (`ststor01`).
2.  **Test Stage:** Verify the website is running by accessing the Load Balancer URL (`http://stlb01:8091`).
3.  **Prerequisites:** Update the `index.html` file in the repo before starting and ensure necessary plugins/credentials are set up.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The solution involved manual code updates, Jenkins configuration, and writing a Groovy pipeline script.

#### Phase 1: Code Update & Git Push
First, I had to act as the developer (`sarah`) to push the new content.
1.  I SSH'd into the Storage Server: `ssh natasha@ststor01` (Password: `Bl@kW`).
2.  I navigated to the repository: `cd /var/www/html/web` (or wherever Sarah's repo was cloned, usually her home or `/var/www/html`).
    * *Correction based on task:* The repo is "already cloned on Storage server under /var/www/html directory".
3.  I edited the file: `vi index.html`.
    * Content: `Welcome to xFusionCorp Industries`
4.  I committed the change:
    ```bash
    git add index.html
    git commit -m "Update index.html"
    git push origin master
    ```

#### Phase 2: Jenkins Configuration
1.  **Install Plugins:** Logged into Jenkins as `admin`. Went to **Manage Jenkins > Plugins**. Installed **Git** and **Pipeline** plugins. Restarted Jenkins.
2.  **Add Credentials:** Went to **Manage Jenkins > Credentials**.
    * Added **Username with password** for Gitea: `sarah` / `Sarah_pass123`, ID: `sarah-git-creds`.
    * Added **Username with password** for SSH: `natasha` / `Bl@kW`, ID: `ssh-storage-server`.

#### Phase 3: Creating the Pipeline
1.  Created a **New Item** named `deploy-job`, type **Pipeline**.
2.  In the **Pipeline** section, I entered the following script. I used `sshpass` because it allows passing the password variable directly to `scp` without setting up SSH keys, which fits the requirements of using the credentials stored in Jenkins.

```groovy
pipeline {
    agent any

    stages {
        stage('Deploy') {
            steps {
                // 1. Checkout Code from Gitea
                git branch: 'master',
                    credentialsId: 'sarah-git-creds',
                    url: 'http://git.stratos.xfusioncorp.com/sarah/web.git'

                // 2. Deploy using sshpass
                // We wrap this in 'withCredentials' to securely inject the password into environment variables.
                // We use single quotes for the outer sh command to prevent Groovy interpolation issues,
                // but double quotes inside are tricky.
                // Best practice is to use the environment variables directly.
                
                withCredentials([usernamePassword(credentialsId: 'ssh-storage-server', usernameVariable: 'SSH_USER', passwordVariable: 'SSH_PASS')]) {
                    // Using sshpass to run scp non-interactively
                    // -o StrictHostKeyChecking=no prevents the "unknown host" prompt
                    sh "sshpass -p '$SSH_PASS' scp -o StrictHostKeyChecking=no -r * $SSH_USER@ststor01:/var/www/html"
                }
            }
        }
        stage('Test') {
            steps {
                echo "Testing application accessibility..."
                // curl -f fails silently on server errors (404, 500) but returns exit code > 0
                // This ensures the stage fails if the site is down.
                sh 'curl -f http://stlb01:8091'
            }
        }
    }
}
```
3.  I clicked **Save** and **Build Now**.

#### Phase 4: Verification
1.  I watched the pipeline execution.
    * **Deploy Stage:** Green. Logs showed files copied.
    * **Test Stage:** Green. Logs showed the HTML content of the page fetched by curl.
2.  I clicked the **App** button in the top bar to verify visually. The text "Welcome to xFusionCorp Industries" was displayed correctly.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **Multi-Stage Pipeline:** Splitting the job into "Deploy" and "Test" provides clarity. If the build fails, I know immediately if it was a code transfer issue (Deploy) or an application runtime issue (Test).
-   **`withCredentials`:** This is the secure way to handle secrets in a Jenkins Pipeline. It injects the username and password into environment variables (`SSH_USER`, `SSH_PASS`) only for the scope of that block. They are masked in the console logs (`****`).
-   **`sshpass`**: Standard `scp` prompts for a password interactively, which hangs a CI job. `sshpass` wraps the command and supplies the password automatically. It's less secure than SSH keys but very useful when you cannot or should not set up keys.
-   **`curl -f`:** The `-f` (fail) flag is critical. Without it, `curl` might show a "404 Not Found" page but still exit with code `0` (Success), creating a false positive. `-f` makes `curl` return an error code on HTTP errors, causing the Jenkins stage to fail correctly.

---

### Deep Dive: The Pipeline Script & `sshpass`
<a name="deep-dive-the-pipeline-script-and-sshpass"></a>
The core logic relies on safely passing the password to the shell command.

```groovy
withCredentials([usernamePassword(credentialsId: 'ssh-storage-server', ...)]) {
    // 1. sshpass -p '${SSH_PASS}': Takes the injected password variable.
    // 2. scp -o StrictHostKeyChecking=no: Disables the "Are you sure?" prompt for new hosts.
    // 3. -r *: Recursive copy of everything in the workspace.
    // 4. ${SSH_USER}@ststor01:/var/www/html: Destination path.
    sh "sshpass -p '${SSH_PASS}' scp -o StrictHostKeyChecking=no -r * ${SSH_USER}@ststor01:/var/www/html"
}
```
*Note on Quoting:* I used double quotes `"` for the `sh` string so that Groovy would interpolate the `${SSH_PASS}` variable. I wrapped the variable itself in single quotes `'${SSH_PASS}'` inside the shell command to handle any special characters the password might contain.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Missing `sshpass`:** The `sshpass` utility must be installed on the Jenkins server (or agent) running the build. If it's missing, the command will fail with "command not found".
-   **File Permissions:** If `natasha` doesn't own `/var/www/html` on the storage server, the `scp` command will fail with "Permission denied".
-   **Stage Names:** The task specified "Deploy" and "Test" are case-sensitive. Using "deploy" or "test" would fail the requirements check.
-   **Curl without `-f`:** If the web server is up but serving a 403 or 500 error, a normal `curl` will just print the error page and pass the stage. Using `-f` ensures the pipeline actually catches the failure.

---

### Exploring the UI Used
<a name="exploring-the-ui-used"></a>
-   **`Pipeline Syntax` Snippet Generator:** I used this to generate the `withCredentials` block structure, as remembering the exact syntax for binding username/password variables is difficult.
-   **`Global Credentials`**: Where I securely stored the passwords so they didn't have to be hardcoded in the pipeline script.
   