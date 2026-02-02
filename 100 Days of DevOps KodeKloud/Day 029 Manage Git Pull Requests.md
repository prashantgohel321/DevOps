# DevOps Day 29: Mastering the Pull Request Workflow

Today's task was the most important lesson in collaborative software development I've had so far. I moved from being a solo developer on the command line to participating in a professional, team-based workflow centered around the **Pull Request (PR)**. This task simulated the entire lifecycle: a developer proposing a change, a reviewer being formally requested, and that reviewer approving and merging the code.

This was a challenging task because it highlighted subtle but critical distinctions in the Gitea UI that I initially missed, leading to failures. After a few attempts, I finally understood the precise workflow the validation script was looking for. This document is my detailed, first-person guide to that successful process, with a special deep dive into the concept of the Pull Request itself.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution (The One That Worked)](#my-step-by-step-solution-the-one-that-worked)
- [Post-Mortem: Why My Previous Attempts Failed](#post-mortem-why-my-previous-attempts-failed)
- [Why Did I Do This? (The "What & Why" of Pull Requests)](#why-did-i-do-this-the-what--why-of-pull-requests)
- [Deep Dive: The Anatomy of a Professional Code Review](#deep-dive-the-anatomy-of-a-professional-code-review)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the UI Used](#exploring-the-ui-used)

---

### The Task
<a name="the-task"></a>
My objective was to simulate a full code review and merge process using the Gitea web UI, playing the role of two different users. The requirements were:
1.  As user `max`, create a **Pull Request** to merge the `story/fox-and-grapes` branch into the `master` branch.
2.  The PR title had to be `Added fox-and-grapes story`.
3.  Crucially, I had to formally request a review by adding user `tom` as a **Reviewer**.
4.  As user `tom`, I had to **review**, **approve**, and then **merge** the Pull Request.

---

### My Step-by-Step Solution (The One That Worked)
<a name="my-step-by-step-solution"></a>
The successful workflow required me to perform specific actions as two different users in the Gitea UI.

#### Phase 1: Max Creates the Pull Request
1.  I logged into Gitea as `max` (`Max_pass123`).
2.  I navigated to the `story-blog` repository and initiated a `New Pull Request`.
3.  I set the branches correctly: `base: master` <-- `compare: story/fox-and-grapes`.
4.  On the next screen, I set the title to `Added fox-and-grapes story`.
5.  **This was the first critical step:** In the sidebar on the right, I located the section explicitly labeled **"Reviewers."** I clicked the gear icon and selected `tom`.
6.  I then clicked the final "Create Pull Request" button. Max's job was now done.

#### Phase 2: Tom Reviews, Approves, and Merges
1.  I signed out of Gitea and logged back in as `tom` (`Tom_pass123`).
2.  I found the new PR on my dashboard and clicked on it.
3.  **This was the second critical step:** Instead of just merging, I first had to perform a formal review. I navigated to the **"Files Changed"** tab to see the code. Then, at the top of this view, I clicked the green **"Review"** button.
4.  This opened a dialog box with three options. I selected the **"Approve"** radio button and clicked **"Submit review"**.
5.  The "Conversation" tab now showed a log entry confirming "tom approved these changes."
6.  **Only after the approval was submitted**, I clicked the green **"Merge Pull Request"** button and confirmed the merge. The PR status changed to a purple "Merged" box, successfully completing the task.

---

### Post-Mortem: Why My Previous Attempts Failed
<a name="post-mortem-why-my-previous-attempts-failed"></a>
My failures on this task were a fantastic lesson in reading both the prompt and the UI carefully.
* **Failure 1: "Assignee" vs. "Reviewer"**
    -   **Symptom:** The task failed with `- PR is not requested for review`.
    -   **Diagnosis:** My screenshots showed that I had put `tom` in the **"Assignees"** field instead of the **"Reviewers"** field. An assignee is the person responsible for the work, while a reviewer is the person who checks it. The validation script was specifically checking the Reviewers list.
* **Failure 2: Merging Without Approving**
    -   **Symptom:** Another potential failure is merging the PR as `tom` without first going through the formal "Review" -> "Approve" steps.
    -   **Diagnosis:** The validation script isn't just checking if the code got into `master`. It's checking if the **process** was followed. The "Approval" is a distinct event that it looks for in the PR's history. Simply merging the PR doesn't create this event.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **Pull Request (PR)**: A Pull Request is a formal proposal to merge code from one branch into another. It's the heart of collaborative development on platforms like Gitea, GitHub, and GitLab. It's a request to the project maintainers to "please pull my changes into the main codebase."
-   **Protected Branches**: The reason we need PRs is that the `master` branch is almost always "protected." This is a feature of the Git server that physically prevents anyone (except maybe a senior administrator) from pushing code directly to it. This forces all changes to go through the code review process, ensuring quality and stability.
-   **Code Review**: This is the primary purpose of a PR. It creates a forum for discussion around a set of changes. A reviewer (`tom`) can look at the code, ask questions, suggest improvements, and ultimately give their stamp of approval. This process catches bugs early, improves code quality, and helps share knowledge across the team.

---

### Deep Dive: The Anatomy of a Professional Code Review
<a name="deep-dive-the-anatomy-of-a-professional-code-review"></a>
This task perfectly simulated the professional code review lifecycle.


1.  **The Proposal (`max`):** A developer finishes their work on a feature branch. They create a PR, which acts as a notification to the team. The PR includes a clear title, a description of the changes, and a list of the commits and files changed. By assigning a reviewer, the developer is formally requesting a quality check.

2.  **The Inspection (`tom`):** The reviewer is notified. Their job is to go to the **"Files Changed"** tab. This "diff" view is the most important part of the review. They check for:
    -   **Correctness:** Does the code do what it's supposed to do?
    -   **Bugs:** Are there any obvious logical errors or edge cases that were missed?
    -   **Style:** Does the code adhere to the team's coding standards?
    -   **Clarity:** Is the code easy to read and understand?

3.  **The Verdict (`tom`):** After the inspection, the reviewer makes a formal decision.
    -   **Comment:** The reviewer can leave comments on specific lines of code to ask questions or suggest small changes.
    -   **Request Changes:** If there are significant issues, the reviewer can formally block the merge and request changes. `max` would then have to make new commits on his branch to address the feedback.
    -   **Approve:** If the code is good, the reviewer gives their formal approval. This signals to the team that the code has been vetted and is ready to be merged.

4.  **The Integration (`tom`):** Once the PR is approved, it can be merged. This takes the commits from the feature branch and integrates them into the `master` branch, making the new feature a permanent part of the project.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Confusing Assignee and Reviewer:** As I discovered, these are two distinct roles in the UI, and the validation script was specifically looking for a "Reviewer."
-   **Merging Without Formal Approval:** A reviewer clicking "Merge" without first clicking "Approve" bypasses the review process and would cause this lab's validation to fail.
-   **Merging the Wrong Branches:** It's critical on the "New Pull Request" page to ensure the base (destination) is `master` and the compare (source) is the feature branch. Reversing these would try to merge `master` into the feature branch, which is the opposite of what's intended.

---

### Exploring the UI Used
<a name="exploring-the-ui-used"></a>
This task was entirely UI-based. The key components I interacted with were:
-   **`New Pull Request` Button**: The starting point of the workflow.
-   **Branch Selection Dropdowns**: The critical UI element for defining the source and destination of the merge.
-   **`Reviewers` Sidebar Section**: The specific area where I had to assign `tom` to request a formal review.
-   **`Files Changed` Tab**: The "diff" view where the code review actually happens.
-   **`Review` Button**: The button inside the "Files Changed" tab that opens the dialog for a formal approval.
-   **`Merge Pull Request` Button**: The final button to integrate the approved changes.
  