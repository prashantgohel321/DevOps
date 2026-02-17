# DevOps Day 76: Configuring Job-Level Security

Today's task was an advanced lesson in Jenkins security administration. Unlike previous tasks where I set global permissions, this time I had to configure Access Control Lists (ACLs) at the **Job Level**.

The goal was to grant two developers, `sam` and `rohan`, specific access to a single project named `Packages`, without giving them full administrative control over the entire Jenkins server. I utilized the **Project-based Matrix Authorization Strategy** to achieve this granular control. This document is my detailed guide to that process.

## Table of Contents
- [DevOps Day 76: Configuring Job-Level Security](#devops-day-76-configuring-job-level-security)
  - [Table of Contents](#table-of-contents)
    - [The Task](#the-task)
    - [My Step-by-Step Solution](#my-step-by-step-solution)
      - [Phase 1: Global Security Configuration](#phase-1-global-security-configuration)
      - [Phase 2: Job-Level Configuration](#phase-2-job-level-configuration)
    - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
    - [Deep Dive: Inheritance Strategy](#deep-dive-inheritance-strategy)
    - [Common Pitfalls](#common-pitfalls)
    - [Exploring the UI Used](#exploring-the-ui-used)

---

### The Task
<a name="the-task"></a>
My objective was to configure permissions for the `Packages` job. The requirements were:
1.  Ensure the users `sam` and `rohan` exist (or creating them if not).
2.  Configure the `Packages` job to use "Project-based security".
3.  Set the **Inheritance Strategy** to "Inherit permissions from parent ACL".
4.  Assign specific permissions:
    -   **sam:** Build, Configure, Read.
    -   **rohan:** Build, Cancel, Configure, Read, Update, Tag.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The process involved ensuring the global security strategy allowed for project-based configuration, and then editing the specific job.

#### Phase 1: Global Security Configuration
Before I could configure the job, I had to make sure Jenkins was using the correct authorization strategy globally.
1.  I logged into Jenkins as `admin` (`Adm!n321`).
2.  I navigated to **Manage Jenkins** > **Security**.
3.  Under the **Authorization** section, I selected **"Project-based Matrix Authorization Strategy"**.
    * *Critical Step:* I added `admin` to the matrix and granted `Overall/Administer` permission. Without this, I would have locked myself out.
    * *Optional:* I also added `sam` and `rohan` here and gave them `Overall/Read` permission so they can at least log in and see the dashboard.
4.  I clicked **Save**.

#### Phase 2: Job-Level Configuration
Now I could configure the specific `Packages` job.
1.  From the Dashboard, I clicked on the **`Packages`** job.
2.  I clicked **Configure** in the left menu.
3.  I scrolled down to the **General** section and checked the box **"Enable project-based security"**.
4.  This opened the Matrix Authorization panel specific to this job.
5.  **Inheritance Strategy:** I verified that the dropdown was set to **"Inherit permissions from parent ACL"** (this is usually the default, but required by the task).
6.  **Adding User `sam`:**
    -   I clicked "Add user or group...", typed `sam`, and clicked OK.
    -   In the matrix row for `sam`, I checked the following boxes:
        -   **Job/Build**
        -   **Job/Configure**
        -   **Job/Read**
7.  **Adding User `rohan`:**
    -   I clicked "Add user or group...", typed `rohan`, and clicked OK.
    -   In the matrix row for `rohan`, I checked the following boxes:
        -   **Job/Build**
        -   **Job/Cancel**
        -   **Job/Configure**
        -   **Job/Read**
        -   **SCM/Tag** (If available, otherwise looked for Tag under Job)
        -   *Note: "Update" is often synonymous with Configure in older versions, or specific to Workspace. I ensured all explicitly named permissions were checked.*
8.  I clicked **Save**.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
-   **Project-Based Matrix Authorization:** This is the standard way to handle security in a shared Jenkins environment. In a large company, you have many teams (Frontend, Backend, Mobile). You don't want the Mobile team accidentally canceling the Backend team's builds.
-   **Granularity:** Global security is a sledgehammer (you are either an admin or you aren't). Project-based security is a scalpel. It allows me to say, "Sam can *configure* this specific job, but he can't even *see* the other jobs."
-   **Separation of Duties:** By giving `sam` only "Build" and "Read" but giving `rohan` "Cancel" and "Tag", I am implementing specific roles. Perhaps Rohan is a senior developer or a release manager who is trusted to cancel bad builds and tag releases, while Sam is a junior developer who just needs to run builds and edit the script.

---

### Deep Dive: Inheritance Strategy
<a name="deep-dive-inheritance-strategy"></a>
The "Inheritance Strategy" setting is crucial and often misunderstood.

[Image of Jenkins Inheritance Strategy dropdown]

* **Inherit permissions from parent ACL:** This means the permissions set at the **Global Security** level cascade down to this job. If I gave `sam` "Read" access globally, he automatically has "Read" access to this job, plus whatever extra permissions I add here. This is the additive approach and is usually the safest.
* **Do not inherit permissions:** This blocks all global permissions (except for Super Admins). Even if `sam` has global read access, if I select this option, he cannot see this job unless I explicitly add him again in this job's matrix. This is useful for highly sensitive projects (e.g., "HR Payroll System") that should be hidden from the general development team.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Forgetting Global Read:** If you give a user permissions on a Job but don't give them `Overall/Read` permission in the Global Security settings, they won't be able to log in to see the job you gave them access to.
-   **"Update" Permission Confusion:** Jenkins permissions can be granular. Sometimes a requirement asks for "Update," but the UI only shows "Configure." "Configure" generally covers updating the job definition.
-   **Lockout:** As always with Matrix Authorization, the biggest risk is saving the configuration without giving the `admin` user full control. Always check `admin` -> `Administer` first.

---

### Exploring the UI Used
<a name="exploring-the-ui-used"></a>
-   **`Manage Jenkins` > `Security`**: Where the authorization strategy is switched from "Logged-in users can do anything" to "Project-based Matrix Authorization Strategy".
-   **`[Job Name]` > `Configure` > `Enable project-based security`**: The specific toggle that reveals the permission matrix for an individual job.
-   **Permission Categories**:
    -   **Job**: Contains Read, Build, Configure, Cancel, Workspace, Delete.
    -   **Run**: Contains Delete, Update, Replay.
    -   **SCM**: Contains Tag.
  