# DevOps Day 50: Managing Container Resources in Kubernetes

Today's task was a critical step in my Kubernetes journey. I moved from simply creating a Pod to creating a Pod with **resource management**. My objective was to define specific CPU and Memory "requests" and "limits" for my container. This is one of the most important concepts for running stable, predictable, and fair applications in a shared Kubernetes cluster.

This was a fantastic lesson in how Kubernetes prevents "noisy neighbor" problems, where one misbehaving application can crash an entire server. I learned how to declare these resource constraints in a YAML file and how to verify that the cluster was enforcing them. This document is my very detailed, first-person guide to that entire process, written for a complete beginner to Kubernetes.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [Why Did I Do This? (The "What & Why" for a K8s Beginner)](#why-did-i-do-this-the-what--why-for-a-k8s-beginner)
- [Deep Dive: A Line-by-Line Explanation of My Pod YAML File](#deep-dive-a-line-by-line-explanation-of-my-pod-yaml-file)
- [Common Pitfalls for Beginners](#common-pitfalls-for-beginners)
- [Exploring the Essential `kubectl` Commands](#exploring-the-essential-kubectl-commands)

---

### The Task
<a name="the-task"></a>
My objective was to create a single Kubernetes Pod with specific resource constraints. The requirements were:
1.  The Pod must be named `httpd-pod`.
2.  The container inside must be named `httpd-container` and use the `httpd:latest` image.
3.  The container required specific resource settings:
    -   **Requests:** `15Mi` of Memory and `100m` of CPU.
    -   **Limits:** `20Mi` of Memory and `100m` of CPU.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The professional way to create resources in Kubernetes is with a YAML manifest file. I followed this declarative approach.

#### Phase 1: Writing the Pod Manifest
1.  I connected to the jump host, where `kubectl` was pre-configured to talk to the cluster.
2.  I created a new file named `httpd-pod-resources.yaml` using `vi`.
3.  Inside the editor, I wrote the following YAML code. The key part was the new `resources` block inside the container specification.
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: httpd-pod
    spec:
      containers:
      - name: httpd-container
        image: httpd:latest
        resources:
          requests:
            memory: "15Mi"
            cpu: "100m"
          limits:
            memory: "20Mi"
            cpu: "100m"
    ```
4.  I saved and quit the file.

#### Phase 2: Applying the Manifest and Verifying
1.  I used `kubectl` to send my manifest to the Kubernetes API server.
    ```bash
    kubectl apply -f httpd-pod-resources.yaml
    ```
    The command responded with `pod/httpd-pod created`.

2.  **Verification:** The final and most important step was to confirm that the Pod was created with the correct resource settings.
    -   First, I checked that the Pod was running: `kubectl get pods`. The status was `Running`.
    -   For the definitive proof, I used the `describe` command:
        ```bash
        kubectl describe pod httpd-pod
        ```
    I scrolled down to the "Containers" section of the output and saw my exact settings reflected, which was the final proof of success.
    ```
    Containers:
      httpd-container:
        ...
        Limits:
          cpu:     100m
          memory:  20Mi
        Requests:
          cpu:     100m
          memory:  15Mi
        ...
    ```

---

### Why Did I Do This? (The "What & Why" for a K8s Beginner)
<a name="why-did-i-do-this-the-what--why-for-a-k8s-beginner)"></a>
-   **Resource Management**: This is the core concept of the task. In a Kubernetes cluster, many Pods from many different applications can run on the same physical server (a "Node"). Resource management is how the cluster administrator ensures that all these applications play nicely together. Without it, a single buggy application with a memory leak could consume all the RAM on a Node, causing every other application on that Node to crash.
-   **Requests vs. Limits (The Critical Distinction)**: I learned that these two settings serve very different purposes.
    1.  **Requests (The Guarantee):** This is the amount of CPU and Memory that I am **requesting** for my container. Kubernetes uses this number for **scheduling**. It will only place my Pod on a Node that has at least this amount of free resources available. This is a **guarantee**: my container will always have at least this much CPU and Memory reserved for it.
    2.  **Limits (The Ceiling):** This is the **maximum** amount of CPU and Memory my container is ever allowed to use. This is for **enforcement**. If my container tries to exceed its limits:
        -   **CPU:** It will be "throttled," meaning its CPU time will be artificially slowed down so it doesn't go over the limit.
        -   **Memory:** It will be killed. If a process tries to allocate more memory than its limit, the operating system will terminate it. This is called an "OOMKill" (Out Of Memory Kill). Kubernetes will then likely restart the container.

-   **CPU and Memory Units**:
    -   **CPU**: CPU is measured in "millicores" or "millicpus," written as `m`. `1000m` is equal to one full CPU core. So, my setting of `100m` is equivalent to 10% of a single CPU core.
    -   **Memory**: Memory is measured in bytes. The suffixes `Ki`, `Mi`, `Gi` represent Kibibytes, Mebibytes, and Gibibytes. My setting of `15Mi` requests 15 Mebibytes of RAM.

---

### Deep Dive: A Line-by-Line Explanation of My Pod YAML File
<a name="deep-dive-a-line-by-line-explanation-of-my-pod-yaml-file"></a>
The key to this task was adding the `resources` block to my Pod's container specification.

[Image showing a Pod with resource requests and limits]

```yaml
# Standard API version and Kind for a Pod.
apiVersion: v1
kind: Pod
metadata:
  name: httpd-pod
spec:
  containers:
  - name: httpd-container
    image: httpd:latest
    
    # This is the new and most important block for this task.
    resources:
      
      # The 'requests' block defines the guaranteed resources for the container.
      # This is used by the Kubernetes scheduler to find a suitable Node.
      requests:
        # Requesting 15 Mebibytes of Memory.
        memory: "15Mi"
        # Requesting 100 millicores (0.1) of a CPU core.
        cpu: "100m"
        
      # The 'limits' block defines the maximum allowed resources for the container.
      # This is enforced by the kubelet on the Node.
      limits:
        # The memory usage can never exceed 20 Mebibytes.
        memory: "20Mi"
        # The CPU usage can never exceed 100 millicores.
        cpu: "100m"
```

---

### Common Pitfalls for Beginners
<a name="common-pitfalls-for-beginners"></a>
-   **YAML Indentation Errors:** As always with Kubernetes, a single wrong space in the indentation of the `resources` block would make the file invalid.
-   **Incorrect Units:** Using the wrong case or unit (e.g., `15m` for memory, or `20mb` instead of `20Mi`) will cause the Pod creation to be rejected by the API server.
-   **Setting Requests Higher Than Limits:** A container's request for a resource can never be higher than its limit. If I set `requests.memory` to `30Mi` and `limits.memory` to `20Mi`, Kubernetes would reject the Pod as invalid.
-   **Forgetting to Verify with `describe`:** Running `kubectl get pods` only tells me if the Pod is running. It does **not** tell me if the resource constraints were applied correctly. The only way to be sure is to use `kubectl describe pod ...` and inspect the "Limits" and "Requests" section of the output.

---

### Exploring the Essential `kubectl` Commands
<a name="exploring-the-essential-kubectl-commands"></a>
This task reinforced the importance of the core `kubectl` commands.

-   **Creating & Updating:**
    -   `kubectl apply -f [filename.yaml]`: The standard way to create or update resources from a manifest file.

-   **Viewing & Inspecting (The most common commands):**
    -   `kubectl get pods`: **Gets** a summary list of all Pods.
    -   `kubectl describe pod [pod-name]`: **Describes** a specific Pod in great detail. This is my primary tool for troubleshooting. It shows the Pod's labels, IP address, events, and, crucially for this task, the applied resource `Requests` and `Limits`.
    -   `kubectl logs [pod-name]`: Shows the standard output (the logs) from the container running inside the Pod.
    -   `kubectl exec -it [pod-name] -- /bin/bash`: **Exec**utes a command inside the Pod. This gives me an **i**nteractive **t**erminal shell, allowing me to "get inside" my container.

-   **Deleting:**
    -   `kubectl delete -f [filename.yaml]`: Deletes all the resources defined in a specific file.
    -   `kubectl delete pod [pod-name]`: Deletes a specific Pod by name.

-   **Other useful commands:**
    -   `kubectl get all`: Shows a summary of all the most common resource types (Pods, Services, Deployments, etc.).
    -   `kubectl top pod [pod-name]`: A very useful command that shows the *current, real-time* CPU and Memory usage of a running Pod. This is how I can see if my application is getting close to its defined limits.
   