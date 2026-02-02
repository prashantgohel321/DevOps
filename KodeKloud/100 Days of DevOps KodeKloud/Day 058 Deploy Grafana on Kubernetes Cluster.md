# DevOps Day 58: Deploying a Grafana Instance on Kubernetes

Today's task was a fantastic, real-world application of the Kubernetes concepts I've been learning. My objective was to deploy a Grafana instance, a popular open-source monitoring and analytics tool. This required me to create both a **Deployment** to manage the application's lifecycle and a **Service** to make it accessible from outside the cluster.

This exercise was the perfect way to solidify my understanding of how to run a complete, scalable, and accessible application on Kubernetes. I learned how to define both of these critical objects in a single YAML file and how the "label-selector" mechanism magically links them together. This document is my very detailed, first-person guide to that entire process, written from the perspective of a Kubernetes beginner.

## Table of Contents
- [DevOps Day 58: Deploying a Grafana Instance on Kubernetes](#devops-day-58-deploying-a-grafana-instance-on-kubernetes)
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
My objective was to deploy a Grafana instance and make it accessible. The specific requirements were:
1.  Create a **Deployment** named `grafana-deployment-devops` using a Grafana image.
2.  Create a **Service** to expose the application using a `NodePort` of `32000`.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The professional way to create related Kubernetes resources is to define them in a single YAML manifest file.

#### Phase 1: Writing the Manifest File
1.  I connected to the jump host.
2.  I created a new file named `grafana-app.yaml` using `vi`.
3.  Inside the editor, I wrote the following YAML code, using the `---` separator to define both the Deployment and the Service in one file.
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: grafana-deployment-devops
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: grafana
      template:
        metadata:
          labels:
            app: grafana
        spec:
          containers:
          - name: grafana
            image: grafana/grafana:latest
            ports:
            - containerPort: 3000
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: grafana-service
    spec:
      type: NodePort
      selector:
        app: grafana
      ports:
        - protocol: TCP
          port: 3000
          targetPort: 3000
          nodePort: 32000
    ```
4.  I saved and quit the file.

#### Phase 2: Applying the Manifest and Verifying
1.  I used `kubectl` to send my manifest to the Kubernetes API server.
    ```bash
    kubectl apply -f grafana-app.yaml
    ```
    The command responded with `deployment.apps/grafana-deployment-devops created` and `service/grafana-service created`.

2.  **Verification:** The final step was to confirm that both objects were created and working correctly.
    -   First, I checked that the Deployment had successfully created its Pod.
        ```bash
        kubectl get deployment grafana-deployment-devops
        kubectl get pods
        ```
        The first command showed `READY 1/1`, and the second command listed a `grafana-deployment-devops-...` Pod in a `Running` state.
    -   For the definitive proof, I inspected the Service.
        ```bash
        kubectl get service grafana-service
        ```
    The output clearly showed a `TYPE` of `NodePort` and the port mapping `3000:32000/TCP`. This confirmed that the Service was correctly exposing the application on the node's port 32000. Finally, accessing the Grafana login page via the lab's UI button was the ultimate confirmation of success.

---

### Why Did I Do This? (The "What & Why" for a K8s Beginner)
<a name="why-did-i-do-this-the-what--why-for-a-k8s-beginner)"></a>
-   **Deployment**: A Deployment is the standard way to run a stateless application in Kubernetes. It's a controller that manages a set of identical Pods (replicas). Its key jobs are:
    -   **Scalability:** I can easily scale my Grafana instance by changing the `replicas` count.
    -   **Self-Healing:** If my Grafana Pod were to crash, the Deployment controller would instantly detect it and automatically create a new Pod to replace it, ensuring my monitoring dashboard stays available.
-   **Service**: A Service is a critical networking object that solves a huge problem: **Pods are ephemeral**. Pods can be created and destroyed by a Deployment, and every new Pod gets a new IP address. A **Service** provides a **single, stable endpoint** (a fixed IP address and DNS name) for a group of Pods.
-   **Labels and Selectors (The Magic Link)**: This is how the Service knows which Pods to send traffic to.
    1.  In my Deployment's Pod `template`, I gave each Pod a **Label**: `app: grafana`.
    2.  In my Service's `spec`, I defined a **Selector**: `app: grafana`.
    3.  Kubernetes continuously watches for all Pods that match the Service's selector and automatically updates the Service's list of endpoints with their IP addresses. This is how the two objects are connected.
-   **`NodePort` Service**: This is one of several ways to expose a Service to the outside world. When I create a `NodePort` service, Kubernetes does two things:
    1.  It still creates a stable internal IP address for the Service (the `ClusterIP`).
    2.  It also opens a specific port (the `nodePort`, `32000` in my case) on **every single Node** in the cluster. Any traffic that arrives at any Node's IP address on that port is then forwarded to the Service, which in turn load-balances it to one of the healthy Grafana Pods.

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
  name: grafana-deployment-devops
spec:
  replicas: 1 # I desire 1 copy of my Pod to be running.
  selector:
    matchLabels:
      app: grafana # This Deployment manages any Pod with the label 'app: grafana'.
  template: # This is the blueprint for the Pods.
    metadata:
      labels:
        app: grafana # This label is applied to each Pod. It MUST match the selector above.
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:latest
        # This tells Kubernetes that the container listens on port 3000.
        # It's good practice and helps with service discovery.
        ports:
        - containerPort: 3000

# The '---' is a YAML separator that allows me to define another object in the same file.

# --- SERVICE DEFINITION ---
apiVersion: v1
kind: Service
metadata:
  name: grafana-service
spec:
  # 'type: NodePort' tells Kubernetes to expose this service on a static port on each Node.
  type: NodePort
  
  # This is the crucial link. This Service will look for and send traffic to
  # any Pod that has the label 'app: grafana'.
  selector:
    app: grafana
    
  # This defines the port mapping for the Service.
  ports:
    - protocol: TCP
      # 'port' is the port on the Service's own internal ClusterIP.
      port: 3000
      # 'targetPort' is the port on the Pods that the traffic should be sent to.
      # This must match the 'containerPort' in the Deployment.
      targetPort: 3000
      # 'nodePort' is the static port that will be opened on every Node in the cluster.
      nodePort: 32000
```

---

### Common Pitfalls for Beginners
<a name="common-pitfalls-for-beginners"></a>
-   **Selector/Label Mismatch:** This is the #1 error. If the `selector` in the Service does not exactly match the `labels` in the Deployment's Pod template, the Service will not be able to find any Pods, and its list of endpoints will be empty.
-   **`port` vs. `targetPort` vs. `nodePort`:** It's easy to get these confused.
    -   `targetPort`: The port your container is actually listening on (3000 for Grafana).
    -   `port`: The port the Service itself listens on *inside* the cluster's private network.
    -   `nodePort`: The high-numbered port that is opened on the physical server to expose the service externally.
-   **`nodePort` Range:** The `nodePort` value is not arbitrary. It must be within a configurable range, which by default is **30000-32767**. Choosing a port outside this range will cause the Service creation to fail.

---

### Exploring the Essential `kubectl` Commands
<a name="exploring-the-essential-kubectl-commands"></a>
-   `kubectl apply -f [filename.yaml]`: The standard way to create or update resources from a manifest file.
-   `kubectl get all`: A great command to get a quick overview of all the major resources (Pods, Deployments, Services, etc.).
-   `kubectl get deployment [dep-name]`: Gets a summary of a Deployment's status.
-   `kubectl get service [svc-name]`: Gets a summary of a Service. This is the best way to see its `ClusterIP` and the `NodePort` mapping.
-   `kubectl describe service [svc-name]`: Describes a Service in detail. The most useful part of this output is the `Endpoints` field, which will show you the actual IP addresses of the Pods that the service is currently sending traffic to. If this is empty, you have a selector/label mismatch.
   