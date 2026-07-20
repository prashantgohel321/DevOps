# Kubernetes Level 01 Day 01: Deploying a Pod Using a Declarative Manifest

## Understanding Pod Creation Through a Declarative YAML File

Before creating anything in Kubernetes, it is important to understand that Kubernetes is not a system where we directly start containers. Instead, we describe what we want, and Kubernetes works continuously to make that desired state a reality.

When we create a Pod, we are not telling Kubernetes *how* to run it step by step. We are <mark><b>simply telling Kubernetes what we want</b></mark>. This approach is called the **declarative model**. The desired configuration is written inside a YAML file, and Kubernetes takes responsibility for translating that configuration into a running workload.

In this task, the objective is to create a Pod named `pod-httpd` that runs the Apache HTTP Server image `httpd:latest`. The Pod must also contain a label `app=httpd_app`, and the container inside the Pod must be explicitly named `httpd-container`.

At first glance, these requirements may look simple, but they introduce an important Kubernetes concept. While a Pod and a container are closely related, they are not the same thing. A Pod is the Kubernetes object that acts as a wrapper around one or more containers. Every container inside a Pod has its own name, and Kubernetes allows us to define those names explicitly. This is one of the reasons why a YAML manifest is preferred for such tasks, because it gives complete control over every part of the resource definition.

---

<br>
<br>

## Understanding the Structure of a Kubernetes Object

Every resource inside Kubernetes is represented as an object. Whether it is a Pod, Deployment, Service, ConfigMap, Secret, or Persistent Volume, all resources follow a common structure.

A Kubernetes object typically contains four major sections.

The first section is `apiVersion`. Kubernetes exposes many APIs, and different resources belong to different API groups and versions. The `apiVersion` field tells Kubernetes which API should process the object definition.

The second section is `kind`. This field tells Kubernetes what type of object is being created. In this case, the object type is a Pod.

The third section is `metadata`. Metadata contains information that identifies and describes the object. This is where names, labels, annotations, namespaces, and other identifying information are stored.

The final section is `spec`, which is short for specification. This is the most important part because it contains the desired state. The specification tells Kubernetes what containers should run, which images should be used, how much memory should be allocated, which volumes should be mounted, and many other runtime settings.

Whenever Kubernetes receives an object definition, it stores that desired state and continuously works to ensure that the actual state of the cluster matches what is defined in the specification.

---

<br>
<br>

## Creating the Pod Manifest

To create the Pod, a YAML file named `pod.yaml` can be created.

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

Although this file is very small, every line plays an important role.

The line `apiVersion: v1` tells Kubernetes to use the core API group. Pods belong to the core Kubernetes resources, so version `v1` is used.

The line `kind: Pod` tells the API server that the object being submitted is a Pod resource.

Inside the metadata section, the field `name: pod-httpd` assigns a unique name to the Pod within its namespace. Kubernetes uses this name as the primary identifier for the resource.

The labels section contains:

```yaml
app: httpd_app
```

A label is simply a key-value pair attached to a Kubernetes object. Labels do not directly affect how a Pod runs, but they become extremely important later when Services, ReplicaSets, Deployments, and monitoring tools need a way to identify and group resources.

Inside the specification section, the `containers` field defines the containers that will run inside the Pod.

Even though this Pod contains only one container, Kubernetes still expects the containers field to be a list because a Pod can contain multiple containers working together.

The line:

```yaml
name: httpd-container
```

defines the container name.

This is an important requirement because Kubernetes internally tracks containers by name. If the Pod is inspected later using commands like `kubectl describe`, this is the name that will appear.

The line:

```yaml
image: httpd:latest
```

tells Kubernetes which container image should be used.

The image `httpd` is the official Apache HTTP Server image available from Docker Hub. The tag `latest` refers to the most recent version available under that tag.

When Kubernetes eventually schedules the Pod onto a node, the node will pull this image and start a container from it.

---

<br>
<br>

## Applying the Manifest to the Cluster

Once the YAML file is ready, it can be submitted to Kubernetes using the following command.

```bash
kubectl apply -f pod.yaml
```

At first, this command looks very simple, but a lot happens internally after it is executed.

The `kubectl` command-line tool reads the YAML file and sends the object definition to the Kubernetes API Server.

The API Server is the central entry point of the entire Kubernetes control plane. Every request to create, modify, retrieve, or delete resources passes through it.

When the API Server receives the manifest, it first validates the structure of the YAML file. It checks whether all required fields are present and whether the resource definition follows Kubernetes rules.

If validation succeeds, the API Server stores the object definition inside **etcd**.

Etcd is Kubernetes' distributed key-value database. It serves as the single source of truth for the entire cluster. Every resource definition, configuration change, status update, and cluster state information is ultimately stored inside etcd.

At this stage, the Pod exists only as data inside the Kubernetes control plane. It is not yet running anywhere.

The Kubernetes Scheduler continuously watches for newly created Pods that do not have an assigned node. When it detects the new Pod, it evaluates available worker nodes and selects a suitable node based on resource availability and scheduling rules.

Once a node is selected, the scheduler updates the Pod object with the node assignment.

The kubelet running on that node then notices that a new Pod has been assigned to it.

The kubelet is the primary Kubernetes agent running on every node. Its responsibility is to ensure that containers described in Pod specifications are actually running.

The kubelet communicates with the container runtime, such as containerd or CRI-O, and instructs it to pull the required image.

If the image is not already present on the node, the container runtime downloads it from the container registry.

After the image download completes, the runtime creates the container, starts the Apache process, and reports the container status back to the kubelet.

The kubelet then updates the Pod status, and Kubernetes finally marks the Pod as running.

If everything succeeds, the command output will be:

```bash
pod/pod-httpd created
```

---

<br>
<br>

## Verifying the Pod

