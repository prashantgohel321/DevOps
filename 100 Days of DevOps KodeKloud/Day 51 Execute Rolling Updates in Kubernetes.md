# DevOps Day 51: Zero-Downtime Updates with Kubernetes Deployments

Today's task was a deep dive into one of the most powerful and critical features of Kubernetes: performing a **rolling update** to an application with **zero downtime**. My objective was to update a running Nginx application, managed by a Deployment, from an older version to a newer one.

This was an incredible, real-world exercise that demonstrated the self-healing and orchestration power of the Kubernetes Deployment controller. I also had a fantastic troubleshooting moment where my initial command failed because I used the wrong container name, teaching me the importance of first investigating the state of a resource with `kubectl describe`. This document is my very detailed, first-person guide to that entire successful process.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [My Troubleshooting Journey: Finding the Correct Container Name](#my-troubleshooting-journey-finding-the-correct-container-name)
- [Why Did I Do This? (The "What & Why" for a K8s Beginner)](#why-did-i-do-this-the-what--why-for-a-k8s-beginner)
- [Deep Dive: How a Rolling Update Works](#deep-dive-how-a-rolling-update-works)
- [Common Pitfalls for Beginners](#common-pitfalls-for-beginners)
- [Exploring the Essential `kubectl` Commands](#exploring-the-essential-kubectl-commands)

---

### The Task
<a name="the-task"></a>
My objective was to perform a rolling update on an existing Kubernetes Deployment. The specific requirements were:
1.  The target was a Deployment named `nginx-deployment`.
2.  I had to update the application to use the new image `nginx:1.17`.
3.  All Pods had to be operational after the update.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The solution involved a crucial investigation phase, followed by the update command and verification.

#### Phase 1: The Investigation (The Most Important Step)
Before I could update the image, I needed to know the exact name of the container inside the Deployment's Pod template.
1.  I connected to the jump host.
2.  I used the `describe` command to get all the details of the running Deployment.
    ```bash
    kubectl describe deployment nginx-deployment
    ```
3.  I carefully examined the "Containers" section of the output:
    ```
    Containers:
     nginx-container:
      Image:        nginx:1.16
    ```
    This was the "aha!" moment. It told me the container's name was `nginx-container`, not a generic name like `httpd-container`, and that it was currently running version `1.16`.

#### Phase 2: The Rolling Update
With the correct container name, I could now perform the update.
1.  I used the `kubectl set image` command to tell the Deployment to use the new image.
    ```bash
    kubectl set image deployment/nginx-deployment nginx-container=nginx:1.17
    ```
    The command responded with `deployment.apps/nginx-deployment image updated`, which kicked off the automated update process.

2.  I immediately used the `rollout status` command to watch the update happen in real-time.
    ```bash
    kubectl rollout status deployment/nginx-deployment
    ```
    I saw messages as Kubernetes terminated old Pods and brought up new ones, until it finally reported: `deployment "nginx-deployment" successfully rolled out`.

#### Phase 3: Verification
The final step was to confirm that the application was now running the new version.
1.  I described the deployment one last time:
    ```bash
    kubectl describe deployment nginx-deployment
    ```
2.  I looked at the "Containers" section again. The `Image` field now correctly showed `nginx:1.17`. This was the definitive proof of success.

---

### My Troubleshooting Journey: Finding the Correct Container Name
<a name="my-troubleshooting-journey-finding-the-correct-container-name"></a>
This task was a perfect lesson in the importance of investigating before acting.
* **Failure:** My first attempt at the update command failed:
    ```bash
    kubectl set image deployment/nginx-deployment httpd-container=nginx:1.17
    # Output: error: unable to find container named "httpd-container"
    ```
* **Diagnosis:** The error message was crystal clear. I was trying to update a container that didn't exist *within that Deployment's template*.
* **The "Aha!" Moment:** This forced me to take a step back and use `kubectl describe`. This command is the master tool for understanding the exact specification of any Kubernetes resource. It showed me the true container name was `nginx-container`.
* **The Lesson:** I learned that the `kubectl set image` command is very precise. The container name is not a guess; it's a specific key from the Deployment's Pod template, and `describe` is the way to find it.

---

### Why Did I Do This? (The "What & Why" for a K8s Beginner)
<a name="why-did-i-do-this-the-what--why-for-a-k8s-beginner)"></a>
-   **Deployment Controller:** This is the Kubernetes object that manages my application. Its most important job is to ensure that the "current state" of the cluster matches the "desired state" I've defined. When I changed the desired image version, the Deployment controller automatically started the process to make it happen.
-   **Rolling Update:** This is the default strategy that Deployments use to update Pods. It is the key to achieving **zero downtime**. Instead of stopping all the old Pods at once (which would cause an outage) and then starting the new ones, it does it gracefully and incrementally:
    1.  It creates a new Pod with the new image.
    2.  It waits for the new Pod to become healthy and "ready."
    3.  **Only then** does it terminate one of the old Pods.
    4.  It repeats this process until all Pods are running the new version.
-   **`kubectl set image`**: This is a powerful *imperative* command. It's a shortcut that directly tells the Kubernetes API, "Find the Deployment named `nginx-deployment` and update the image for its `nginx-container` to `nginx:1.17`." This is often quicker than editing the YAML file and running `kubectl apply` for a simple image change.

---

### Deep Dive: How a Rolling Update Works
<a name="deep-dive-how-a-rolling-update-works"></a>
When I used `kubectl describe`, I saw a section called `RollingUpdateStrategy: 25% max unavailable, 25% max surge`. This is the rulebook for the update.

[Image of a Kubernetes rolling update in progress]

-   **`maxUnavailable: 25%`**: This tells Kubernetes that during the update, it must ensure that at least 75% of the desired number of Pods are always available to serve traffic. For my 3 replicas, this meant at least `3 * 0.75 = 2.25`, rounded up to 3, must be available. This setting prioritizes availability.
-   **`maxSurge: 25%`**: This tells Kubernetes that it's allowed to temporarily create *more* Pods than the desired replica count. For my 3 replicas, this meant it could add `3 * 0.25 = 0.75`, rounded up to 1, extra Pod. So, for a short time, I could have up to 4 Pods running. This setting prioritizes speed, as it allows the new Pod to start before the old one is terminated.

Kubernetes uses these two rules together to perform the update as quickly as possible while always guaranteeing a minimum level of availability.

---

### Common Pitfalls for Beginners
<a name="common-pitfalls-for-beginners"></a>
-   **Using the Wrong Container Name:** As I discovered, this is a very common mistake. The name must be the one defined in the Deployment's Pod template.
-   **Specifying a Non-Existent Image Tag:** If I had tried to update to `nginx:1.17.nonexistent`, the new Pods would fail to start with an `ImagePullBackOff` error, and the rolling update would get stuck, but the old, working application would remain available.
-   **Not Monitoring the Rollout:** Just running `kubectl set image` is not enough. If there's a problem with the new image, the rollout will get stuck. Using `kubectl rollout status` is essential to confirm that the update actually completed successfully.

---

### Exploring the Essential `kubectl` Commands
<a name="exploring-the-essential-kubectl-commands"></a>
This task reinforced the importance of the core `kubectl` commands and introduced some new ones.

-   **`kubectl get deployment [dep-name]`**: Gets a quick summary of a Deployment's status.
-   **`kubectl describe deployment [dep-name]`**: My hero command for this task. It provides a very detailed description of a Deployment, including its labels, replica count, update strategy, and, most importantly, the full template for the Pods it manages (including container names and images).
-   **`kubectl set image deployment/[dep-name] [container-name]=[new-image]`**: The imperative command to trigger a rolling update by changing the image for a specific container within a Deployment.
-   **`kubectl rollout status deployment/[dep-name]`**: A crucial command to monitor the real-time progress of a rolling update. It will tell you if the update is in progress, has completed successfully, or has failed.
-   **`kubectl rollout history deployment/[dep-name]`**: Shows a history of the revisions for a Deployment.
-   **`kubectl rollout undo deployment/[dep-name]`**: An incredibly powerful command. If I discovered the new `nginx:1.17` image was buggy, I could run this single command to trigger a "rollback," which would perform another rolling update back to the previous, stable version.
  