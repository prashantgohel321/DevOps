# DevOps Day 65: Deploying a Configured Redis Cache on Kubernetes

Today's task was a fantastic, real-world example of deploying a stateful service—a Redis cache—on Kubernetes. This went far beyond just running a container; I had to manage its configuration externally using a **ConfigMap**, provide it with storage volumes, and define its resource requirements.

This was a brilliant exercise that taught me how to take an off-the-shelf Docker image (`redis:alpine`) and customize its runtime behavior without modifying the image itself. I learned how to create a ConfigMap, mount it as a file into a Pod, and override the container's startup command to use that new configuration file. This document is my very detailed, first-person guide to that entire process, written for a Kubernetes beginner.

## Table of Contents
- [DevOps Day 65: Deploying a Configured Redis Cache on Kubernetes](#devops-day-65-deploying-a-configured-redis-cache-on-kubernetes)
  - [Table of Contents](#table-of-contents)
    - [The Task](#the-task)
    - [My Step-by-Step Solution](#my-step-by-step-solution)
      - [Phase 1: Creating the ConfigMap](#phase-1-creating-the-configmap)
      - [Phase 2: Writing the Deployment Manifest](#phase-2-writing-the-deployment-manifest)
      - [Phase 3: Applying the Manifest and Verifying](#phase-3-applying-the-manifest-and-verifying)
    - [Why Did I Do This? (The "What \& Why" for a K8s Beginner)](#why-did-i-do-this-the-what--why-for-a-k8s-beginner)
    - [Deep Dive: A Line-by-Line Explanation of My Deployment YAML](#deep-dive-a-line-by-line-explanation-of-my-deployment-yaml)
    - [Common Pitfalls for Beginners](#common-pitfalls-for-beginners)
    - [Exploring the Essential `kubectl` Commands](#exploring-the-essential-kubectl-commands)

---

### The Task
<a name="the-task"></a>
My objective was to deploy a customized Redis instance using a Kubernetes Deployment. The specific requirements were:
1.  Create a **ConfigMap** named `my-redis-config` containing a key `redis-config` with the value `maxmemory 2mb`.
2.  Create a **Deployment** named `redis-deployment` with 1 replica and the label `app: redis`.
3.  The container had to be named `redis-container`, use the `redis:alpine` image, and request `1` CPU.
4.  It required two volumes:
    -   An `emptyDir` volume named `data` mounted at `/redis-master-data`.
    -   A `ConfigMap` volume named `redis-config` (using the ConfigMap I created) mounted at `/redis-master`.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The solution involved an imperative command to create the ConfigMap and a declarative manifest to create the Deployment that uses it.

#### Phase 1: Creating the ConfigMap
First, I needed to create the configuration object that my Redis container would later consume.
1.  I connected to the jump host.
2.  I used a single, imperative `kubectl create configmap` command to generate the ConfigMap with the required key-value data.
    ```bash
    kubectl create configmap my-redis-config --from-literal=redis-config="maxmemory 2mb"
    ```
    The command responded with `configmap/my-redis-config created`.

#### Phase 2: Writing the Deployment Manifest
1.  I created a new file named `redis-deployment.yaml` using `vi`.
2.  Inside the editor, I wrote the following YAML code. This defines the Deployment, its container, the volumes, and critically, overrides the container's command to use my custom config.
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: redis-deployment
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: redis
      template:
        metadata:
          labels:
            app: redis
        spec:
          containers:
          - name: redis-container
            image: redis:alpine
            command: ["redis-server"]
            args: ["/redis-master/redis-config"]
            ports:
            - containerPort: 6379
            resources:
              requests:
                cpu: "1"
            volumeMounts:
            - name: data
              mountPath: /redis-master-data
            - name: redis-config
              mountPath: /redis-master
          volumes:
          - name: data
            emptyDir: {}
          - name: redis-config
            configMap:
              name: my-redis-config
    ```
3.  I saved and quit the file.

#### Phase 3: Applying the Manifest and Verifying
1.  I used `kubectl` to create the Deployment from my manifest.
    ```bash
    kubectl apply -f redis-deployment.yaml
    ```
2.  **Verification:** The final part of the task was to prove that the Redis server was actually using my custom configuration.
    -   First, I checked that the Pod was `Running` with `kubectl get pods`.
    -   **This was the definitive proof:** I `exec`'d into the running container and used the Redis command-line interface (`redis-cli`) to inspect its live configuration.
        ```bash
        # Get the full name of the pod
        POD_NAME=$(kubectl get pods -l app=redis -o jsonpath='{.items[0].metadata.name}')
        # Exec into the pod and run redis-cli
        kubectl exec -it $POD_NAME -- redis-cli
        ```
    -   Inside the Redis prompt, I ran the command:
        ```
        127.0.0.1:6379> CONFIG GET maxmemory
        ```
    The output was `2097152` (2 megabytes), which proved that my `maxmemory 2mb` setting from the ConfigMap was successfully loaded and applied by the Redis server.

---

### Why Did I Do This? (The "What & Why" for a K8s Beginner)
<a name="why-did-i-do-this-the-what--why-for-a-k8s-beginner)"></a>
-   **Redis**: Redis is an extremely fast, in-memory key-value data store. It's most commonly used as a **cache** to speed up applications by reducing the load on slower, disk-based databases. It's also used for real-time analytics, session management, and as a message broker.
-   **ConfigMap Volume**: This is a core Kubernetes pattern for **decoupling configuration from your application image**.
    -   **The Problem:** I could have built a custom Docker image with a `redis.conf` file inside it, but what if I need to change the `maxmemory` setting later? I would have to rebuild the entire image.
    -   **The Solution:** I stored my configuration (`maxmemory 2mb`) in a Kubernetes **ConfigMap**. Then, I told my Pod to mount this ConfigMap as a volume. Kubernetes creates a file named `redis-config` (the key from the ConfigMap) inside the `/redis-master` directory in my container. This way, I can update the ConfigMap in the cluster, and the new configuration will be available to the Pod without needing an image rebuild.
-   **Overriding Container `command` and `args`**: This was the crucial step to make the ConfigMap useful. The default `redis:alpine` image just runs the `redis-server` command. By setting the `command` and `args` in my Pod spec, I overrode that default. I told the container to run `redis-server /redis-master/redis-config`, which explicitly instructs the Redis server to start up using my custom configuration file.

---

### Deep Dive: A Line-by-Line Explanation of My Deployment YAML
<a name="deep-dive-a-line-by-line-explanation-of-my-deployment-yaml"></a>
This YAML manifest is a great example of how to configure a custom application.

[Image of a Kubernetes Deployment with ConfigMap and emptyDir volumes]

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis-container
        image: redis:alpine
        
        # This 'command' and 'args' block overrides the image's default startup command.
        # It tells the container to run the 'redis-server' executable...
        command: ["redis-server"]
        # ...and to pass '/redis-master/redis-config' as an argument to it.
        # This instructs Redis to load our custom config file.
        args: ["/redis-master/redis-config"]

        ports:
        - containerPort: 6379 # The default Redis port.
        
        # This block defines the resource requests for the container.
        resources:
          requests:
            cpu: "1" # Requesting 1 full CPU core.
            
        # This block defines where to mount the volumes inside the container.
        volumeMounts:
        - name: data # This name must match a volume below.
          mountPath: /redis-master-data
        - name: redis-config # This name must match a volume below.
          mountPath: /redis-master

      # This block defines the volumes that are available to this Pod.
      volumes:
      # The first volume is a temporary scratch space.
      - name: data
        emptyDir: {}
      # The second volume's source is our ConfigMap.
      - name: redis-config
        configMap:
          # This must be the name of the ConfigMap I created earlier.
          name: my-redis-config
```

---

### Common Pitfalls for Beginners
<a name="common-pitfalls-for-beginners"></a>
-   **Forgetting to Override the Command:** If I had forgotten the `command` and `args` block, the Redis container would have started, but it would have used its default, built-in configuration, ignoring my `maxmemory` setting completely.
-   **ConfigMap Name Mismatch:** A typo in the `configMap.name` in the Deployment's `volumes` section would cause the Pod to fail to start with a `CreateContainerConfigError` because it couldn't find the specified ConfigMap.
-   **Key/File Mismatch:** The `args` path (`/redis-master/redis-config`) works because the volume is mounted at `/redis-master` and the key in the ConfigMap is `redis-config`. If the key in the ConfigMap was different, the filename inside the container would be different, and the `redis-server` command would fail.
-   **`exec` into the wrong tool:** For my verification, I had to use `redis-cli`, the specific client for Redis. Just getting a shell (`/bin/bash`) would not have been enough to query the live configuration.

---

### Exploring the Essential `kubectl` Commands
<a name="exploring-the-essential-kubectl-commands"></a>
-   `kubectl create configmap [name] --from-literal=[key]=[value]`: An imperative command to create a ConfigMap directly from a key-value pair on the command line. This is very fast for simple configurations.
-   `kubectl apply -f [filename.yaml]`: The standard way to create or update resources from a manifest file.
-   `kubectl get pods` / `kubectl get deployment`: My high-level tools to check the overall status.
-   `kubectl describe pod [pod-name]`: My primary tool for troubleshooting startup issues. It would have shown me errors if the ConfigMap volume failed to mount.
-   `kubectl exec -it [pod-name] -- redis-cli`: The most important verification command. It gave me an **i**nteractive **t**erminal with the `redis-cli` tool inside my running container, allowing me to directly query the live application's state.
  