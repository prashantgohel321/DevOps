# DevOps Day 60: Deploying a Stateful Application with Persistent Storage

Today's task was a massive leap forward in my Kubernetes knowledge. I moved from deploying simple, stateless applications to deploying a **stateful** one. This required me to understand and implement Kubernetes's persistent storage system, a critical component for any application that needs to save data, like a database or a web server with user-uploaded content.

This was an incredible, end-to-end exercise where I built a complete application stack from the ground up, all within a single YAML file. I defined the physical storage (**PersistentVolume**), the request for that storage (**PersistentVolumeClaim**), the application that uses the storage (**Pod**), and the network access to the application (**Service**). This document is my very detailed, first-person guide to that entire process, written from the perspective of a beginner to Kubernetes storage.

## Table of Contents
- [DevOps Day 60: Deploying a Stateful Application with Persistent Storage](#devops-day-60-deploying-a-stateful-application-with-persistent-storage)
  - [Table of Contents](#table-of-contents)
    - [The Task](#the-task)
    - [My Step-by-Step Solution](#my-step-by-step-solution)
      - [Phase 1: Writing the Manifest File](#phase-1-writing-the-manifest-file)
      - [Phase 2: Applying the Manifest and Verifying](#phase-2-applying-the-manifest-and-verifying)
    - [Why Did I Do This? (The "What \& Why" for a K8s Beginner)](#why-did-i-do-this-the-what--why-for-a-k8s-beginner)
    - [Deep Dive: A Line-by-Line Explanation of My Full-Stack YAML Manifest](#deep-dive-a-line-by-line-explanation-of-my-full-stack-yaml-manifest)
    - [Common Pitfalls for Beginners](#common-pitfalls-for-beginners)
    - [Exploring the Essential `kubectl` Commands](#exploring-the-essential-kubectl-commands)

---

### The Task
<a name="the-task"></a>
My objective was to deploy a complete, accessible, and stateful `httpd` web server. The task was broken down into four distinct but interconnected resources:
1.  **PersistentVolume (PV):** Named `pv-devops`, with `4Gi` of `manual` storage from a `hostPath` at `/mnt/finance`.
2.  **PersistentVolumeClaim (PVC):** Named `pvc-devops`, requesting `1Gi` of `manual` storage.
3.  **Pod:** Named `pod-devops`, running an `httpd:latest` container named `container-devops`, and mounting the PVC as its web root.
4.  **Service:** Named `web-devops`, of type `NodePort`, exposing the application on node port `30008`.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The professional way to create these related resources is to define them all in a single YAML manifest file.

#### Phase 1: Writing the Manifest File
1.  I connected to the jump host.
2.  I created a new file named `web-app.yaml` using `vi`.
3.  Inside the editor, I wrote the following complete YAML code, using the `---` separator to define all four Kubernetes objects. I also remembered to add a `label` to my Pod so the Service's `selector` could find it.
    ```yaml
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: pv-devops
    spec:
      storageClassName: manual
      capacity:
        storage: 4Gi
      accessModes:
        - ReadWriteOnce
      hostPath:
        path: "/mnt/finance"
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: pvc-devops
    spec:
      storageClassName: manual
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 1Gi
    ---
    apiVersion: v1
    kind: Pod
    metadata:
      name: pod-devops
      labels:
        app: httpd-app # This label is critical for the Service
    spec:
      containers:
        - name: container-devops
          image: httpd:latest
          volumeMounts:
            - name: storage
              mountPath: /usr/local/apache2/htdocs
      volumes:
        - name: storage
          persistentVolumeClaim:
            claimName: pvc-devops
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: web-devops
    spec:
      type: NodePort
      selector:
        app: httpd-app # This selector matches the Pod's label
      ports:
        - protocol: TCP
          port: 80
          targetPort: 80
          nodePort: 30008
    ```
4.  I saved and quit the file.

#### Phase 2: Applying the Manifest and Verifying
1.  I used `kubectl` to send my manifest to the Kubernetes API server.
    ```bash
    kubectl apply -f web-app.yaml
    ```
    The command responded by confirming that all four objects (`persistentvolume`, `persistentvolumeclaim`, `pod`, and `service`) were created.

2.  **Verification:** The final step was to confirm that the entire chain of resources was correctly linked and running.
    -   First, I checked the storage.
        ```bash
        kubectl get pv,pvc
        ```
        The output showed both my `pv-devops` and `pvc-devops` with a `STATUS` of `Bound`.
    -   Next, I checked the application and network.
        ```bash
        kubectl get pod,service
        ```
    The output showed my `pod-devops` was `Running` and my `web-devops` service was correctly exposing port `30008`. This was the definitive proof of success.

---

### Why Did I Do This? (The "What & Why" for a K8s Beginner)
<a name="why-did-i-do-this-the-what--why-for-a-k8s-beginner)"></a>
-   **The Problem of Stateful Applications:** A standard Pod's filesystem is **ephemeral**. If the Pod crashes and is recreated, all the data inside it is lost. This is fine for stateless web servers, but a disaster for a database or a CMS where users upload files.
-   **The PV/PVC Abstraction (The Core Lesson):** Kubernetes solves this with a two-part abstraction. This is a brilliant design that decouples the application from the physical storage.
    1.  **`PersistentVolume` (PV):** This represents a piece of **physical storage** in the cluster. It's the "supply." An administrator is responsible for creating PVs. The PV I created was of type `hostPath`, meaning the "physical" storage was just a directory (`/mnt/finance`) on one of the cluster's nodes.
    2.  **`PersistentVolumeClaim` (PVC):** This is a **request for storage** made by a user or an application. It's the "demand." The PVC says, "I need 1Gi of storage that can be mounted by one pod at a time (`ReadWriteOnce`)."
-   **The Binding Process:** When I created my PVC, the Kubernetes control plane looked for an available PV that could satisfy my claim. It saw my `pv-devops` was a match (correct `storageClassName`, sufficient size, and correct `accessMode`) and automatically **bound** the PVC to the PV.
-   **Using the Claim in a Pod:** My Pod's definition did **not** refer to the PV directly. It referred to the **PVC**. This is the power of the abstraction. The Pod just says, "Give me the storage that `pvc-devops` claimed." Kubernetes handles the rest, ensuring the underlying PV is mounted into the Pod.

---

### Deep Dive: A Line-by-Line Explanation of My Full-Stack YAML Manifest
<a name="deep-dive-a-line-by-line-explanation-of-my-full-stack-yaml-manifest"></a>
This file defines the four interconnected objects that make up my application.

[Image of the Kubernetes PV, PVC, and Pod relationship]

```yaml
# --- PERSISTENT VOLUME (The Supply) ---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-devops
spec:
  # 'storageClassName' is a label for the type of storage. 'manual' means I created it myself.
  storageClassName: manual
  capacity:
    storage: 4Gi # The total size of this physical storage piece.
  # 'accessModes' defines how the volume can be mounted.
  # 'ReadWriteOnce' means it can be mounted as read-write by a single Node.
  accessModes:
    - ReadWriteOnce
  # 'hostPath' is the type of volume. It uses a directory on the host Node's filesystem.
  hostPath:
    path: "/mnt/finance"
---
# --- PERSISTENT VOLUME CLAIM (The Demand) ---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-devops
spec:
  # The storageClassName must match the PV for a successful binding.
  storageClassName: manual
  # The accessModes must also be a subset of what the PV supports.
  accessModes:
    - ReadWriteOnce
  # 'resources.requests' is how much storage I am requesting.
  resources:
    requests:
      storage: 1Gi
---
# --- POD (The Application) ---
apiVersion: v1
kind: Pod
metadata:
  name: pod-devops
  labels:
    app: httpd-app # This label is critical for the Service to find the Pod.
spec:
  containers:
    - name: container-devops
      image: httpd:latest
      # This block tells the container how to use a volume.
      volumeMounts:
        - name: storage # This name must match a volume defined in the 'volumes' block below.
          mountPath: /usr/local/apache2/htdocs # The path inside the container.
  # This 'volumes' block defines the volumes available to the Pod.
  volumes:
    - name: storage # A local name for the volume.
      # This is the key link: I am telling this volume to use the storage that was
      # claimed by the PVC named 'pvc-devops'.
      persistentVolumeClaim:
        claimName: pvc-devops
---
# --- SERVICE (The Network Access) ---
apiVersion: v1
kind: Service
metadata:
  name: web-devops
spec:
  type: NodePort
  # The selector that links the Service to the Pod.
  selector:
    app: httpd-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30008
```

---

### Common Pitfalls for Beginners
<a name="common-pitfalls-for-beginners"></a>
-   **Selector/Label Mismatch:** Forgetting to add a `label` to the Pod that matches the `selector` in the Service is the #1 reason a Service fails to connect.
-   **PV/PVC Mismatch:** The `storageClassName` and `accessModes` must be compatible between the PV and PVC for a successful binding. If they don't match, the PVC will remain in a `Pending` state forever.
-   **`claimName` Mismatch:** A typo in the `claimName` in the Pod's `volumes` section will cause the Pod to fail to start, as it won't be able to find the storage it needs.
-   **`hostPath` Issues:** In a multi-node cluster, using `hostPath` can be problematic. A Pod might be scheduled on `node-1`, write data to `/mnt/finance`, then crash and be rescheduled on `node-2`, where `/mnt/finance` is a completely different, empty directory. For real stateful applications, you would use a network-based storage solution like AWS EBS or a StorageClass.

---

### Exploring the Essential `kubectl` Commands
<a name="exploring-the-essential-kubectl-commands"></a>
-   `kubectl apply -f [filename.yaml]`: The standard way to create or update all the resources from my manifest file.
-   `kubectl get pv [pv-name]`: Gets a summary of a PersistentVolume. I used this to check its `STATUS` (`Bound`).
-   `kubectl get pvc [pvc-name]`: Gets a summary of a PersistentVolumeClaim. I used this to check its `STATUS` (`Bound`).
-   `kubectl get pod [pod-name]`: Gets a summary of my Pod's status.
-   `kubectl get service [svc-name]`: Gets a summary of my Service, which I used to confirm the `NodePort`.
-   `kubectl describe ...`: I could have used `describe` on any of these objects to get far more detail, such as the events that show the successful binding of the PV and PVC, and the successful mounting of the volume into the Pod.
  