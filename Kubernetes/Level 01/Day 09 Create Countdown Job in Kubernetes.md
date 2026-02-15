# Kubernetes Level 01 – Day 09: Run Jobs in Kubernetes

This document explains how to create and manage a Kubernetes Job. Unlike Deployments or ReplicaSets that maintain continuously running applications, a Job is designed to execute a task once and ensure it completes successfully.

---

<br>
<br>

- [Kubernetes Level 01 – Day 09: Run Jobs in Kubernetes](#kubernetes-level-01--day-09-run-jobs-in-kubernetes)
  - [Objective](#objective)
- [Understanding the Purpose of a Job](#understanding-the-purpose-of-a-job)
- [Step 1: Create the YAML Manifest](#step-1-create-the-yaml-manifest)
    - [Manifest Content](#manifest-content)
    - [Important Configuration Details](#important-configuration-details)
- [Step 2: Apply the Configuration](#step-2-apply-the-configuration)
- [Step 3: Verification](#step-3-verification)
  - [Check Job Status](#check-job-status)
  - [Check Pods](#check-pods)
- [How Jobs Work Internally](#how-jobs-work-internally)
- [Restart Policy for Jobs](#restart-policy-for-jobs)
- [Job vs Deployment vs CronJob](#job-vs-deployment-vs-cronjob)
- [Key Outcome](#key-outcome)


<br>
<br>

## Objective

Create a Job with the following configuration:

* **Job Name:** `countdown-nautilus`
* **Pod Template Name:** `countdown-nautilus`
* **Container Name:** `container-countdown-nautilus`
* **Image:** `fedora:latest`
* **Command:** `sleep 5`
* **Restart Policy:** `Never`

---

<br>
<br>

# Understanding the Purpose of a Job

A Job in Kubernetes is used for tasks that must run to completion. Examples include database migrations, batch processing, report generation, and backup operations.

Unlike a Deployment, which keeps Pods running indefinitely, a Job:

* Creates a Pod
* Runs the defined task
* Waits for successful completion
* Stops after success

Kubernetes ensures the task completes at least once.

---

<br>
<br>

# Step 1: Create the YAML Manifest

Create a manifest file:

```bash
vi job.yaml
```

### Manifest Content

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: countdown-nautilus
spec:
  template:
    metadata:
      name: countdown-nautilus
    spec:
      containers:
      - name: container-countdown-nautilus
        image: fedora:latest
        command: ["sleep", "5"]
      restartPolicy: Never
```

### Important Configuration Details

* `apiVersion: batch/v1` → Job belongs to the batch API group
* `kind: Job` → Defines a one-time execution controller
* `spec.template` → Pod template used by the Job
* `command: ["sleep", "5"]` → Container runs for 5 seconds
* `restartPolicy: Never` → Do not restart the container inside the same Pod if it exits

The Job controller monitors the Pod status. If the Pod exits successfully (exit code 0), the Job is marked as complete.

---

<br>
<br>

# Step 2: Apply the Configuration

Deploy the Job:

```bash
kubectl apply -f job.yaml
```

Expected output:

```text
job.batch/countdown-nautilus created
```

The API server stores the configuration and immediately creates a Pod.

---

<br>
<br>

# Step 3: Verification

## Check Job Status

```bash
kubectl get jobs
```

Expected progression:

* Initially: `0/1` (not completed)
* After ~5 seconds: `1/1` (completed)

## Check Pods

```bash
kubectl get pods
```

You will see a Pod with a generated suffix:

```text
countdown-nautilus-xxxxx
```

Pod lifecycle:

* ContainerCreating
* Running
* Completed

If the container exits successfully, the Job is considered successful.

---

<br>
<br>

# How Jobs Work Internally

1. The Job controller creates a Pod based on the template.
2. The Pod runs the defined container command.
3. If the container exits with code 0, the Job marks completion.
4. If it fails, behavior depends on restart policy and backoff configuration.

The Job keeps retrying until successful completion or until it reaches the retry limit (`backoffLimit`, default is 6).

---

<br>
<br>

# Restart Policy for Jobs

Valid restart policies for Jobs:

* `OnFailure` → Restart container inside the same Pod if it fails
* `Never` → Do not restart container inside the same Pod; a new Pod may be created

`Always` is not supported because Jobs are designed to finish, not run continuously.

---

<br>
<br>

# Job vs Deployment vs CronJob

* **Pod** → Basic execution unit
* **Job** → Ensures task completes at least once
* **CronJob** → Creates Jobs on a time schedule
* **Deployment** → Maintains continuously running application Pods

---

<br>
<br>

# Key Outcome

The Job `countdown-nautilus` is successfully deployed. The container runs the `sleep 5` command, completes execution, and the Job transitions to a completed state, ensuring reliable one-time task execution.
