# DevOps Day 70: Granular User Permissions with Matrix Authorization

Today's Jenkins task was a deep dive into security and user management. I moved beyond the initial setup to configuring Jenkins for a team environment. The goal was to create a new user and give them very specific, limited permissions, which is a fundamental requirement for any real-world Jenkins server.

This was a fantastic exercise because it taught me the importance of the "Principle of Least Privilege." I learned how to install a new plugin to enable more powerful security options and then configure permissions at both the global (whole server) level and the project (specific job) level.

## Table of Contents
- [DevOps Day 70: Granular User Permissions with Matrix Authorization](#devops-day-70-granular-user-permissions-with-matrix-authorization)
  - [Table of Contents](#table-of-contents)
    - [The Task](#the-task)
    - [My Step-by-Step Solution](#my-step-by-step-solution)
      - [Phase 1: Installing the Security Plugin](#phase-1-installing-the-security-plugin)
      - [Phase 2: Creating the New User](#phase-2-creating-the-new-user)
      - [Phase 3: Configuring Security](#phase-3-configuring-security)
    - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
    - [Deep Dive: The Principle of Least Privilege in Jenkins](#deep-dive-the-principle-of-least-privilege-in-jenkins)
    - [Common Pitfalls](#common-pitfalls)
    - [Exploring the UI Used](#exploring-the-ui-used)

---

### The Task
<a name="the-task"></a>
My objective was to securely configure my Jenkins server for a new developer, `rose`. The specific requirements were:
1.  Install the **Matrix Authorization Strategy Plugin**.
2.  Create a new user named `rose` with a specific password and full name.
3.  Switch the server's security to use the **Project-based Matrix Authorization Strategy**.
4.  Configure **Global Permissions**:
    -   `rose` should only have `Overall/Read`.
    -   `admin` must retain full `Overall/Administer` permissions.
    -   `Anonymous Users` should have no permissions at all.
5.  Configure **Project Permissions** for the existing job:
    -   `rose` should only have `Job/Read` permission.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
This entire task was performed through the Jenkins web UI.

#### Phase 1: Installing the Security Plugin
First, I needed to install the plugin that would enable the required security configuration.
1.  I logged into Jenkins as `admin` and navigated to `Manage Jenkins` > `Plugins`.
2.  In the `Available plugins` tab, I searched for `Matrix Authorization Strategy`, selected the plugin, and clicked to install.
3.  On the installation screen, I checked the box to **"Restart Jenkins when installation is complete..."** and waited for the server to restart and bring me back to the login page.

#### Phase 2: Creating the New User
With the necessary plugin installed, I created the new developer's account.
1.  After logging back in as `admin`, I navigated to `Manage Jenkins` > `Users`.
2.  I clicked `Create User` and filled in the details exactly as required:
    -   Username: `rose`
    -   Password: `8FmzjvFU6S`
    -   Full name: `Rose`
3.  I clicked `Create User` to save the new account.

#### Phase 3: Configuring Security
This was the most critical part of the task, involving two levels of permissions.

1.  **Configure Global Security:** I went to `Manage Jenkins` > `Security`.
    -   Under **Authorization**, I selected the **"Project-based Matrix Authorization Strategy"** radio button.
    -   In the permissions grid that appeared, I added both `admin` and `rose`.
    -   For the `admin` user, I checked the master checkbox for `Overall/Administer` to ensure I didn't lock myself out.
    -   For the `rose` user, I checked **only** the box for `Overall/Read`.
    -   I double-checked that the `Anonymous Users` row had no permissions checked.
    -   I clicked **Save**.

2.  **Configure Project Security:** I went back to the main dashboard and clicked on the existing job.
    -   From the job's menu, I clicked `Configure`.
    -   I checked the box for **"Enable project-based security"**.
    -   In the new permissions grid for the job, I added the user `rose`.
    -   I checked the box for `Job/Read` for `rose` and nothing else.
    -   I clicked **Save**.

My final verification was to log out as `admin` and log in as `rose` to confirm that the permissions were working exactly as intended. I could see the job but couldn't configure or build it, which was the proof of success.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
-   **Authorization Strategy**: This is the core of Jenkins security. It's the set of rules that determines "who can do what." The default, "Logged-in users can do anything," is fine for a personal server but completely insecure for a team.
-   **Matrix Authorization Strategy Plugin**: The default Jenkins options are limited. This plugin provides a much more powerful and flexible way to manage permissions. It gives you a grid (a "matrix") where you can visually assign specific permissions to different users or groups.
-   **Project-based vs. Global Security**: This is a key concept.
    -   **Global Security (`Manage Jenkins` > `Security`):** This is the baseline security for the entire server. The `Overall/Read` permission I gave `rose` allows her to log in and see the dashboard, but that's it.
    -   **Project-based Security (Inside a Job's Configuration):** This allows me to get more specific. Even though `rose` only has read access globally, I can grant her extra permissions on a specific job. In this case, I gave her `Job/Read`, which allows her to see the details of that one job. This is how you can give different teams access to only their own projects.

---

### Deep Dive: The Principle of Least Privilege in Jenkins
<a name="deep-dive-the-principle-of-least-privilege-in-jenkins"></a>
This entire task was a practical exercise in implementing the **Principle of Least Privilege**. This security concept dictates that a user should only have the absolute minimum permissions required to perform their job, and nothing more.



-   **Why is this important?**
    -   **Reduces Accidents:** If a junior developer only has read access, they can't accidentally delete a critical production job.
    -   **Enhances Security:** If a user's account is compromised, the damage an attacker can do is limited by that user's permissions. If `rose`'s account was stolen, the attacker could only *look* at one job; they couldn't run malicious code, steal secrets (credentials), or damage the Jenkins server.
-   **How I Implemented It:**
    1.  **Removed Anonymous Access:** I started by ensuring that people who aren't logged in can't see anything. This is the first line of defense.
    2.  **Established a Low Baseline:** I gave the `rose` user the lowest possible useful permission globally: `Overall/Read`.
    3.  **Granted Specific Permissions:** I then went to the *specific resource* (the job) and granted the *specific permission* (`Job/Read`) that the user needed.

This approach is the opposite of the default "everyone can do everything" model and is the standard for any professionally managed Jenkins instance.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Locking Yourself Out:** The most dangerous mistake is to enable Matrix Authorization but forget to give the `admin` user the `Overall/Administer` permission. If you click save, you will be instantly locked out of all administrative functions, which can be difficult to recover from.
-   **Installing the Wrong Plugin:** There are several security plugins. It was important to install the exact `Matrix Authorization Strategy Plugin` to get the required features.
-   **Confusing Global vs. Project Permissions:** A user might be confused why they can't see a job's details. This is often because they have been granted `Overall/Read` but not the specific `Job/Read` permission on that project.
-   **Forgetting to Restart:** After installing the plugin, a restart is required. Forgetting to check the restart box would mean the "Project-based Matrix Authorization Strategy" option wouldn't be available in the security settings.

---

### Exploring the UI Used
<a name="exploring-the-ui-used"></a>
This task was entirely UI-based. The key navigation paths were:
-   **`Manage Jenkins` > `Plugins`**: My starting point for extending Jenkins' functionality. I used the `Available plugins` tab to find and install the new security plugin.
-   **`Manage Jenkins` > `Users`**: The area for creating, deleting, and managing user accounts.
-   **`Manage Jenkins` > `Security`**: The central location for configuring the global security settings, including the Authorization Strategy.
-   **`[Job Name]` > `Configure`**: The configuration page for a specific job. This is where I enabled and configured the project-based permissions.
   