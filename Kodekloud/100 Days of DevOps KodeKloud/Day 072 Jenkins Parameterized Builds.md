# DevOps Day 72: Creating a Parameterized Build

Today's task was a fantastic step up in my Jenkins journey. I moved beyond creating simple, static jobs to building a **parameterized job**. This is one of the most powerful features in Jenkins, as it transforms a single-purpose job into a flexible, reusable automation tool that can adapt to user input.

I learned how to add different types of parameters—a free-form `String Parameter` and a restrictive `Choice Parameter`—and then how to use those parameters as variables within my build script. This document is my detailed, first-person guide to that entire process, explaining the concepts and the UI steps I took.

## Table of Contents
- [DevOps Day 72: Creating a Parameterized Build](#devops-day-72-creating-a-parameterized-build)
  - [Table of Contents](#table-of-contents)
    - [The Task](#the-task)
    - [My Step-by-Step Solution](#my-step-by-step-solution)
      - [Phase 1: Creating the Job and Defining Parameters](#phase-1-creating-the-job-and-defining-parameters)
      - [Phase 2: Configuring the Build Step](#phase-2-configuring-the-build-step)
      - [Phase 3: Running and Verifying](#phase-3-running-and-verifying)
    - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
    - [Deep Dive: How Jenkins Exposes Parameters to the Build](#deep-dive-how-jenkins-exposes-parameters-to-the-build)
    - [Common Pitfalls](#common-pitfalls)
    - [Exploring the UI Used](#exploring-the-ui-used)

---

### The Task
<a name="the-task"></a>
My objective was to create a new, flexible Jenkins job. The specific requirements were:
1.  Create a Freestyle project named `parameterized-job`.
2.  The job must be **parameterized**.
3.  Add a **String Parameter** named `Stage` with a default value of `Build`.
4.  Add a **Choice Parameter** named `env` with three choices: `Development`, `Staging`, and `Production`.
5.  Configure a build step to run a shell script that prints the values of both parameters.
6.  Run the job at least once, selecting `Staging` for the `env` parameter.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The entire process was performed through the Jenkins web UI.

#### Phase 1: Creating the Job and Defining Parameters
1.  I logged into Jenkins as `admin` and from the dashboard, I clicked **`New Item`**.
2.  I entered the name `parameterized-job`, selected **`Freestyle project`**, and clicked **OK**.
3.  On the configuration page, under the "General" section, I checked the crucial box: **"This project is parameterized"**.
4.  I clicked the **"Add Parameter"** dropdown and selected **"String Parameter"**. I configured it with:
    -   Name: `Stage`
    -   Default Value: `Build`
5.  I clicked **"Add Parameter"** again and selected **"Choice Parameter"**. I configured it with:
    -   Name: `env`
    -   Choices (one per line):
        ```
        Development
        Staging
        Production
        ```

#### Phase 2: Configuring the Build Step
1.  I scrolled down to the **"Build Steps"** section, clicked **"Add build step"**, and chose **"Execute shell"**.
2.  In the command box, I wrote a simple script to print the values of the parameters. Jenkins makes these available as environment variables, so I accessed them with a `$`.
    ```bash
    echo "The selected stage is: $Stage"
    echo "The selected environment is: $env"
    ```
3.  I clicked **Save**.

#### Phase 3: Running and Verifying
1.  On the job's page, the "Build Now" link was now **"Build with Parameters"**. I clicked it.
2.  This took me to a build screen where I could input my parameters. As required, I selected **`Staging`** from the `env` dropdown menu.
3.  I clicked the **"Build"** button.
4.  I then clicked on the new build number in the "Build History" and went to its **"Console Output"**. The log showed the correct output, proving my success:
    ```
    + echo 'The selected stage is: Build'
    The selected stage is: Build
    + echo 'The selected environment is: Staging'
    The selected environment is: Staging
    Finished: SUCCESS
    ```

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
-   **Parameterized Builds**: This is a core feature that makes Jenkins jobs reusable and flexible. Instead of creating a hardcoded job that can only do one thing, a parameterized job accepts user input each time it's run. This is essential for CI/CD. For example, instead of separate jobs for deploying to different environments, I can have one "Deploy" job with an `env` parameter to choose the target.
-   **`String Parameter`**: This parameter type creates a simple text input box. It's perfect for when the user needs to provide free-form text, like a Git branch name to build, a version number, or a custom message.
-   **`Choice Parameter`**: This parameter type creates a dropdown menu with a pre-defined list of options. This is much better than a string parameter when the user must select from a limited set of valid options. It prevents typos and ensures that the job only receives input it can understand (e.g., `Production`, not `prod` or `production`).

---

### Deep Dive: How Jenkins Exposes Parameters to the Build
<a name="deep-dive-how-jenkins-exposes-parameters-to-the-build"></a>
This was the most important concept for me to grasp. How does the value I select in the UI get into my shell script?



-   **Environment Variables:** When Jenkins starts a build, it takes all the parameters defined for the job and **injects them into the build's environment as environment variables**.
-   **The Magic of `$VARIABLE`:** The shell automatically substitutes variables that start with a `$` with their value from the environment.
    -   When my script ran `echo "The selected environment is: $env"`, the shell saw `$env`.
    -   It looked in its environment, found a variable named `env` that Jenkins had set to `Staging` (the value I selected).
    -   It then substituted the variable, so the final command that was actually executed was `echo "The selected environment is: Staging"`.
-   **Universality:** This principle applies to almost all build tools Jenkins integrates with. Whether I'm writing a shell script, a Maven command, a Gradle build, or an Ansible playbook, I can access the Jenkins parameters as environment variables, making them universally accessible.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Forgetting to Check "This project is parameterized"**: If this box isn't checked, the "Add Parameter" button won't appear, and the job won't be parameterized.
-   **Variable Name Mismatch:** Jenkins parameter names are **case-sensitive**. If I had named my parameter `Stage` but tried to access it as `$stage` in my script, the variable would have been empty.
-   **Incorrectly Formatting Choices:** For a Choice Parameter, the options must be entered one per line in the configuration.
-   **Not Quoting Variables:** While not an issue in my simple `echo` command, in a more complex script, it's a best practice to wrap variables in double quotes (e.g., `echo "$env"`). This prevents the shell from misinterpreting spaces or special characters that might be in the parameter's value.

---

### Exploring the UI Used
<a name="exploring-the-ui-used"></a>
This task was entirely UI-based. The key navigation paths and sections were:
-   **`Dashboard` > `New Item`**: The starting point for creating my Freestyle project.
-   **`[Job Name]` > `Configure`**: The main configuration page for the job, where I used:
    -   **`General` > `This project is parameterized`**: The checkbox to enable parameters.
    -   **`Add Parameter` Dropdown**: The menu where I selected the `String Parameter` and `Choice Parameter` types.
    -   **`Build Steps` > `Execute shell`**: The section where I defined the shell script that would be run.
-   **`[Job Name]` > `Build with Parameters`**: The new button on the job's page that appears for parameterized jobs. It takes you to the screen where you can input the parameter values before starting the build.
-   **`[Build Number]` > `Console Output`**: The page I used to check the logs of my build and verify that the parameters were being used correctly.
   