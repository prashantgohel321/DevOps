# DevOps Day 23: Collaborative Git Workflows with Forks

Today's task was a shift from the command line to the web UI, which is where a lot of modern Git collaboration takes place. I learned about the concept of "forking," a cornerstone of contributing to projects in a team or open-source setting.

This was a critical lesson in understanding the difference between a `clone` (a local copy for me to work on) and a `fork` (a new server-side copy that I own). It's the first step in the famous "Fork and Pull Request" workflow that powers most collaborative software development.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [The Fork and Pull Request Workflow](#the-fork-and-pull-request-workflow)
- [Exploring the UI Used](#exploring-the-ui-used)

---

### The Task
<a name="the-task"></a>
My objective was to perform a task as a new developer, `jon`, using the Gitea web interface. The requirements were:
1.  Log into the Gitea server as user `jon`.
2.  Find the existing Git repository named `sarah/story-blog`.
3.  **Fork** this repository so that a new copy would exist under my (`jon`'s) account.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
This entire task was performed using the web browser.

1.  **Access and Login:** I clicked the **Gitea UI** button in the lab environment. On the login page, I entered the credentials:
    -   Username: `jon`
    -   Password: `Jon_pass123`

2.  **Locate Repository:** After logging in, I used the search bar at the top of the dashboard to find the `sarah/story-blog` repository and clicked on it to navigate to its main page.

3.  **Fork:** In the top-right corner of the repository page, I located and clicked the **"Fork"** button.

4.  **Confirm Fork:** Gitea presented a "New Fork" screen where the owner was correctly set to `jon`. I simply had to click the final **"Fork Repository"** button.

5.  **Verification:** The confirmation was immediate. I was automatically redirected to my new repository's page. The title clearly showed **`jon/story-blog`**, and just below it was the text **"forked from sarah/story-blog"**. This was the definitive proof of success.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
-   **Gitea**: This is a self-hosted Git service, like a private version of GitHub or GitLab. It provides a web UI to manage users, repositories, and collaboration features like pull requests.
-   **Forking**: A fork is a **new copy of a repository that is created on the server**. This new copy belongs to me (`jon`), so I have full permission to push changes to it. The original repository (`sarah/story-blog`) remains untouched and protected.
-   **Forking vs. Cloning**: This is the most important concept from this task.
    -   A **clone** creates a *local copy* on my machine for me to work on.
    -   A **fork** creates a *new repository on the server* that I own.
    The standard workflow is to first **fork** the project on the server, and then **clone** *your fork* to your local machine.

---

### The Fork and Pull Request Workflow
<a name="the-fork-and-pull-request-workflow"></a>
Forking is the first step in the most common collaboration pattern in software development. It allows anyone to contribute to a project without giving them direct write access to the main codebase.

[Image of the fork and pull request workflow]

The full process is:
1.  **Fork:** Create my own server-side copy of the project (e.g., `jon/story-blog`).
2.  **Clone:** Clone **my fork** to my local machine (`git clone <URL_of_jon/story-blog>`).
3.  **Code:** Create a new branch, make my changes, and commit them.
4.  **Push:** Push my changes **to my fork** on the server.
5.  **Create a Pull Request (PR):** From the Gitea UI, I would open a "Pull Request" from my fork to the original repository. This is a formal request for the project maintainer to review and merge my work.

---

### Exploring the UI Used
<a name="exploring-the-ui-used"></a>
This was a UI-driven task, so no command-line tools were used. The key actions were all performed by clicking buttons within the Gitea web interface:
-   **Login Button**
-   **Search Bar**
-   **Fork Button**
-   **Fork Repository Button**
  