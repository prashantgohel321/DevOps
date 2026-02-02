# DevOps Day 56: Deploying a Scalable and Accessible Application in Kubernetes

Today's task was a huge leap in my Kubernetes journey. I went from managing single, mortal Pods to deploying a robust, scalable, and highly available application using a **Deployment**. Even more importantly, I learned how to make that application accessible from outside the cluster using a **Service**.

This was a fantastic, real-world exercise that taught me how to combine two of the most fundamental Kubernetes objects to create a complete application stack. I learned how the Deployment ensures my app is always running and how the Service provides a stable entry point for users. This document is my very detailed, first-person guide to that entire process, written from the perspective of a complete beginner to Kubernetes networking.

## Table of Contents
- [DevOps Day 56: Deploying a Scalable and Accessible Application in Kubernetes](#devops-day-56-deploying-a-scalable-and-accessible-application-in-kubernetes)
  - [Table of Contents](#table-of-contents)
    - [The Task](#the-task)
    - [My Step-by-Step Solution](#my-step-by-step-solution)
      - [Phase 1: Writing the Manifest File](#phase-1-writing-the-manifest-file)
      - [Phase 2: Applying the Manifest and Verifying](#phase-2-applying-the-manifest-and-verifying)
    - [Why Did I Do This? (The "What \& Why" for a K8s Beginner)](#why-did-i-do-this-the-what--why-for-a-k8s-beginner)
    - [Deep Dive: A Line-by-Line Explanation of My YAML Manifest](#deep-dive-a-line-by-line-explanation-of-my-yaml-manifest)
    - [Common Pitfalls for Beginners](#common-pitfalls-for-beginners)
    - [Exploring the Essential `kubectl` Commands](#exploring-the-essential-kubectl-commands)

---

### The Task
<a name="the-task"></a>
My objective was to create a scalable and accessible web server deployment. The specific requirements were:
1.  Create a **Deployment** named `nginx-deployment` using the `nginx:latest` image.
2.  The container inside the Pods had to be named `nginx-container`.
3.  The Deployment must run **3 replicas** (copies) of the application.
4.  Create a **Service** named `nginx-service` of type `NodePort`.
5.  The Service must expose the application on a `nodePort` of `30011`.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The professional way to create related resources in Kubernetes is to define them in a single YAML manifest file.

#### Phase 1: Writing the Manifest File
1.  I connected to the jump host.
2.  I created a new file named `nginx-app.yaml` using `vi`.
3.  Inside the editor, I wrote the following YAML code, using the `---` separator to define both the Deployment and the Service in one file.
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: nginx-deployment
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: nginx
      template:
        metadata:
          labels:
            app: nginx
        spec:
          containers:
          - name: nginx-container
            image: nginx:latest
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: nginx-service
    spec:
      type: NodePort
      selector:
        app: nginx
      ports:
        - protocol: TCP
          port: 80
          targetPort: 80
          nodePort: 30011
    ```
4.  I saved and quit the file.

#### Phase 2: Applying the Manifest and Verifying
1.  I used `kubectl` to send my manifest to the Kubernetes API server.
    ```bash
    kubectl apply -f nginx-app.yaml
    ```
    The command responded with `deployment.apps/nginx-deployment created` and `service/nginx-service created`.

2.  **Verification:** The final step was to confirm that both objects were created and working correctly.
    -   First, I checked the Deployment and the Pods it created.
        ```bash
        kubectl get deployment nginx-deployment
        kubectl get pods
        ```
        The first command showed `READY 3/3`, and the second command listed three separate `nginx-deployment-...` Pods, all in a `Running` state.
    -   For the definitive proof, I inspected the Service.
        ```bash
        kubectl get service nginx-service
        ```
    The output clearly showed a `TYPE` of `NodePort` and, most importantly, the port mapping `80:30011/TCP`. This confirmed that the Service was correctly exposing the application on the node's port 30011.

---

### Why Did I Do This? (The "What & Why" for a K8s Beginner)
<a name="why-did-i-do-this-the-what--why-for-a-k8s-beginner)"></a>
-   **Deployment**: A Deployment is the standard way to run a stateless application in Kubernetes. It's a controller that manages a set of identical Pods (replicas). Its key jobs are:
    -   **Scalability:** The `replicas: 3` line in my file told the Deployment I wanted three copies of my web server running at all times. This distributes the load and provides redundancy.
    -   **Self-Healing:** If one of my Nginx Pods were to crash, the Deployment controller would instantly detect it and automatically create a new Pod to replace it, ensuring my application stays available.
-   **Service**: A Service is a critical networking object that solves a huge problem: **Pods are ephemeral**. Pods can be created and destroyed by a Deployment, and every new Pod gets a new IP address. A **Service** provides a **single, stable endpoint** (a fixed IP address and DNS name) for a group of Pods.
-   **Labels and Selectors (The Magic Link)**: This is how the Service knows which Pods to send traffic to.
    1.  In my Deployment's Pod `template`, I gave each Pod a **Label**: `app: nginx`.
    2.  In my Service's `spec`, I defined a **Selector**: `app: nginx`.
    3.  Kubernetes continuously watches for all Pods that match the Service's selector and automatically updates the Service's list of endpoints with their IP addresses. This is how the two objects are connected.
-   **`NodePort` Service**: This is one of several ways to expose a Service to the outside world. When I create a `NodePort` service, Kubernetes does two things:
    1.  It still creates a stable internal IP address for the Service (the `ClusterIP`).
    2.  It also opens a specific port (the `nodePort`, `30011` in my case) on **every single Node** in the cluster. Any traffic that arrives at any Node's IP address on that port is then forwarded to the Service, which in turn load-balances it to one of the healthy Nginx Pods.

---

### Deep Dive: A Line-by-Line Explanation of My YAML Manifest
<a name="deep-dive-a-line-by-line-explanation-of-my-yaml-manifest"></a>
This file defines two separate but connected Kubernetes objects.

[Image of a Kubernetes NodePort Service directing traffic]

```yaml
# --- DEPLOYMENT DEFINITION ---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3 # I desire 3 identical copies of my Pod to be running.
  selector:
    matchLabels:
      app: nginx # This Deployment manages any Pod with the label 'app: nginx'.
  template: # This is the blueprint for the Pods.
    metadata:
      labels:
        app: nginx # This label is applied to each Pod created by this template. It MUST match the selector above.
    spec:
      containers:
      - name: nginx-container
        image: nginx:latest

# The '---' is a YAML separator that allows me to define another object in the same file.

# --- SERVICE DEFINITION ---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  # 'type: NodePort' tells Kubernetes to expose this service on a static port on each Node.
  type: NodePort
  
  # This is the crucial link. This Service will look for and send traffic to
  # any Pod that has the label 'app: nginx'.
  selector:
    app: nginx
    
  # This defines the port mapping for the Service.
  ports:
    - protocol: TCP
      # 'port' is the port on the Service's own internal ClusterIP.
      port: 80
      # 'targetPort' is the port on the Pods that the traffic should be sent to.
      targetPort: 80
      # 'nodePort' is the static port that will be opened on every Node in the cluster.
      nodePort: 30011
```

---

### Common Pitfalls for Beginners
<a name="common-pitfalls-for-beginners"></a>
-   **Selector/Label Mismatch:** This is the #1 error. If the `selector` in the Service does not exactly match the `labels` in the Deployment's Pod template, the Service will not be able to find any Pods, and its list of endpoints will be empty.
-   **Forgetting the `---` separator:** When defining multiple resources in one file, this separator is mandatory.
-   **`nodePort` Range:** The `nodePort` value is not arbitrary. It must be within a configurable range, which by default is **30000-32767**. Choosing a port outside this range will cause the Service creation to fail.
-   **`port` vs. `targetPort`:** It's easy to get these confused. `targetPort` is the port your container is listening on (port 80 for Nginx). `port` is the port the Service itself listens on within the cluster's internal network.

---

### Exploring the Essential `kubectl` Commands
<a name="exploring-the-essential-kubectl-commands"></a>
-   `kubectl apply -f [filename.yaml]`: The standard way to create or update resources from a manifest file.
-   `kubectl get all`: A great command to get a quick overview of all the major resources (Pods, Deployments, Services, etc.) in the current namespace.
-   `kubectl get deployment [dep-name]`: Gets a summary of a Deployment's status, showing the desired vs. current replica count.
-   `kubectl get service [svc-name]`: Gets a summary of a Service. This is the best way to see its `ClusterIP` and the `NodePort` mapping.
-   `kubectl describe service [svc-name]`: Describes a Service in detail. The most useful part of this output is the `Endpoints` field, which will show you the actual IP addresses of the Pods that the service is currently sending traffic to. If this is empty, you have a selector/label mismatch.
  