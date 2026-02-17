# DevOps Day 67: Deploying a Three-Tier Microservices App on Kubernetes

Today's task was the most complex and realistic Kubernetes deployment I've ever done. My objective was to deploy a complete **three-tier application**—the classic "guestbook" app. This involved orchestrating a frontend web server, a primary (master) database, and multiple read-only (slave) database replicas.

This was a fantastic exercise that brought all the core Kubernetes concepts together. I had to create three separate **Deployments** to manage each component, and three corresponding **Services** to handle the networking between them. I learned the critical difference between a `NodePort` service (for external access) and a `ClusterIP` service (for internal communication). This document is my very detailed, first-person guide to that entire process, written for a Kubernetes beginner.

## Table of Contents
- [DevOps Day 67: Deploying a Three-Tier Microservices App on Kubernetes](#devops-day-67-deploying-a-three-tier-microservices-app-on-kubernetes)
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
My objective was to deploy a full guestbook application by creating six distinct Kubernetes resources:

1.  **Redis Master Deployment:** `redis-master` (1 replica) using the `redis` image.
2.  **Redis Master Service:** `redis-master` (a `ClusterIP`) to provide a stable endpoint for write operations.
3.  **Redis Slave Deployment:** `redis-slave` (2 replicas) using the `gcr.io/google_samples/gb-redisslave:v3` image.
4.  **Redis Slave Service:** `redis-slave` (a `ClusterIP`) to provide a load-balanced endpoint for read operations.
5.  **Frontend Deployment:** `frontend` (3 replicas) using the `gcr.io/google-samples/gb-frontend` image.
6.  **Frontend Service:** `frontend` (a `NodePort`) to expose the application to the outside world on port `30009`.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The professional way to deploy such an interconnected application is to define all six resources in a single YAML manifest file.

#### Phase 1: Writing the Manifest File
1.  I connected to the jump host.
2.  I created a new file named `guestbook-app.yaml` using `vi`.
3.  Inside the editor, I wrote the following complete YAML code, using the `---` separator to define all six Kubernetes objects. I created my own clear labels (`app: guestbook, tier: ...`) to link the services.
    ```yaml
    # --- 1. REDIS MASTER (BACKEND) ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: redis-master
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: guestbook
          tier: backend
          role: master
      template:
        metadata:
          labels:
            app: guestbook
            tier: backend
            role: master
        spec:
          containers:
          - name: master-redis-devops
            image: redis:latest
            resources:
              requests:
                cpu: "100m"
                memory: "100Mi"
            ports:
            - containerPort: 6379
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: redis-master
    spec:
      selector:
        app: guestbook
        tier: backend
        role: master
      ports:
        - protocol: TCP
          port: 6379
          targetPort: 6379
    
    ---
    # --- 2. REDIS SLAVE (BACKEND) ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: redis-slave
    spec:
      replicas: 2
      selector:
        matchLabels:
          app: guestbook
          tier: backend
          role: slave
      template:
        metadata:
          labels:
            app: guestbook
            tier: backend
            role: slave
        spec:
          containers:
          - name: slave-redis-devops
            image: gcr.io/google_samples/gb-redisslave:v3
            resources:
              requests:
                cpu: "100m"
                memory: "100Mi"
            env:
            - name: GET_HOSTS_FROM
              value: "dns"
            ports:
            - containerPort: 6379
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: redis-slave
    spec:
      selector:
        app: guestbook
        tier: backend
        role: slave
      ports:
        - protocol: TCP
          port: 6379
          targetPort: 6379

    ---
    # --- 3. FRONTEND (WEB) ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: frontend
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: guestbook
          tier: frontend
      template:
        metadata:
          labels:
            app: guestbook
            tier: frontend
        spec:
          containers:
          - name: php-redis-devops
            image: gcr.io/google-samples/gb-frontend@sha256:a908df8486ff66f2c4daa0d3d8a2fa09846a1fc8efd65649c0109695c7c5cbff
            resources:
              requests:
                cpu: "100m"
                memory: "100Mi"
            env:
            - name: GET_HOSTS_FROM
              value: "dns"
            ports:
            - containerPort: 80
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: frontend
    spec:
      type: NodePort
      selector:
        app: guestbook
        tier: frontend
      ports:
        - protocol: TCP
          port: 80
          targetPort: 80
          nodePort: 30009
    ```
4.  I saved and quit the file.

#### Phase 2: Applying the Manifest and Verifying
1.  I used `kubectl` to send my manifest to the Kubernetes API server.
    ```bash
    kubectl apply -f guestbook-app.yaml
    ```
    The command responded by confirming that all six objects were created.

2.  **Verification:** The final step was to confirm that the entire application stack was up and running.
    ```bash
    kubectl get all
    ```
    The output of this single command was the definitive proof of success. It showed me:
    -   `pod/frontend-...` (3 Pods)
    -   `pod/redis-master-...` (1 Pod)
    -   `pod/redis-slave-...` (2 Pods)
    -   `service/frontend` (as `NodePort`)
    -   `service/redis-master` (as `ClusterIP`)
    -   `service/redis-slave` (as `ClusterIP`)
    -   `deployment.apps/frontend` (with `3/3` ready)
    -   `deployment.apps/redis-master` (with `1/1` ready)
    -   `deployment.apps/redis-slave` (with `2/2` ready)
    
    Finally, I clicked the "App" button in the lab, which opened the `frontend` service's `NodePort`, and I saw the live Guestbook application.

---

### Why Did I Do This? (The "What & Why" for a K8s Beginner)
<a name="why-did-i-do-this-the-what--why-for-a-k8s-beginner)"></a>
-   **Microservices Architecture:** This is a classic example. My application was not one giant program; it was broken into three separate, independent services: a frontend, a write-database (`redis-master`), and a read-database (`redis-slave`). Kubernetes is designed to manage exactly this kind of architecture.
-   **Deployments**: The `Deployment` is the controller that provides **self-healing** and **scalability**. By setting `replicas: 3` for my frontend, I told Kubernetes, "I always want three copies of my web server running." If one crashes, the Deployment will instantly create a new one to replace it.
-   **Labels and Selectors (The "Glue")**: This is the magic that connects everything. I defined labels in my Deployments' Pod templates (e.g., `app: guestbook, tier: frontend`). Then, in my Service, I used a `selector` that looked for those exact labels (`selector: {app: guestbook, tier: frontend}`). This is how my `frontend` Service knew to send traffic *only* to my `frontend` Pods.
-   **Service Discovery (`ClusterIP` vs. `NodePort`)**: This was the most important networking lesson.
    -   **`ClusterIP` (Internal):** The `redis-master` and `redis-slave` services are of this type (it's the default). It creates a stable IP address and DNS name (e.g., `redis-master`) that is **only reachable from inside the cluster**. This is perfect for backend services. My frontend Pods can find the database simply by connecting to the hostname `redis-master`, without ever needing to know its IP.
    -   **`NodePort` (External):** The `frontend` service needed to be accessible from outside the cluster. By setting `type: NodePort`, I told Kubernetes to open a high-numbered port (`30009`) on the physical cluster Nodes, allowing external users to access my application.

---

### Deep Dive: A Line-by-Line Explanation of My Full-Stack YAML Manifest
<a name="deep-dive-a-line-by-line-explanation-of-my-full-stack-yaml-manifest"></a>
My `guestbook-app.yaml` file defined six objects, separated by `---`.

[Image of a three-tier Kubernetes application]

-   **`kind: Deployment`:**
    -   `replicas: 3`: Told Kubernetes I want 3 copies of my frontend Pods.
    -   `selector: {matchLabels: ...}`: The Deployment's "search query" to find the Pods it manages.
    -   `template:`: The blueprint for the Pods to be created.
    -   `template.metadata.labels:`: The "nametag" given to each Pod, which **must match** the Deployment's selector.
    -   `env: {name: GET_HOSTS_FROM, value: "dns"}`: This tells the application inside the container to find other services (like `redis-master`) using the cluster's internal DNS, which is the standard K8s service discovery method.
-   **`kind: Service`:**
    -   `selector:`: The "search query" for the Service to find the Pods it should send traffic to. This **must match** the Pods' labels.
    -   `type: NodePort`: Makes the Service accessible from outside the cluster.
    -   `port: 80`: The port the Service itself listens on *inside* the cluster's private network.
    -   `targetPort: 80`: The port the application *container* is listening on.
    -   `nodePort: 30009`: The static port that is opened on every Node.

---

### Common Pitfalls for Beginners
<a name="common-pitfalls-for-beginners"></a>
-   **Selector/Label Mismatch:** This is the #1 error. If the `selector` in my `frontend` Service was `app: my-app` but my Pods had the label `app: frontend`, the Service would not find any endpoints and the connection would fail.
-   **`port` vs. `targetPort`:** It's easy to get these confused. `targetPort` must match the `containerPort` on the Pods. `port` is the port the Service listens on internally. `nodePort` is the port for external access.
-   **Forgetting `---`:** When defining multiple resources in one file, this separator is mandatory.
-   **Using `NodePort` for a Database:** Exposing a database directly to the outside world with a `NodePort` is a major security risk. The correct pattern, which I used, is to keep it internal with the default `ClusterIP` type.

---

### Exploring the Essential `kubectl` Commands
<a name="exploring-the-essential-kubectl-commands"></a>
-   `kubectl apply -f [filename.yaml]`: The standard way to create or update all the resources from my manifest file.
-   `kubectl get all`: This was the most useful command for this task. It shows a summary of all the key resources (Pods, Deployments, ReplicaSets, Services) in the current namespace, giving me a complete overview of my application.
-   `kubectl get svc`: A quick command to list just the services and see their types and port mappings.
-   `kubectl describe svc [service-name]`: My primary tool for debugging a Service. The `Endpoints` field at the bottom is critical. If it says `<none>`, I know I have a selector/label mismatch.
-   `kubectl describe pod [pod-name]`: My tool for debugging a single Pod if it was failing to start.
   