# Kubernetes Level 01 Day 01: Deploying a Pod Using a Declarative Manifest

This document explains how a Pod was deployed in a Kubernetes cluster using a declarative YAML manifest. The objective was to create a Pod with a specific name, label, image, and most importantly, a custom container name. While Kubernetes allows quick creation of resources using imperative commands, this task required precise control over configuration, which makes a YAML-based approach necessary.

The Pod to be created must satisfy the following conditions:

* Pod name: `pod-httpd`
* Image: `httpd:latest`
* Label: `app=httpd_app`
* Container name: `httpd-container`

The container name requirement is important because `kubectl run` automatically assigns the container name equal to the Pod name unless explicitly overridden via a manifest.

---

<br>
<br>

- [Kubernetes Level 01 Day 01: Deploying a Pod Using a Declarative Manifest](#kubernetes-level-01-day-01-deploying-a-pod-using-a-declarative-manifest)
  - [Understanding the Kubernetes Object Model Before Creation](#understanding-the-kubernetes-object-model-before-creation)
  - [Step 1: Create the YAML Manifest](#step-1-create-the-yaml-manifest)
    - [Breakdown of Each Section](#breakdown-of-each-section)
  - [Step 2: Apply the Configuration to the Cluster](#step-2-apply-the-configuration-to-the-cluster)
  - [Step 3: Verify Pod Deployment and Configuration](#step-3-verify-pod-deployment-and-configuration)
  - [Observing Pod Lifecycle Internally](#observing-pod-lifecycle-internally)
  - [Inspecting Labels and Selectors](#inspecting-labels-and-selectors)
  - [Cleaning Up the Resource](#cleaning-up-the-resource)
  - [Declarative vs Imperative Creation](#declarative-vs-imperative-creation)
  - [Final State](#final-state)


<br>
<br>

## Understanding the Kubernetes Object Model Before Creation

In Kubernetes, every resource is defined as an object. A Pod is the smallest deployable unit and represents one or more containers scheduled together on a node.

Each Kubernetes object definition contains four essential sections:

* `apiVersion`: Defines which Kubernetes API version to use.
* `kind`: Specifies the resource type.
* `metadata`: Stores identifying information such as name and labels.
* `spec`: Contains the desired configuration state.

When a YAML file is applied, Kubernetes compares the desired state in the manifest with the cluster’s current state. If the resource does not exist, it is created. If it exists, Kubernetes attempts to reconcile differences.

---

<br>
<br>

## Step 1: Create the YAML Manifest

Create a file named `pod.yaml`.

```bash
vi pod.yaml
```

Insert the following content.

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

### Breakdown of Each Section

`apiVersion: v1` indicates that we are using the core Kubernetes API group.

`kind: Pod` tells the Kubernetes API server that we want to create a Pod object.

Inside `metadata`, the `name` uniquely identifies the Pod inside its namespace. The `labels` field assigns key-value metadata that can later be used for selection, filtering, or grouping.

Inside `spec`, the `containers` array defines one or more containers that will run inside the Pod. Even for a single container, this field must be structured as a list. The `name` under containers sets the internal container identifier. The `image` specifies which container image will be pulled from the configured registry.

By defining the container name explicitly as `httpd-container`, we satisfy the task requirement that would not be met with a simple `kubectl run` command.

---

<br>
<br>

## Step 2: Apply the Configuration to the Cluster

Once the manifest is ready, use the following command.

```bash
kubectl apply -f pod.yaml
```

This command sends the object definition to the Kubernetes API server. The API server stores the desired state in etcd, which is the cluster’s distributed key-value store.

The scheduler then assigns the Pod to a suitable node based on available resources. After scheduling, the kubelet on that node pulls the container image and starts the container runtime.

Expected output:

```
pod/pod-httpd created
```

---

<br>
<br>

## Step 3: Verify Pod Deployment and Configuration

Check whether the Pod is created and observe its status.

```bash
kubectl get pods -o wide
```

```text

NAME        READY   STATUS    RESTARTS   AGE   IP           NODE                      NOMINATED NODE   READINESS GATES
pod-httpd   1/1     Running   0          10s   10.244.0.5   kodekloud-control-plane   <none>           <none>

```

Initially, the status may show `ContainerCreating` while the image is being pulled. Once ready, it should show `Running`.

To inspect detailed configuration and confirm container name and labels:

```bash
kubectl describe pod pod-httpd
```

```text

Name:             pod-httpd
Namespace:        default
Priority:         0
Service Account:  default
Node:             kodekloud-control-plane/172.17.0.2
Start Time:       Sat, 14 Feb 2026 05:06:23 +0000
Labels:           app=httpd_app
Annotations:      <none>
Status:           Running
IP:               10.244.0.5
IPs:
  IP:  10.244.0.5
Containers:
  httpd-container:
    Container ID:   containerd://3d4ca4c14242d0e63a97fe0699580e290c8fd2a2657aa7151e0258d22f816933
    Image:          httpd:latest
    Image ID:       docker.io/library/httpd@sha256:b89c19a390514d6767e8c62f29375d0577190be448f63b24f5f11d6b03f7bf18
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Sat, 14 Feb 2026 05:06:29 +0000
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-r8d8z (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             True 
  ContainersReady   True 
  PodScheduled      True
Volumes:
  kube-api-access-r8d8z:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  20s   default-scheduler  Successfully assigned default/pod-httpd to kodekloud-control-plane
  Normal  Pulling    19s   kubelet            Pulling image "httpd:latest"
  Normal  Pulled     14s   kubelet            Successfully pulled image "httpd:latest" in 5.029996784s (5.030014421s including waiting)
  Normal  Created    14s   kubelet            Created container httpd-container
  Normal  Started    14s   kubelet            Started container httpd-container

```

Verify the following:

* Pod name matches `pod-httpd`
* Label `app=httpd_app` is present
* Container name is `httpd-container`
* Image is `httpd:latest`

For structured inspection using JSONPath:

```bash
kubectl get pod pod-httpd -o jsonpath='{.spec.containers[0].name}'
```

This confirms the container name programmatically.

---

<br>
<br>

## Observing Pod Lifecycle Internally

When the manifest is applied, the following internal sequence occurs:

1. The API server validates the YAML schema.
2. The desired state is stored in etcd.
3. The scheduler selects a node.
4. The kubelet on that node pulls the `httpd:latest` image.
5. The container runtime creates and runs the container.

If the image pull fails, the Pod status changes to `ImagePullBackOff`. This can be diagnosed using:

```bash
kubectl describe pod pod-httpd
```

---

<br>
<br>

## Inspecting Labels and Selectors

Labels are critical for grouping and service targeting. To filter Pods by label:

```bash
kubectl get pods -l app=httpd_app
```

Labels become especially important when creating Services, ReplicaSets, or Deployments.

---

<br>
<br>

## Cleaning Up the Resource

If you need to remove the Pod:

```bash
kubectl delete -f pod.yaml
```

Or directly by name:

```bash
kubectl delete pod pod-httpd
```

Deleting the Pod removes it permanently because standalone Pods are not self-healing. If a Pod managed by a controller is deleted, it would be recreated automatically. Since this Pod is standalone, deletion is final.

---

<br>
<br>

## Declarative vs Imperative Creation

An imperative shortcut could be used to generate a base manifest.

```bash
kubectl run pod-httpd --image=httpd:latest --labels="app=httpd_app" --dry-run=client -o yaml > pod.yaml
```

However, this generated YAML would set the container name to `pod-httpd`. Manual modification is required to rename it to `httpd-container`.

Declarative YAML files are preferred in production environments because they are version-controlled, auditable, reproducible, and support infrastructure-as-code practices.

---

<br>
<br>

## Final State

At completion of this task:

* The Pod `pod-httpd` exists in the cluster
* It runs a container named `httpd-container`
* The image `httpd:latest` is deployed
* The label `app=httpd_app` is attached
* The configuration is stored declaratively in `pod.yaml`

This establishes the foundational understanding of Kubernetes object creation using declarative configuration, which is the standard method in real-world cluster management.
