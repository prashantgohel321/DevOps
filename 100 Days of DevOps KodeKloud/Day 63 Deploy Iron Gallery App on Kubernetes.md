# DevOps Day 63: Deploying a Full Two-Tier Application on Kubernetes

Today's task was the most comprehensive Kubernetes deployment I've done yet. It was a complete, end-to-end setup of a **two-tier application**, consisting of a frontend web gallery and a backend database. This wasn't just about creating a single Pod; it was about orchestrating an entire application stack with multiple, interconnected components.

I had to create a dedicated **Namespace** for isolation, two separate **Deployments** to manage the web and database Pods, and two different types of **Services** to handle internal and external communication. This was a fantastic, real-world exercise that tied together almost every core concept of Kubernetes application management. This document is my very detailed, first-person guide to that entire process, written from the perspective of a Kubernetes beginner.

## Table of Contents
- [DevOps Day 63: Deploying a Full Two-Tier Application on Kubernetes](#devops-day-63-deploying-a-full-two-tier-application-on-kubernetes)
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
My objective was to deploy a two-tier "iron gallery" application in a new namespace. This required creating five distinct Kubernetes objects:

1.  **Namespace:** `iron-namespace-datacenter` to house all the application's resources.
2.  **Web Deployment:** `iron-gallery-deployment-datacenter` for the frontend, with 1 replica, resource limits, and two `emptyDir` volumes.
3.  **DB Deployment:** `iron-db-deployment-datacenter` for the backend, with 1 replica, environment variables for database setup, and an `emptyDir` volume.
4.  **DB Service:** `iron-db-service-datacenter`, a `ClusterIP` type service for internal communication.
5.  **Web Service:** `iron-gallery-service-datacenter`, a `NodePort` type service to expose the application externally on port `32678`.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The professional way to create these related resources is to define them all in a single YAML manifest file.

#### Phase 1: Writing the Manifest File
1.  I connected to the jump host.
2.  I created a new file named `iron-gallery-app.yaml` using `vi`.
3.  Inside the editor, I wrote the following complete YAML code, using the `---` separator to define all five Kubernetes objects.
    ```yaml
    # 1. The Namespace to isolate our application
    apiVersion: v1
    kind: Namespace
    metadata:
      name: iron-namespace-datacenter
    ---
    # 2. The Deployment for the frontend web application
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: iron-gallery-deployment-datacenter
      namespace: iron-namespace-datacenter
      labels:
        run: iron-gallery
    spec:
      replicas: 1
      selector:
        matchLabels:
          run: iron-gallery
      template:
        metadata:
          labels:
            run: iron-gallery
        spec:
          containers:
          - name: iron-gallery-container-datacenter
            image: kodekloud/irongallery:2.0
            resources:
              limits:
                memory: "100Mi"
                cpu: "50m"
            volumeMounts:
            - name: config
              mountPath: /usr/share/nginx/html/data
            - name: images
              mountPath: /usr/share/nginx/html/uploads
          volumes:
          - name: config
            emptyDir: {}
          - name: images
            emptyDir: {}
    ---
    # 3. The Deployment for the backend database
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: iron-db-deployment-datacenter
      namespace: iron-namespace-datacenter
      labels:
        db: mariadb
    spec:
      replicas: 1
      selector:
        matchLabels:
          db: mariadb
      template:
        metadata:
          labels:
            db: mariadb
        spec:
          containers:
          - name: iron-db-container-datacenter
            image: kodekloud/irondb:2.0
            env:
            - name: MYSQL_DATABASE
              value: "database_host"
            - name: MYSQL_ROOT_PASSWORD
              value: "ComplexRootPass123!"
            - name: MYSQL_USER
              value: "kodekloud_user"
            - name: MYSQL_PASSWORD
              value: "ComplexUserPass456@"
            volumeMounts:
            - name: db
              mountPath: /var/lib/mysql
          volumes:
          - name: db
            emptyDir: {}
    ---
    # 4. The Service for the database (internal access)
    apiVersion: v1
    kind: Service
    metadata:
      name: iron-db-service-datacenter
      namespace: iron-namespace-datacenter
    spec:
      type: ClusterIP
      selector:
        db: mariadb
      ports:
        - protocol: TCP
          port: 3306
          targetPort: 3306
    ---
    # 5. The Service for the web app (external access)
    apiVersion: v1
    kind: Service
    metadata:
      name: iron-gallery-service-datacenter
      namespace: iron-namespace-datacenter
    spec:
      type: NodePort
      selector:
        run: iron-gallery
      ports:
        - protocol: TCP
          port: 80
          targetPort: 80
          nodePort: 32678
    ```
4.  I saved and quit the file.

#### Phase 2: Applying the Manifest and Verifying
1.  I used `kubectl` to send my manifest to the Kubernetes API server.
    ```bash
    kubectl apply -f iron-gallery-app.yaml
    ```
    The command responded by confirming that all five objects were created.

2.  **Verification:** The final step was to confirm that all the objects were created correctly and were running in the new namespace.
    ```bash
    kubectl get all -n iron-namespace-datacenter
    ```
    The output of this single command was the definitive proof of success. It showed me:
    -   The two Pods (one for the gallery, one for the DB), both in a `Running` state.
    -   The two Services (`iron-db-service-datacenter` as `ClusterIP` and `iron-gallery-service-datacenter` as `NodePort`).
    -   The two Deployments, both with `1/1` ready replicas.
    This confirmed that my entire application stack was up and running as designed.

---

### Why Did I Do This? (The "What & Why" for a K8s Beginner)
<a name="why-did-i-do-this-the-what--why-for-a-k8s-beginner)"></a>
-   **Namespaces**: A Namespace is a **virtual cluster** within my physical Kubernetes cluster. It's the primary way to provide isolation. By creating `iron-namespace-datacenter` and placing all my resources inside it, I keep my "iron gallery" application completely separate from any other applications running in other namespaces. This is critical for organizing a multi-tenant or multi-environment cluster.
-   **Deployments**: A Deployment is the manager for my application's Pods. It provides **self-healing** (recreating Pods if they crash) and **scalability**. I created two separate Deployments, one for the frontend and one for the backend, which is a standard practice that allows me to scale them independently.
-   **Services**: A Service provides a stable network endpoint for my ephemeral Pods. I used two different types for two different purposes:
    -   **`ClusterIP` Service:** This is the **default** type. It creates a stable IP address and DNS name that is **only reachable from inside the cluster**. This is perfect for my database (`iron-db-service-datacenter`). I don't want the database to be exposed to the public internet, but my web application (running inside the cluster) needs a reliable way to connect to it. The web app can simply connect to the hostname `iron-db-service-datacenter`.
    -   **`NodePort` Service:** This service type exposes the application to the **outside world**. It opens a static port (`32678` in my case) on every Node in the cluster. Any traffic sent to any Node's IP on that port is forwarded to my web Pods.
-   **Labels and Selectors**: This is the "glue" that connects everything. The `selector` in each Service (`selector: {db: mariadb}` or `selector: {run: iron-gallery}`) tells it which Pods to send traffic to, based on the `labels` defined in the Pod templates of the Deployments.

---

### Deep Dive: A Line-by-Line Explanation of My Full-Stack YAML Manifest
<a name="deep-dive-a-line-by-line-explanation-of-my-full-stack-yaml-manifest"></a>
This multi-document YAML file is the blueprint for my entire application.

[Image of a two-tier application on Kubernetes]

-   **`Namespace`:** A very simple object. It just needs a `name`. All other objects in this file have `namespace: iron-namespace-datacenter` in their `metadata` to ensure they are created in the right place.
-   **`Deployments`:** Both Deployments follow the standard structure:
    -   `replicas`: How many copies of the Pod to run.
    -   `selector`: How the Deployment finds the Pods it manages.
    -   `template`: The blueprint for the Pods, which includes `metadata.labels` that **must match the selector**, and the `spec` which defines the containers, volumes, etc.
-   **`ClusterIP` Service:**
    -   `type: ClusterIP`: Makes this service internal-only.
    -   `selector: {db: mariadb}`: The crucial link. It tells the service to find all Pods with the label `db: mariadb`.
    -   `port: 3306` / `targetPort: 3306`: The service listens on port 3306 and forwards traffic to port 3306 on the Pods.
-   **`NodePort` Service:**
    -   `type: NodePort`: Makes this service accessible from outside the cluster.
    -   `selector: {run: iron-gallery}`: The link to my frontend Pods.
    -   `port: 80`: The port the service listens on internally.
    -   `targetPort: 80`: The port on the Nginx container to send traffic to.
    -   `nodePort: 32678`: The static port that is opened on every Node.

---

### Common Pitfalls for Beginners
<a name="common-pitfalls-for-beginners"></a>
-   **Forgetting the Namespace:** If I forgot to add `namespace: iron-namespace-datacenter` to any of my resources, it would be created in the `default` namespace by mistake, and my application would not be properly isolated.
-   **Selector/Label Mismatch:** This is the #1 error. If the `selector` in a Service does not exactly match the `labels` in the Deployment's Pod template, the Service will not be able to find any Pods, and it will not work.
-   **`emptyDir` for Databases:** My use of an `emptyDir` volume for the database is a major anti-pattern for production. Because an `emptyDir` is ephemeral, if the database Pod were to be deleted or rescheduled to another Node, **all the data would be lost**. In a real-world scenario, I would always use a `PersistentVolumeClaim` for a database.

---

### Exploring the Essential `kubectl` Commands
<a name="exploring-the-essential-kubectl-commands"></a>
-   `kubectl apply -f [filename.yaml]`: The standard way to create or update all the resources from my manifest file.
-   `kubectl get all -n iron-namespace-datacenter`: The most useful command for this task.
    -   `get all`: Shows a summary of all the most common resource types (Pods, Deployments, ReplicaSets, Services).
    -   `-n iron-namespace-datacenter`: The `-n` or `--namespace` flag is crucial. It tells `kubectl` to perform the action in my specific namespace, not the `default` one.
-   `kubectl get ns`: A simple command to **g**et **n**ame**s**paces, which I could use to verify my new namespace was created.
-   `kubectl describe ... -n [namespace]`: I could use `describe` on any of my objects (e.g., `kubectl describe deployment iron-gallery-deployment-datacenter -n iron-namespace-datacenter`) to get far more detail and troubleshoot any issues.
  