After creation, the Pod can be inspected using:

```bash
kubectl get pods -o wide
```

A typical output may look like:

```text
NAME        READY   STATUS    RESTARTS   AGE
pod-httpd   1/1     Running   0          10s
```

The READY column shows how many containers are operational inside the Pod.

Since this Pod contains one container and that container is healthy, the value becomes `1/1`.

The STATUS column indicates the current lifecycle state of the Pod.

Initially, Kubernetes may show:

```text
ContainerCreating
```

This state means the node is still downloading the image, creating networking resources, mounting volumes, or preparing the container environment.

After startup completes successfully, the status changes to:

```text
Running
```

which indicates that the container process is actively executing.

---

<br>
<br>

## Inspecting Detailed Pod Information

To view detailed information about the Pod, the following command can be used:

```bash
kubectl describe pod pod-httpd
```

This command provides a comprehensive view of the resource.

The output includes the Pod name, namespace, labels, assigned node, IP address, container information, mounted volumes, conditions, and event history.

When examining the container section, Kubernetes displays:

```text
Containers:
  httpd-container:
```

This confirms that the container name has been correctly configured.

The image field shows:

```text
Image: httpd:latest
```

which confirms that the correct image is being used.

The labels section shows:

```text
Labels:
  app=httpd_app
```

which verifies that the required label is attached to the Pod.

Further down in the output, Kubernetes also displays a chronological event history.

These events provide a real-time record of what happened during Pod creation.

Typical events include successful scheduling, image pulling, image download completion, container creation, and container startup.

Reading the event section is one of the most useful troubleshooting techniques because it reveals exactly where a failure occurred.

---

<br>
<br>

## Understanding the Pod Lifecycle Internally

When a Pod is created, Kubernetes moves it through a series of stages.

The API Server accepts the resource definition and stores it inside etcd.

The Scheduler detects an unscheduled Pod and selects an appropriate node.

The kubelet running on that node receives instructions to create the Pod.

The container runtime downloads the image if necessary.

The runtime creates the container environment and starts the application process.

The kubelet continuously monitors the container and reports its status back to the control plane.

This entire sequence usually completes within a few seconds.

If something goes wrong during image download, Kubernetes cannot start the container.

In such situations, the Pod status may become:

```text
ImagePullBackOff
```

This state indicates repeated image pull failures. Common causes include incorrect image names, invalid image tags, registry connectivity issues, or authentication problems.

To investigate such failures, the most useful command is:

```bash
kubectl describe pod pod-httpd
```

because the Events section usually reveals the exact reason.

---

<br>
<br>

## Understanding Labels and Their Importance

Labels may seem like simple metadata, but they are one of the most powerful concepts in Kubernetes.

A label is essentially a tag attached to an object.

In this Pod, the label is:

```yaml
app: httpd_app
```

Labels allow Kubernetes resources to discover and interact with one another.

For example, when a Service needs to route traffic to a group of Pods, it does not target Pod names directly. Instead, it uses label selectors.

This allows applications to scale dynamically without requiring configuration changes.

Pods with a specific label can be viewed using:

```bash
kubectl get pods -l app=httpd_app
```

Here, the `-l` flag applies a label selector and filters the output to show only matching Pods.

As Kubernetes environments grow larger, labels become the primary mechanism for organizing, grouping, monitoring, and targeting resources.

---

<br>
<br>

## Cleaning Up the Resource

When the Pod is no longer needed, it can be removed.

If the YAML file is available, the declarative way is:

```bash
kubectl delete -f pod.yaml
```

Alternatively, it can be deleted directly by name:

```bash
kubectl delete pod pod-httpd
```

Once deleted, Kubernetes removes the Pod object from the cluster and terminates the associated container.

An important concept to understand here is that this Pod is a standalone Pod. No higher-level controller is managing it.

Because of that, deleting the Pod permanently removes it.

If the Pod had been created by a Deployment, ReplicaSet, StatefulSet, or another controller, Kubernetes would automatically create a replacement Pod to maintain the desired state.

Since this Pod has no controller, deletion is final.

---

<br>
<br>

## Declarative vs Imperative Resource Creation

Kubernetes supports both imperative and declarative approaches.

An imperative approach means issuing commands that directly perform actions.

For example:

```bash
kubectl run pod-httpd \
  --image=httpd:latest \
  --labels="app=httpd_app"
```

This creates the Pod immediately.

However, imperative commands have limitations because complex configurations become difficult to manage and reproduce.

A useful compromise is generating a YAML template from an imperative command:

```bash
kubectl run pod-httpd \
  --image=httpd:latest \
  --labels="app=httpd_app" \
  --dry-run=client -o yaml > pod.yaml
```

This command does not create the Pod. Instead, it generates a YAML definition and saves it to a file.

However, the generated manifest would automatically set the container name to match the Pod name.

Therefore, manual editing would still be required to change the container name to:

```yaml
httpd-container
```

This is one of the reasons declarative manifests are preferred in real-world Kubernetes environments. They provide complete control over configuration, can be stored in version control systems, support auditing and change tracking, and fit naturally into Infrastructure as Code practices.

---

<br>
<br>

## Final Result

After completing this task, the Kubernetes cluster contains a Pod named `pod-httpd` running the `httpd:latest` image inside a container called `httpd-container`. The Pod carries the label `app=httpd_app`, making it identifiable through label selectors and ready for future integration with Services, Deployments, and other Kubernetes resources.

More importantly, this exercise demonstrates the complete lifecycle of Kubernetes object creation. A simple YAML file travels through the API Server, gets stored in etcd, is processed by the Scheduler, executed by the kubelet, and ultimately becomes a running container on a cluster node. Understanding this flow is fundamental because the same architecture and control loop pattern applies to almost every resource that exists in Kubernetes.
