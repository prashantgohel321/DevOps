# DevOps Day 48: My First Pod in Kubernetes

Today was a monumental day in my DevOps learning journey. I graduated from running single containers with Docker to orchestrating them with **Kubernetes (K8s)**. This task was my "Hello, World!" for K8s, where my objective was to create the most fundamental building block of the system: a **Pod**.

This was a huge conceptual shift. I moved from giving direct, *imperative* commands like `docker run` to writing a *declarative* manifest file in YAML. This file describes the *desired state* of my application, and I then hand it off to Kubernetes to make it a reality. This document is my very detailed, first-person guide to that entire process, written from the perspective of a complete beginner to Kubernetes.

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
My objective was to create a single Kubernetes Pod on the provided cluster. The specific requirements were:
1.  The Pod must be named `pod-httpd`.
2.  It must use the `httpd:latest` Docker image.
3.  It needed a label `app` with the value `httpd_app`.
4.  The container inside the Pod had to be named `httpd-container`.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The professional way to create resources in Kubernetes is with a YAML manifest file. I followed this declarative approach.

#### Phase 1: Writing the Pod Manifest
1.  I connected to the jump host, where `kubectl` was pre-configured to talk to the cluster.
2.  I created a new file named `pod-httpd.yaml` using `vi`.
3.  Inside the editor, I wrote the following YAML code, which is a declaration of the Pod I wanted to create.
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: pod-httpd
      labels:
        app: httpd_app
    spec:
      containers:
      - name: httpd-container
        image: httpd:latest
    ```
4.  I saved and quit the file.

#### Phase 2: Applying the Manifest and Verifying
1.  This was the magic moment. I used `kubectl` to send my manifest to the Kubernetes API server.
    ```bash
    kubectl apply -f pod-httpd.yaml
    ```
    The command responded with `pod/pod-httpd created`, which was my first sign of success.

2.  **Verification:** The final and most important step was to confirm that the Pod was created correctly and was running.
    -   First, I checked the status of the Pod.
        ```bash
        kubectl get pods
        ```
        The output showed `pod-httpd` with a `STATUS` of `Running`.
    -   For a definitive check, I used the `describe` command to see all the details.
        ```bash
        kubectl describe pod pod-httpd
        ```
    This detailed output allowed me to confirm every single requirement: the Pod's name, its label, the container's name, and the image it was using. This was the final proof of success.

---

### Why Did I Do This? (The "What & Why" for a K8s Beginner)
<a name="why-did-i-do-this-the-what--why-for-a-k8s-beginner)"></a>

-   **Kubernetes (K8s)**: I like to think of Kubernetes as the operating system for the cloud. While **Docker** runs one container at a time, **Kubernetes** manages many containers across multiple servers, called a **cluster**. It takes care of things like deploying apps, scaling them up or down, fixing issues automatically, and handling their networking.

-   **Pod**: This is the basic building block in Kubernetes. A Pod is the smallest thing you can deploy. Instead of running a container directly, I run a **Pod that holds my container**. A Pod **can also have multiple containers** that work together. They **share the same environment**, like one IP address and storage.

-   **`kubectl`**: This is the **command-line tool** I use to talk to the Kubernetes cluster. You can think of it **like a remote control** — I use it **to tell the cluster what to do**, such as creating Pods, checking their status, or managing deployments.

-   **Declarative Manifests (YAML)**: This is one of the main ideas behind Kubernetes. Instead of giving step-by-step commands like “run this, then do that,” I write a YAML file that **describes how I want my application to look in the end**. This file acts like **a blueprint**. I give it to Kubernetes, and Kubernetes keeps working to make sure the cluster matches what’s written in that file. It’s a clean, repeatable, and easy-to-track way to manage infrastructure.

---

### Deep Dive: A Line-by-Line Explanation of My Pod YAML File
<a name="deep-dive-a-line-by-line-explanation-of-my-pod-yaml-file"></a>
The YAML file is the "recipe" for my Pod. Understanding its structure is the key to mastering Kubernetes.



```yaml
# 'apiVersion' tells Kubernetes which version of its API to use to create this object.
# 'v1' is the core, stable API group for fundamental objects like Pods.
apiVersion: v1

# 'kind' specifies the TYPE of object I want to create. In this case, a 'Pod'.
# Other kinds include 'Deployment', 'Service', 'ConfigMap', etc.
kind: Pod

# This section 'metadata' contains information that helps identify the object in Kubernetes.
# It includes details like the object’s name, labels, and annotations.
# basically, information that tells Kubernetes what this object is and how it should be organized or grouped.
metadata:
  # 'name' is the unique name for this Pod within its namespace.
  name: pod-httpd
  # 'labels' are key-value pairs that I can attach to my objects.
  # They are incredibly important for organizing and selecting objects later.
  labels:
    app: httpd_app

# 'spec' (Specification) is where I describe the DESIRED STATE of the object.
# This is the most important section. For a Pod, the spec describes the containers
# that should run inside it.
spec:
  # 'containers' is a list. A Pod can have multiple containers, so this is an array.
  containers:
  # The '-' indicates the start of a new item in the list. This is my first container.
  - name: httpd-container  # The name of the container within the Pod.
    image: httpd:latest   # The Docker image to use for this container.
```

---

### Common Pitfalls for Beginners
<a name="common-pitfalls-for-beginners"></a>

- **YAML Indentation Errors**: YAML is extremely strict about indentation (2 spaces is the standard). A single wrong space can make the file completely invalid. kubectl will usually give a helpful error pointing to the line.

- **Confusing Pod Name and Container Name**: It's important to remember that a Pod has a name, and each container inside the Pod also has its own name. The task required me to set both.

- **Forgetting `-f`**: When using kubectl apply, the `-f` flag is required to specify the filename of the manifest you want to apply.

- **Typos in kind or apiVersion**: A typo like kind: `pod` (lowercase) would be rejected by the Kubernetes API. These values are case-sensitive.

---

### Exploring the Essential kubectl Commands
<a name="exploring-the-essential-kubectl-commands"></a>
This task introduced me to the core commands, but there are a few others that are essential for daily work.

- **Creating & Updating:**

    - **`kubectl apply -f [filename.yaml]`**: The main command I used. It's the standard way to create or update resources. If the object doesn't exist, it creates it. If it does exist, it applies any changes from the file.

- **Viewing & Inspecting (The most common commands):**

    - **`kubectl get pods`**: Gets a summary list of all Pods in the current namespace. The output shows their name, ready status, running status, restarts, and age. You can use it for other objects too, like kubectl get services.

    - **`kubectl describe pod [pod-name]`**: Describes a specific Pod in great detail. This is my primary tool for troubleshooting. It shows the Pod's labels, IP address, events (like when it was scheduled or when the image was pulled), and the state of its containers.

    - **`kubectl logs [pod-name]`**: Shows the standard output (the logs) from the container running inside the Pod. This is essential for debugging my application.

    - **`kubectl exec -it [pod-name] -- /bin/bash`**: Executes a command inside the Pod. This gives me an interactive terminal shell, just like docker exec. This is how I can "get inside" my container to look around.

- **Deleting:**

    - **`kubectl delete -f [filename.yaml]`**: Deletes all the resources defined in a specific file.

    - **`kubectl delete pod [pod-name]`**: Deletes a specific Pod by name.

- **Other useful commands:**

    - **`kubectl get all`**: Shows a summary of all the most common resource types (Pods, Services, Deployments, etc.) in the current namespace.