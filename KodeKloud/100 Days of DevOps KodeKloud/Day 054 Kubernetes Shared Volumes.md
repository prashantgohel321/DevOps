# DevOps Day 54: Shared Volumes in Multi-Container Pods

Today's task was a fantastic dive into a more advanced Kubernetes pattern: the **multi-container Pod**. My objective was to create a single Pod that ran two separate containers and, most importantly, to set up a shared volume that both containers could read from and write to.

This was a critical lesson in how tightly-coupled processes can work together within the Kubernetes ecosystem. I learned how to define a shared `emptyDir` volume at the Pod level and then mount it into each container at different paths. This document is my very detailed, first-person guide to that entire process, written from the perspective of a complete beginner to this concept.

## Table of Contents
- [DevOps Day 54: Shared Volumes in Multi-Container Pods](#devops-day-54-shared-volumes-in-multi-container-pods)
  - [Table of Contents](#table-of-contents)
    - [The Task](#the-task)
    - [My Step-by-Step Solution](#my-step-by-step-solution)
      - [Phase 1: Writing the Pod Manifest](#phase-1-writing-the-pod-manifest)
      - [Phase 2: Applying the Manifest and Verifying](#phase-2-applying-the-manifest-and-verifying)
    - [Why Did I Do This? (The "What \& Why" for a K8s Beginner)](#why-did-i-do-this-the-what--why-for-a-k8s-beginner)
    - [Deep Dive: A Line-by-Line Explanation of My Pod YAML File](#deep-dive-a-line-by-line-explanation-of-my-pod-yaml-file)
    - [Common Pitfalls for Beginners](#common-pitfalls-for-beginners)
    - [Exploring the Essential `kubectl` Commands](#exploring-the-essential-kubectl-commands)

---

### The Task
<a name="the-task"></a>
My objective was to create a single Kubernetes Pod with two containers sharing a volume. The specific requirements were:
1.  The Pod must be named `volume-share-nautilus`.
2.  It must contain two containers, `volume-container-nautilus-1` and `volume-container-nautilus-2`, both using the `debian:latest` image.
3.  A shared `emptyDir` volume named `volume-share` must be created.
4.  This volume must be mounted at `/tmp/news` in the first container and at `/tmp/cluster` in the second container.
5.  I had to verify the setup by creating a file in one container's mount path and confirming its existence in the other's.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The professional way to create this complex Pod is with a single YAML manifest file.

#### Phase 1: Writing the Pod Manifest
1.  I connected to the jump host.
2.  I created a new file named `shared-volume-pod.yaml` using `vi`.
3.  Inside the editor, I wrote the following YAML code, which defines the shared volume at the Pod level and then mounts it into each container.
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: volume-share-nautilus
    spec:
      volumes:
      - name: volume-share
        emptyDir: {}
      containers:
      - name: volume-container-nautilus-1
        image: debian:latest
        command: ["/bin/sh", "-c", "sleep 3600"]
        volumeMounts:
        - name: volume-share
          mountPath: /tmp/news
      - name: volume-container-nautilus-2
        image: debian:latest
        command: ["/bin/sh", "-c", "sleep 3600"]
        volumeMounts:
        - name: volume-share
          mountPath: /tmp/cluster
    ```
4.  I saved and quit the file.

#### Phase 2: Applying the Manifest and Verifying
1.  I used `kubectl` to create the Pod from my manifest.
    ```bash
    kubectl apply -f shared-volume-pod.yaml
    ```
2.  **Verification:** The final part of the task was to prove that the volume was truly shared.
    -   First, I checked the Pod's status with `kubectl get pods`. The `READY` column showed `2/2`, confirming both containers were running.
    -   Next, I `exec`'d into the first container to create the test file.
        ```bash
        kubectl exec -it volume-share-nautilus -c volume-container-nautilus-1 -- /bin/bash
        # Inside the container shell:
        echo "Shared volume test" > /tmp/news/news.txt
        exit
        ```
    -   Finally, I `exec`'d into the second container to look for the file.
        ```bash
        kubectl exec -it volume-share-nautilus -c volume-container-nautilus-2 -- /bin/bash
        # Inside the container shell:
        ls -l /tmp/cluster/
        ```
    The output listed the `news.txt` file. This was the definitive proof that both containers were writing to and reading from the exact same directory, successfully completing the task.

---

### Why Did I Do This? (The "What & Why" for a K8s Beginner)
<a name="why-did-i-do-this-the-what--why-for-a-k8s-beginner)"></a>
-   **Multi-Container Pods**: This is a powerful Kubernetes pattern. While most Pods have a single container, you can run multiple containers together in one Pod when they are very tightly coupled and need to share resources. The classic example is a "sidecar" container that helps a main application container (e.g., a log shipper that reads the main app's logs and sends them to a central location). Because containers in a Pod share a network, they can communicate via `localhost`.
-   **Shared Volumes**: This is the key concept of the task. By defining a volume at the Pod level (`spec.volumes`), I create a storage resource that can be accessed by any container within that Pod.
-   **`emptyDir` Volume**: This is the simplest type of volume in Kubernetes.
    -   **What it is:** An `emptyDir` is exactly what it sounds like: a new, **empty dir**ectory that is created when the Pod is scheduled on a Node.
    -   **Lifecycle:** It is ephemeral. It exists only as long as the Pod exists. When the Pod is deleted, the `emptyDir` and all its data are permanently erased.
    -   **Use Case:** It's perfect for temporary scratch space or, as in my task, for providing a shared filesystem for multiple containers in the same Pod. One container can write data, and the other can immediately read it.

---

### Deep Dive: A Line-by-Line Explanation of My Pod YAML File
<a name="deep-dive-a-line-by-line-explanation-of-my-pod-yaml-file"></a>
The YAML for a multi-container pod with a shared volume has two key parts: defining the volume and then mounting it.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: volume-share-nautilus
spec:
  # This 'volumes' block is at the Pod's 'spec' level. This is where I DECLARE
  # all the volumes that will be available to the containers in this Pod.
  volumes:
  # The '-' indicates an item in a list. This is my first volume definition.
  - name: volume-share  # I give the volume a name that I can refer to later.
    emptyDir: {}       # I specify the TYPE of volume. '{}' means use the defaults.

  # 'containers' is a list of all the containers that will run in this Pod.
  containers:
  # This is the definition for the first container.
  - name: volume-container-nautilus-1
    image: debian:latest
    command: ["/bin/sh", "-c", "sleep 3600"] # A command to keep it running.
    
    # This 'volumeMounts' block is inside the container's definition.
    # It tells this specific container how to USE a volume declared above.
    volumeMounts:
    - name: volume-share  # This name MUST match the name from the 'volumes' block.
      mountPath: /tmp/news # This is the path INSIDE this container to mount the volume.

  # This is the definition for the second container.
  - name: volume-container-nautilus-2
    image: debian:latest
    command: ["/bin/sh", "-c", "sleep 3600"]
    
    # This container also gets a 'volumeMounts' block.
    volumeMounts:
    - name: volume-share  # It refers to the SAME volume by name.
      mountPath: /tmp/cluster # But it mounts it at a DIFFERENT path inside this container.
```

---

### Common Pitfalls for Beginners
<a name="common-pitfalls-for-beginners"></a>
-   **Forgetting the `-c` flag:** When a Pod has more than one container, you **must** use the `-c <container-name>` flag for commands like `kubectl exec` and `kubectl logs` to tell Kubernetes which specific container you want to interact with. Forgetting it will result in an error.
-   **Confusing `volumes` and `volumeMounts`:** `volumes` is defined once at the Pod level to create the volume. `volumeMounts` is defined inside each container that needs to access that volume.
-   **Name Mismatch:** The `name` in a container's `volumeMounts` section must exactly match the `name` of a volume defined in the Pod's `volumes` section. A typo will cause the Pod to fail to start.
-   **Forgetting a `command`:** The `debian` image doesn't have a default command that keeps it running. Without the `command: ["/bin/sh", "-c", "sleep 3600"]`, the containers would start, do nothing, and immediately exit, causing the Pod to go into a `CrashLoopBackOff` state.

---

### Exploring the Essential `kubectl` Commands
<a name="exploring-the-essential-kubectl-commands"></a>
-   `kubectl apply -f [filename.yaml]`: The standard way to create or update resources from a manifest file.
-   `kubectl get pods`: **Gets** a summary list of all Pods. I used this to check the `READY` status (`2/2`).
-   `kubectl describe pod [pod-name]`: **Describes** a Pod in great detail. I used this to verify that the volumes and volume mounts were configured correctly for both containers.
-   `kubectl exec -it [pod-name] -c [container-name] -- [command]`: **Exec**utes a command inside a specific container within a multi-container Pod. This was the essential command for my verification step.
    -   `-i`: Interactive.
    -   `-t`: Allocate a TTY.
    -   `-c`: Specifies the **c**ontainer name.
    -   `--`: Separates the `kubectl` command from the command to be run inside the container.
  