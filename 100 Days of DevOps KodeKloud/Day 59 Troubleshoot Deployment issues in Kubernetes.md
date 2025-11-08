# DevOps Day 59: Troubleshooting a Failing Kubernetes Deployment

Today's task was a masterclass in Kubernetes troubleshooting. I was presented with a failing application where the Pods were stuck in a `ContainerCreating` state and would not start. My objective was to play detective, using Kubernetes's own diagnostic tools to find and fix the underlying configuration errors.

This was an incredible learning experience because the problem wasn't a single error, but **two separate, subtle typos** in the Deployment's definition. I had to go beyond checking logs and dive deep into the Pod's event history to find the root causes. This document is my very detailed, first-person guide to that entire successful detective story.

## Table of Contents
- [DevOps Day 59: Troubleshooting a Failing Kubernetes Deployment](#devops-day-59-troubleshooting-a-failing-kubernetes-deployment)
  - [Table of Contents](#table-of-contents)
    - [The Task](#the-task)
    - [My Step-by-Step Solution](#my-step-by-step-solution)
      - [Phase 1: The Diagnosis](#phase-1-the-diagnosis)
      - [Phase 2: The Fix](#phase-2-the-fix)
      - [Phase 3: Verification](#phase-3-verification)
    - [Why Did I Do This? (The "What \& Why" for a K8s Beginner)](#why-did-i-do-this-the-what--why-for-a-k8s-beginner)
    - [Deep Dive: The Power of `kubectl describe` and the Events Section](#deep-dive-the-power-of-kubectl-describe-and-the-events-section)
    - [Common Pitfalls for Beginners](#common-pitfalls-for-beginners)
    - [Exploring the Essential `kubectl` Commands](#exploring-the-essential-kubectl-commands)

---

### The Task
<a name="the-task"></a>
My objective was to fix a broken Redis deployment on the Kubernetes cluster. The key details were:
1.  The Deployment was named `redis-deployment`.
2.  The Pods were not reaching a `Running` state.
3.  I needed to find the errors and fix them to get the application running.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
My approach was to follow the classic Kubernetes troubleshooting workflow: start high-level to identify the symptom, and then drill down into the details to find the root cause.

#### Phase 1: The Diagnosis
1.  I connected to the jump host. My first command gave me a high-level view of the problem.
    ```bash
    kubectl get deployment redis-deployment
    # Output showed READY 0/1, meaning the desired Pod was not healthy.
    ```
2.  I then checked the Pods to see their specific status.
    ```bash
    kubectl get pods
    # Output showed the Pod was stuck in a 'ContainerCreating' or 'Pending' state.
    ```
    This told me the problem was happening *before* the container could even start. `kubectl logs` was useless at this point because there was no running container to get logs from.

3.  **This was the most critical step.** I used `kubectl describe` on the stuck Pod to get the detailed event history.
    ```bash
    kubectl describe pod redis-deployment-54cdf4f76d-cxdzf
    ```
4.  The `Events` section at the very bottom of the output contained the "smoking gun" for the first problem:
    `Warning FailedMount ... MountVolume.SetUp failed for volume "config" : configmap "redis-conig" not found`
    This was my **first root cause**: a typo in the ConfigMap name (`redis-conig` instead of `redis-config`).

5.  While I was looking at the same `describe` output, I also spotted a second, more subtle bug in the "Containers" section:
    `Image: redis:alpin`
    This was my **second root cause**: a typo in the image tag (`alpin` instead of `alpine`). This would have caused an `ImagePullBackOff` error after I fixed the first problem.

#### Phase 2: The Fix
With both problems identified, I decided the most efficient way to fix them was to edit the live Deployment object directly and correct both typos at once.

1.  I used `kubectl edit` to open the Deployment's live YAML definition in a text editor.
    ```bash
    kubectl edit deployment redis-deployment
    ```
2.  Inside the editor, I found and corrected both typos:
    -   Under `spec.template.spec.containers`, I changed `image: redis:alpin` to `image: redis:alpine`.
    -   Under `spec.template.spec.volumes`, in the `configMap` definition, I changed `name: redis-conig` to `name: redis-config`.
3.  I saved and quit the editor.

#### Phase 3: Verification
1.  When I saved the edited file, Kubernetes automatically detected the change to the Pod template and triggered a new rollout.
2.  I immediately checked the Pods again:
    ```bash
    kubectl get pods
    ```
3.  The output showed the old, broken Pod in a `Terminating` state and a brand new Pod in a `Running` state with `READY: 1/1`. This was the definitive proof that both issues were resolved and the application was now running correctly.

---

### Why Did I Do This? (The "What & Why" for a K8s Beginner)
<a name="why-did-i-do-this-the-what--why-for-a-k8s-beginner)"></a>
-   **Kubernetes Troubleshooting**: This task was a masterclass in the standard K8s debugging workflow:
    1.  Start high-level with `kubectl get` to see the overall status (the "symptom").
    2.  If something is wrong (a Pod is not `Running`), drill down with `kubectl describe` to get the detailed specification and, most importantly, the **events** (the "cause").
    3.  If the container is running but the app is failing, *then* use `kubectl logs`.
-   **Pod Events**: I learned that the `Events` section of the `describe` output is the most valuable source of information when a Pod fails to *start*. It shows the step-by-step actions that the `kubelet` (the agent on the server) took and any errors it encountered, like failing to mount a volume or pull an image.
-   **ConfigMap Volumes**: A `ConfigMap` is a Kubernetes object for storing configuration data. One of its most powerful features is the ability to be mounted as a **volume** inside a Pod. This allows me to inject configuration files (like a `redis.conf` file) into my container at runtime, decoupling the configuration from the container image. The error I found was that the Pod was trying to mount a ConfigMap that didn't exist due to a typo.
-   **ImagePullBackOff**: This is the error I *would have* seen if I had only fixed the ConfigMap issue. It's a common status that means Kubernetes tried to pull the specified Docker image (`redis:alpin`) but the image could not be found in the registry. Kubernetes will keep trying, with an increasing "back-off" delay between attempts.

---

### Deep Dive: The Power of `kubectl describe` and the Events Section
<a name="deep-dive-the-power-of-kubectl-describe-and-the-events-section"></a>
For any problem where a Pod is `Pending`, `ContainerCreating`, or `ImagePullBackOff`, `kubectl describe pod` is your best friend. The logs are useless because the container isn't running yet. The real story is in the `Events` section.

[Image of a kubectl describe pod output with events]

-   **What are Events?** Events are objects in Kubernetes that provide insight into what is happening inside the cluster. They are records of actions and errors related to other resources.
-   **How to Read Them:** The `Events` table at the bottom of the `describe` output is a chronological log of what the system has been doing with your Pod. I looked for events with `Type: Warning`.
-   **My "Smoking Gun" Event:**
    `Warning FailedMount ... MountVolume.SetUp failed for volume "config" : configmap "redis-conig" not found`
    -   **`Warning`**: This immediately told me something was wrong.
    -   **`FailedMount`**: This told me the problem was with a storage volume.
    -   **`configmap "redis-conig" not found`**: This was the exact, specific root cause.

I learned that 90% of Pod startup problems can be diagnosed by carefully reading this `Events` section.

---

### Common Pitfalls for Beginners
<a name="common-pitfalls-for-beginners"></a>
-   **Only Checking `get pods`:** A beginner might see `ContainerCreating` and just wait, thinking the system is slow. `ContainerCreating` for more than a minute is almost always a sign of a deeper problem that requires `describe`.
-   **Trying to Check Logs Too Early:** As I saw, running `kubectl logs` on a Pod that isn't `Running` will result in an error, which can be confusing.
-   **Fixing Only One Bug:** If I had only fixed the ConfigMap typo and not noticed the image tag typo, the Pod would have been recreated and then immediately failed with a new `ImagePullBackOff` error, leading to more confusion. A thorough `describe` helps you find all the problems at once.
-   **Editing the Pod Directly:** A common mistake is to try `kubectl edit pod ...`. This is almost always wrong. Since my Pod was managed by a Deployment, any changes I made to the Pod directly would be instantly reverted by the Deployment controller. The fix **must** be applied to the parent object (the `Deployment`).

---

### Exploring the Essential `kubectl` Commands
<a name="exploring-the-essential-kubectl-commands"></a>
-   `kubectl get pods` / `kubectl get deployment`: My high-level tools to check the overall status.
-   `kubectl describe pod [pod-name]`: My most powerful diagnostic tool. It shows the Pod's full configuration, status, and, most importantly, its event history, which is where I found the root cause.
-   `kubectl edit deployment [dep-name]`: The command I used to apply the fix. It opens the live YAML definition of a resource in a text editor. When I saved and quit, Kubernetes automatically detected the changes to the Pod template and triggered a new, corrected rollout.
-   `kubectl set image deployment/[dep-name] [container-name]=[new-image]`: An alternative command I could have used to fix the image tag. However, `kubectl edit` was better here because it allowed me to fix both the image tag and the ConfigMap name in a single operation.
   