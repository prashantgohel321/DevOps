# DevOps Day 64: Troubleshooting a Failing Kubernetes Deployment

Today's task was a masterclass in Kubernetes troubleshooting. I was presented with a failing Python application where the Pods were not becoming `Ready`. This required me to follow a systematic debugging process, using Kubernetes's own diagnostic tools to uncover not one, but **two separate misconfigurations**: an incorrect image name in the `Deployment` and a wrong `targetPort` in the `Service`.

This was an incredible learning experience because it showed me how to read the cluster's "vital signs" to pinpoint the root cause of a problem. I learned that `kubectl describe` is my most powerful tool for diagnosing startup issues. This document is my very detailed, first-person guide to that entire detective story, from the initial `ImagePullBackOff` error to the final, successful application launch.

## Table of Contents
- [DevOps Day 64: Troubleshooting a Failing Kubernetes Deployment](#devops-day-64-troubleshooting-a-failing-kubernetes-deployment)
  - [Table of Contents](#table-of-contents)
    - [The Task](#the-task)
    - [My Step-by-Step Solution](#my-step-by-step-solution)
      - [Phase 1: Diagnosing the Pod Failure](#phase-1-diagnosing-the-pod-failure)
      - [Phase 2: Fixing the Deployment and Diagnosing the Service](#phase-2-fixing-the-deployment-and-diagnosing-the-service)
      - [Phase 3: Fixing the Service and Verifying](#phase-3-fixing-the-service-and-verifying)
    - [Why Did I Do This? (The "What \& Why" for a K8s Beginner)](#why-did-i-do-this-the-what--why-for-a-k8s-beginner)
    - [Deep Dive: `port` vs. `targetPort` vs. `nodePort` in a Service](#deep-dive-port-vs-targetport-vs-nodeport-in-a-service)
    - [Common Pitfalls for Beginners](#common-pitfalls-for-beginners)
    - [Exploring the Essential `kubectl` Commands](#exploring-the-essential-kubectl-commands)

---

### The Task
<a name="the-task"></a>
My objective was to fix a broken Python application deployment on the Kubernetes cluster. The key details were:
1.  The Deployment was named `python-deployment-nautilus`.
2.  The application was not coming up, and the Pods were not in a `Ready` state.
3.  I needed to find and fix the issues to make the application accessible on the specified `nodePort` (`32345`).

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
My approach was to follow the classic Kubernetes troubleshooting workflow: start high-level and drill down into the details.

#### Phase 1: Diagnosing the Pod Failure
1.  I connected to the jump host. My first command gave me a high-level view of the problem.
    ```bash
    kubectl get deployment python-deployment-nautilus
    # Output showed READY 0/1, meaning the desired Pod was not healthy.
    ```
2.  I then checked the Pods to see their specific status.
    ```bash
    kubectl get pods
    # Output showed the Pod was stuck in 'ImagePullBackOff' state.
    ```
    This told me the problem was that the container image could not be downloaded.

3.  **This was the most critical step.** I used `kubectl describe` on the stuck Pod to get the detailed event history.
    ```bash
    kubectl describe pod <pod-name-from-get-pods>
    ```
4.  The `Events` section at the bottom of the output contained the "smoking gun":
    `Warning Failed ... Failed to pull image "poroko/flask-app-demo": ... repository does not exist`
    This was my **first root cause**: a typo in the image name. The prompt stated the image should be `poroko/flask-demo-app`, but the deployment was using `poroko/flask-app-demo`.

#### Phase 2: Fixing the Deployment and Diagnosing the Service
1.  I used `kubectl edit` to open the Deployment's live YAML definition.
    ```bash
    kubectl edit deployment python-deployment-nautilus
    ```
2.  Inside the editor, I found the `image:` line and corrected the typo from `poroko/flask-app-demo` to `poroko/flask-demo-app`.
3.  After saving the file, Kubernetes automatically created a new Pod. I checked with `kubectl get pods` and saw the new Pod was `1/1 Running`. Success!

4.  However, the application was still not accessible. This told me there was a second problem at the networking layer. I inspected the Service.
    ```bash
    kubectl describe service python-service-nautilus
    ```
5.  The output showed the port configuration: `Port: 8080/TCP`, `TargetPort: 8080/TCP`, `NodePort: 32345/TCP`. This was my **second root cause**. The `targetPort` was `8080`, but a standard Python Flask app listens on port `5000`. The Service was sending traffic to the wrong port on the Pod.

#### Phase 3: Fixing the Service and Verifying
1.  I edited the Service to correct the port.
    ```bash
    kubectl edit service python-service-nautilus
    ```
2.  Inside the editor, I found the `targetPort:` line and changed its value from `8080` to `5000`.
3.  I saved the file. The change was applied instantly.
4.  Finally, I tested the application from the jump host using the NodePort.
    ```bash
    curl http://<node-ip>:32345
    ```
    I received the success message from the Python application, confirming both issues were resolved.

---

### Why Did I Do This? (The "What & Why" for a K8s Beginner)
<a name="why-did-i-do-this-the-what--why-for-a-k8s-beginner)"></a>
-   **Kubernetes Troubleshooting Workflow**: This task was a masterclass in the standard K8s debugging workflow:
    1.  Start high-level with `kubectl get` to see the overall status (the "symptom").
    2.  If a Pod is not `Running` (e.g., `ImagePullBackOff`, `CrashLoopBackOff`, `Pending`), drill down with `kubectl describe pod` to read the **Events** (the "cause").
    3.  If a Pod is `Running` but the app is inaccessible, the problem is likely in the `Service`. Use `kubectl describe service` to check selectors and ports.
-   **`ImagePullBackOff`**: This is a very common Pod status. It means the `kubelet` on the Node tried to pull the specified Docker image from the registry but failed. Kubernetes will keep trying, with an increasing "back-off" delay. The most common causes are:
    1.  A typo in the image name or tag (my issue).
    2.  The image is in a private repository, and the cluster doesn't have the necessary credentials.
-   **`Service` and `targetPort`**: A Service acts as an internal load balancer that forwards traffic to Pods. The `targetPort` is the most critical setting. It specifies the **port on the Pod** where the application container is actually listening for connections. If this is wrong, the Service will send traffic to a closed door, and the connection will fail.

---

### Deep Dive: `port` vs. `targetPort` vs. `nodePort` in a Service
<a name="deep-dive-port-vs-targetport-vs-nodeport-in-a-service"></a>
My `describe service` output showed three different ports. Understanding the difference is key to Kubernetes networking.

[Image of a Kubernetes NodePort Service directing traffic]

-   **`targetPort`**: The port that my application container is **listening on**. For Flask, this is `5000`. The `targetPort` of the Service **must match this value**.
-   **`port`**: The port that the Service itself exposes **inside the cluster's virtual network**. Other Pods inside the cluster can connect to my application on this port using the service's internal DNS name (e.g., `http://python-service-nautilus:8080`).
-   **`nodePort`**: The high-numbered port (`32345` in my case) that is opened on the **physical Node's IP address** to expose the service to the outside world.

The flow of traffic is: `Outside World` -> `NodeIP:32345` -> `ServiceIP:8080` -> `PodIP:5000`.

My mistake was that the final step, `ServiceIP:8080` -> `PodIP:8080`, was failing because my app was listening on `PodIP:5000`.

---

### Common Pitfalls for Beginners
<a name="common-pitfalls-for-beginners"></a>
-   **Typo in Image Name:** As I discovered, a simple typo in the image name is a very common cause of `ImagePullBackOff`.
-   **Confusing `port` and `targetPort`:** This is the most common Service configuration error. Always remember that `targetPort` must match the port your application container is listening on.
-   **Editing the Pod Directly:** A beginner might try `kubectl edit pod ...` to fix the image name. This is wrong. Since my Pod was managed by a Deployment, any changes I made to the Pod directly would be instantly reverted. The fix **must** be applied to the parent `Deployment`.

---

### Exploring the Essential `kubectl` Commands
<a name="exploring-the-essential-kubectl-commands"></a>
-   `kubectl get pods` / `kubectl get deployment`: My high-level tools to check the overall status.
-   `kubectl describe pod [pod-name]`: My most powerful diagnostic tool for Pod startup failures. The `Events` section showed me the exact `ErrImagePull` reason.
-   `kubectl describe service [svc-name]`: My primary tool for diagnosing networking issues. It clearly showed me the incorrect `targetPort`.
-   `kubectl edit deployment [dep-name]` / `kubectl edit service [svc-name]`: The command to open a live YAML definition of a resource in a text editor. I used this to apply my fixes directly to the live objects in the cluster.
   