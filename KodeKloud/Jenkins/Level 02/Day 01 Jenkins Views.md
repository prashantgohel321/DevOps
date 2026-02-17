# Jenkins Level 2, Task 1: Job Scheduling and Dashboard Organization with Views

Today's task was a fantastic dive into the day-to-day work of a Jenkins administrator. I went beyond just creating a simple job and learned how to automate its execution using a scheduler, and how to keep the main dashboard organized using **Views**. This is a critical skill, as a real-world Jenkins server can quickly become cluttered with dozens or hundreds of jobs.

This exercise covered the full lifecycle: creating a new job, adding a build step, creating a custom view to filter jobs, and then scheduling the job to run automatically. This document is my detailed, first-person guide to that entire process, explaining the concepts and the UI steps I took.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: The Importance of an Organized Jenkins Dashboard](#deep-dive-the-importance-of-an-organized-jenkins-dashboard)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the UI and Concepts Used](#exploring-the-ui-and-concepts-used)

---

### The Task
<a name="the-task"></a>
My objective was to create, organize, and schedule a new Jenkins job. The specific requirements were:
1.  Create a new Freestyle project named `nautilus-test-job`.
2.  Configure it to run the shell command `echo "hello world!!"`.
3.  Create a new **List View** named `nautilus-crons`.
4.  This new view must display both my new job (`nautilus-test-job`) and an existing job (`nautilus-cron-job`).
5.  Schedule my new job to run **every minute** using the cron expression `* * * * *`.
6.  Ensure the job runs successfully.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The entire process was performed through the Jenkins web UI.

#### Phase 1: Creating the Job
1.  I logged into Jenkins as `admin` and from the dashboard, I clicked **`New Item`**.
2.  I entered the name `nautilus-test-job`, selected **`Freestyle project`**, and clicked **OK**.
3.  In the configuration page, I scrolled to the **"Build Steps"** section, clicked **"Add build step"**, and chose **"Execute shell"**.
4.  In the command box, I typed: `echo "hello world!!"`
5.  I clicked **Save**.

#### Phase 2: Creating the View
With the job created, my next step was to organize the dashboard.
1.  I went back to the main **Dashboard**. Next to the default "All" tab, I clicked the **`+`** icon.
2.  I entered the **View Name** as `nautilus-crons`, selected the **`List View`** type, and clicked **Create**.
3.  On the view configuration page, I scrolled down to **"Job Filters"**. I checked the boxes next to the two required jobs: `nautilus-cron-job` and `nautilus-test-job`.
4.  I clicked **Save**. I was then taken to my new view, which correctly showed only those two jobs.

#### Phase 3: Scheduling the Job
1.  I navigated back to my `nautilus-test-job` and clicked **`Configure`**.
2.  I scrolled to the **"Build Triggers"** section and checked the box for **"Build periodically"**.
3.  In the **"Schedule"** text box, I entered the cron expression exactly as required:
    ```
    * * * * *
    ```
4.  I clicked **Save**.

#### Phase 4: Verification
The final and most important step was to see it all work.
1.  I stayed on the `nautilus-test-job` page and watched the **"Build History"** panel.
2.  Within a minute, a new build (`#1`) appeared automatically.
3.  I clicked on the build number, then on **"Console Output"**. The log showed my `echo` command and the message `Finished: SUCCESS`. This was the definitive proof that the job was created, scheduled, and running correctly.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **Jenkins Job (Freestyle project)**: A job is the fundamental unit of work in Jenkins. A Freestyle project is the most basic and flexible type, where I can manually configure any combination of steps, such as pulling code from Git, running a shell script, or archiving artifacts.
-   **Jenkins Views**: Views are essentially **filters for your dashboard**. As the number of jobs on a Jenkins server grows, the main "All" view becomes cluttered and difficult to navigate. Views allow me to create custom tabs that show only a specific subset of jobs.
    -   **List View**: This is the most common type of view. It lets me either manually check which jobs I want to include or use a regular expression to match job names automatically. This is essential for organizing jobs by team, project, or purpose (like "cron jobs").
-   **Build Triggers**: This is the mechanism that tells Jenkins *when* to run a job. While jobs can be started manually, the real power of CI/CD comes from automated triggers. The **"Build periodically"** trigger is Jenkins's built-in scheduler.
-   **Cron Syntax**: This is a time-based scheduling syntax inherited from the classic Linux `cron` utility. The five asterisks `* * * * *` represent a schedule for **M**inute, **H**our, **D**ay of **M**onth, **M**onth, and **D**ay of **W**eek. Using all asterisks means "every," so `* * * * *` translates to "run every minute."

---

### Deep Dive: The Importance of an Organized Jenkins Dashboard
<a name="deep-dive-the-importance-of-an-organized-jenkins-dashboard"></a>
This task perfectly highlighted why Views are not just a cosmetic feature but a critical organizational tool.

[Image of a Jenkins dashboard with custom views]

-   **Without Views:** Imagine a Jenkins server with 50 jobs for 5 different teams. The main dashboard would be a single, long, confusing list. A developer from Team A might accidentally trigger a job belonging to Team B. Finding a specific job becomes a chore.
-   **With Views:** I can create a separate List View for each team (`Team-A-Jobs`, `Team-B-Jobs`, etc.).
    -   **Clarity:** Developers can go directly to their team's tab and see only the jobs that are relevant to them.
    -   **Safety:** This reduces the chance of accidental clicks on the wrong job.
    -   **Organization by Purpose:** As in my task, I can create views based on a job's function. The `nautilus-crons` view gives me a single place to see all the jobs that are running on a schedule, which is very useful for an administrator.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Incorrect Cron Syntax:** A single wrong character in the cron schedule can cause the job to run at the wrong time or not at all. Jenkins provides a helpful "sanity check" below the schedule box to help prevent this.
-   **Forgetting to Select Jobs in the View:** After creating a List View, it's easy to forget to scroll down and actually check the boxes for the jobs you want to include, resulting in an empty view.
-   **Forgetting to Save:** Jenkins requires a "Save" or "Apply" click on each configuration page. It's easy to make a change and then navigate away, losing your work.
-   **Plugin Issues:** If the `View Job Filters and Column Filters` plugin wasn't installed, the options for filtering the List View might be more limited.

---

### Exploring the UI and Concepts Used
<a name="exploring-the-ui-and-concepts-used"></a>
This task was entirely UI-based. The key components I interacted with were:
-   **`Dashboard` > `New Item`**: The starting point for creating my Freestyle project.
-   **`[Job Name]` > `Configure`**: The main configuration page for a job, where I set up:
    -   **`Build Steps` > `Execute shell`**: The section where I defined the actual command to be run.
    -   **`Build Triggers` > `Build periodically`**: The section where I defined the cron schedule for the job.
-   **`Dashboard` > `+` (the plus icon)**: The button used to create a new View. I selected `List View` and gave it a name.
-   **`[View Name]` > `Edit View`**: The configuration page for the view, where I used the **`Job Filters`** checklist to select which jobs to display.
-   **`[Build Number]` > `Console Output`**: The page I used to check the logs of an automated build and verify its success.
  