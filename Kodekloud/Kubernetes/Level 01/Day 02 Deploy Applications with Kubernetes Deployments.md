# Kubernetes Level 01 Day 02: Managing Applications Using Deployments

This document explains how a Kubernetes Deployment was created to manage the `httpd` application. Unlike standalone Pods, Deployments introduce lifecycle control, self-healing behavior, and controlled updates. The objective was to create a Deployment named `httpd` using the image `httpd:latest`, explicitly specifying the image tag.

Understanding Deployments is essential because they represent how real-world applications are managed in Kubernetes environments. A Deployment does not directly run containers. Instead, it manages ReplicaSets, and ReplicaSets manage Pods. This layered structure allows Kubernetes to maintain the desired state automatically.

---

<br>
<br>

- [Kubernetes Level 01 Day 02: Managing Applications Using Deployments](#kubernetes-level-01-day-02-managing-applications-using-deployments)
  - [Understanding the Shift from Pod to Deployment](#understanding-the-shift-from-pod-to-deployment)
  - [Method 1: Imperative Creation (Quick Approach)](#method-1-imperative-creation-quick-approach)
  - [Method 2: Declarative YAML Definition (Infrastructure as Code)](#method-2-declarative-yaml-definition-infrastructure-as-code)
    - [Breakdown of Key Sections](#breakdown-of-key-sections)
  - [Verifying the Deployment and Its Components](#verifying-the-deployment-and-its-components)
  - [Demonstrating Self-Healing Behavior](#demonstrating-self-healing-behavior)
  - [Scaling the Deployment](#scaling-the-deployment)
  - [Updating the Application Image](#updating-the-application-image)
  - [Internal Mechanics of Deployments](#internal-mechanics-of-deployments)
  - [Cleaning Up Resources](#cleaning-up-resources)
  - [Final State After Completion](#final-state-after-completion)


<br>
<br>

## Understanding the Shift from Pod to Deployment

When a standalone Pod is created, it runs once. If it crashes or is deleted, Kubernetes does not recreate it automatically unless it is managed by a higher-level controller. A Deployment acts as that controller.

A Deployment defines:

* How many replicas should exist
* What container image should be used
* What labels should identify the Pods
* How updates should be rolled out

Once created, Kubernetes continuously compares actual state with desired state and reconciles differences.

---

<br>
<br>

## Method 1: Imperative Creation (Quick Approach)

For simple scenarios, the imperative command can create the Deployment directly.

```bash
kubectl create deployment httpd --image=httpd:latest

# deployment.apps/httpd created

```

This command instructs the Kubernetes API server to create a Deployment named `httpd` using the specified container image.

Internally, the following occurs:

1. The API server stores the Deployment object.
2. The Deployment controller creates a ReplicaSet.
3. The ReplicaSet creates one Pod by default.
4. The scheduler assigns the Pod to a node.
5. The kubelet pulls the image and starts the container.

By default, this command sets the replica count to 1.

To inspect the generated configuration:

```bash
kubectl get deployment httpd -o yaml
```

This allows observation of the auto-generated selector and Pod template.

---

<br>
<br>

## Method 2: Declarative YAML Definition (Infrastructure as Code)

For controlled, repeatable environments, a YAML manifest is preferred.

Create a file named `deployment.yaml`.

```bash
vi deployment.yaml
```

Insert the following content.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpd
spec:
  replicas: 1
  selector:
    matchLabels:
      app: httpd
  template:
    metadata:
      labels:
        app: httpd
    spec:
      containers:
      - name: httpd
        image: httpd:latest
```

### Breakdown of Key Sections

`apiVersion: apps/v1` specifies that this resource belongs to the `apps` API group, which manages higher-level workload controllers.

`kind: Deployment` defines the resource type.

`spec.replicas` determines how many Pod replicas should exist simultaneously.

`selector.matchLabels` defines how the Deployment identifies the Pods it controls. This must match the labels defined in the Pod template.

`template` describes what the Pods should look like. The labels inside the template must align with the selector; otherwise, the Deployment cannot associate with its Pods.

Apply the configuration:

```bash
kubectl apply -f deployment.yaml
```

---

<br>
<br>

## Verifying the Deployment and Its Components

Check the Deployment status.

```bash
kubectl get deployments

# OUTPUT
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
httpd   1/1     1            1           8s

```

The output should display the Deployment name with a READY count of `1/1`.

Check ReplicaSets:

```bash
kubectl get replicasets
```

You will see a ReplicaSet automatically created by the Deployment.

Check Pods:

```bash
kubectl get pods

# OUTPUT
NAME                     READY   STATUS    RESTARTS   AGE
httpd-69545969bd-vlq5q   1/1     Running   0          17s
```

The Pod name will have a format similar to:

```
httpd-6d4c598dbb-xxxxx
```

The first segment is the Deployment name, the second is a hash derived from the Pod template, and the final segment is a unique identifier for the replica.

To trace ownership relationships:

```bash
kubectl describe pod <pod-name>
```

You will observe that the Pod is controlled by a ReplicaSet, which in turn is controlled by the Deployment.

---

<br>
<br>

## Demonstrating Self-Healing Behavior

Delete a running Pod managed by the Deployment.

```bash
kubectl delete pod <pod-name>
```

Immediately check Pods again:

```bash
kubectl get pods
```

A new Pod will be created automatically. This occurs because the ReplicaSet constantly ensures that the number of replicas matches the desired count defined in the Deployment.

---

<br>
<br>

## Scaling the Deployment

Increase the replica count.

```bash
kubectl scale deployment httpd --replicas=3
```

Verify:

```bash
kubectl get pods
```

You should now see three running Pods.

Alternatively, update the YAML file and reapply.

```yaml
spec:
  replicas: 3
```

Then run:

```bash
kubectl apply -f deployment.yaml
```

Kubernetes reconciles the desired state and creates additional Pods.

---

<br>
<br>

## Updating the Application Image

To simulate an update:

```bash
kubectl set image deployment/httpd httpd=httpd:2.4
```

This triggers a rolling update. Kubernetes creates new Pods with the updated image while gradually terminating old ones.

Monitor rollout progress:

```bash
kubectl rollout status deployment/httpd
```

To view rollout history:

```bash
kubectl rollout history deployment/httpd
```

---

<br>
<br>

## Internal Mechanics of Deployments

A Deployment manages ReplicaSets through a reconciliation loop. When an update to the Pod template occurs, Kubernetes creates a new ReplicaSet with the updated specification. The old ReplicaSet is scaled down while the new one is scaled up according to the rolling update strategy.

This design ensures zero-downtime updates if configured properly and provides rollback capability in case of failures.

---

<br>
<br>

## Cleaning Up Resources

To remove the Deployment and all associated resources:

```bash
kubectl delete deployment httpd
```

Deleting the Deployment automatically deletes its ReplicaSets and Pods.

---

<br>
<br>

## Final State After Completion

At the end of this task:

* A Deployment named `httpd` exists
* It manages a ReplicaSet
* The ReplicaSet manages one or more Pods
* The Pods run the container image `httpd:latest`
* Self-healing and scaling capabilities are active

This transition from standalone Pods to Deployments establishes the foundation for production-ready application management in Kubernetes.
