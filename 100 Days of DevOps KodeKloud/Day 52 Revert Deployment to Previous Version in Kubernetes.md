# DevOps Day 52: Zero-Downtime Rollbacks in Kubernetes

Today's task was one of the most critical operations in any production environment: rolling back a failed deployment. The scenario was simple but urgent: a new release had introduced a bug, and I needed to revert the application to its previous, stable version as quickly and safely as possible.

This was a fantastic lesson that showcased the power and resilience of the Kubernetes `Deployment` object. I learned how Kubernetes keeps a history of changes and how I can use the `kubectl rollout undo` command to trigger a graceful, zero-downtime rollback. This document is my very detailed, first-person guide to that entire process, written from the perspective of a complete beginner to Kubernetes.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [Why Did I Do This? (The "What & Why" for a K8s Beginner)](#why-did-i-do-this-the-what--why-for-a-k8s-beginner)
- [Deep Dive: How a `rollout undo` Works Under the Hood](#deep-dive-how-a-rollout-undo-works-under-the-hood)
- [Common Pitfalls for Beginners](#common-pitfalls-for-beginners)
- [Exploring the Essential `kubectl` Commands](#exploring-the-essential-kubectl-commands)

---

### The Task
<a name="the-task"></a>
My objective was to revert a recent update to a Kubernetes Deployment. The specific requirements were:
1.  The target was an existing Deployment named `nginx-deployment`.
2.  I had to initiate a rollback to its previous revision.
3.  All Pods had to be operational after the rollback was complete.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The solution involved a crucial investigation phase, followed by the rollback command and verification.

#### Phase 1: The Investigation (Investigate Before You Act)
Before rolling back, I needed to understand the current state and the history of the deployment.
1.  I connected to the jump host.
2.  I used the `describe` command to see all the details of the running Deployment. This confirmed the current image version was the "bad" one.
    ```bash
    kubectl describe deployment nginx-deployment
    ```
3.  **This was the most important investigation step.** I used the `rollout history` command to see if there was a previous version to roll back to.
    ```bash
    kubectl rollout history deployment/nginx-deployment
    ```
    The output showed two revisions, confirming that I had a previous, stable state I could revert to.

#### Phase 2: The Rollback
With the history confirmed, I could safely perform the rollback.
1.  I used the `kubectl rollout undo` command to trigger the rollback process.
    ```bash
    kubectl rollout undo deployment/nginx-deployment
    ```
    The command responded with `deployment.apps/nginx-deployment rolled back`, which kicked off the automated rollback in the background.

2.  I immediately used the `rollout status` command to watch the process happen in real-time.
    ```bash
    kubectl rollout status deployment/nginx-deployment
    ```
    I saw messages as Kubernetes terminated the new, buggy Pods and brought up new Pods with the old, stable image version, until it finally reported: `deployment "nginx-deployment" successfully rolled out`.

#### Phase 3: Verification
The final step was to confirm that the application was now running the correct, older version.
1.  I described the deployment one last time:
    ```bash
    kubectl describe deployment nginx-deployment
    ```

2. I looked at the "Containers" section of the output. The Image field now correctly showed the previous, stable version (e.g., `nginx:1.16`). This was the definitive proof of a successful rollback.

---

### Why Did I Do This? (The "What & Why" for a K8s Beginner)
<a name="why-did-i-do-this-the-what--why-for-a-k8s-beginner)"></a>

- **The Problem**: When a new software release introduces a critical bug, the top priority is to restore service for users as quickly as possible. This is called a "rollback."

- **Deployment Revisions**: This is the key concept that makes rollbacks possible. Every time I change a Deployment's Pod template (for example, by using kubectl set image), Kubernetes doesn't just forget the old version. It saves the old configuration as a revision. The kubectl rollout history command lets me see this list of saved revisions.

- **kubectl rollout undo**: This is the magic command. It tells the Deployment controller: "Your current desired state is bad. Please change your desired state back to what it was in the previous revision."

- **A Rollback is just a Rolling Update in Reverse**: This was a huge "aha!" moment for me. When I trigger a rollback, the Deployment controller doesn't just kill all the bad Pods at once. It performs the exact same graceful, zero-downtime rolling update process it used for the initial deployment, but this time, the "new" Pods it creates are based on the old, stable revision. This ensures the application remains available throughout the entire rollback process.

### Deep Dive: How a rollout undo Works Under the Hood
<a name="deep-dive-how-a-rollout-undo-works-under-the-hood"></a> I learned that a Deployment manages Pods through an intermediary object called a ReplicaSet.

- **Initial State:** My nginx-deployment is at Revision 2. It is managing a ReplicaSet-v2 which, in turn, is managing 3 Pods running the bad nginx:1.17 image. The old ReplicaSet-v1 (with the good nginx:1.16 template) still exists but has its replica count set to 0.

- **kubectl rollout undo is Executed:** I run the command. The Deployment controller looks up its history and finds that the previous revision was ReplicaSet-v1.

The Rollback Begins: The Deployment controller now performs a rolling update in reverse:

It scales up the old, good ReplicaSet-v1 from 0 to 1. A new Pod with the nginx:1.16 image starts.

It waits for this new "old" Pod to become healthy and ready.

It then scales down the new, bad ReplicaSet-v2 from 3 to 2, terminating one of the buggy Pods.

- **Completion**: This process continues, following the maxSurge and maxUnavailable rules, until ReplicaSet-v1 is managing 3 healthy Pods and ReplicaSet-v2 has been scaled down to 0. The application is now fully reverted to the previous version with zero downtime.

### Common Pitfalls for Beginners
<a name="common-pitfalls-for-beginners"></a>

- **Forgetting to Check History:** If I run rollout undo on a brand new Deployment that has never been updated, it will fail because there is no previous revision to roll back to.

- **Panic and Manual Deletion:** A common mistake in a crisis is to panic and start manually deleting the "bad" Pods (kubectl delete pod ...). This is a bad idea! The Deployment controller will see that its desired replica count is not met and will immediately create a new, identical "bad" Pod to replace the one I just deleted. You must always manage the application by interacting with the Deployment, not the Pods it controls.

Not Monitoring the Rollout: Just running kubectl rollout undo is not enough. If there's a problem with the old revision (e.g., the old image was deleted from the registry), the rollback will get stuck. Using kubectl rollout status is essential to confirm that the rollback actually completed successfully.

### Exploring the Essential kubectl Commands
<a name="exploring-the-essential-kubectl-commands"></a> This task was a masterclass in the rollout subcommand.

- **`kubectl describe deployment [dep-name]`**: My primary investigation tool. It provides a very detailed description of a Deployment, including the current image version.

- **`kubectl rollout history deployment/[dep-name]`**: The command to view the history of revisions for a Deployment. This is essential for understanding what you can roll back to.

You can `add --revision=<number>` to see the full details of a specific revision.

- **`kubectl rollout undo deployment/[dep-name]`**: The main command for this task. It triggers a rollback to the immediately preceding revision.

- **`kubectl rollout undo deployment/[dep-name] --to-revision=<number>:`** A more advanced version of the undo command that allows you to roll back to a specific older revision (e.g., `--to-revision=1`), not just the last one.

- **`kubectl rollout status deployment/[dep-name]`**: A crucial command to monitor the real-time progress of a rolling update or a rollback. It will tell you if the process is ongoing, has completed successfully, or is stuck.