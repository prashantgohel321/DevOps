# Kubernetes Level 01 – Day 08: Schedule CronJobs in Kubernetes

This document explains how to create and manage a Kubernetes CronJob to execute a recurring task inside the cluster. The objective is to run a simple command at a fixed interval using native Kubernetes scheduling.

---

<br>
<br>

- [Kubernetes Level 01 – Day 08: Schedule CronJobs in Kubernetes](#kubernetes-level-01--day-08-schedule-cronjobs-in-kubernetes)
  - [Objective](#objective)
- [Understanding the Goal](#understanding-the-goal)
- [Step 1: Create the YAML Manifest](#step-1-create-the-yaml-manifest)
    - [Manifest Content](#manifest-content)
    - [Important Configuration Details](#important-configuration-details)
- [Step 2: Apply the Configuration](#step-2-apply-the-configuration)
- [Step 3: Verification](#step-3-verification)
  - [Check CronJob Status](#check-cronjob-status)
  - [Manual Test (Optional)](#manual-test-optional)
  - [Check Pods](#check-pods)
  - [Check Logs](#check-logs)
- [How CronJobs Work Internally](#how-cronjobs-work-internally)
- [Restart Policy Explanation](#restart-policy-explanation)
- [Key Outcome](#key-outcome)


<br>
<br>

## Objective

Create a CronJob with the following configuration:

* **CronJob Name:** `devops`
* **Schedule:** `*/3 * * * *`
* **Image:** `httpd:latest`
* **Container Name:** `cron-devops`
* **Command:** `echo Welcome to xfusioncorp!`
* **Restart Policy:** `OnFailure`

---

<br>
<br>

# Understanding the Goal

A CronJob in Kubernetes is used to run tasks at scheduled times, similar to the traditional Linux cron scheduler. Instead of running scripts on a VM directly, Kubernetes creates and manages Jobs automatically according to the defined schedule.

In this task, the system must execute a container every 3 minutes and print a message.

---

<br>
<br>

# Step 1: Create the YAML Manifest

Create a manifest file:

```bash
vi cronjob.yaml
```

### Manifest Content

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: devops
spec:
  schedule: "*/3 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: cron-devops
            image: httpd:latest
            command:
            - /bin/sh
            - -c
            - echo Welcome to xfusioncorp!
          restartPolicy: OnFailure
```

### Important Configuration Details

* `apiVersion: batch/v1` → CronJob API group
* `schedule` → Standard cron format (minute hour day month weekday)
* `*/3 * * * *` → Every 3 minutes
* `jobTemplate` → Template used to create a Job
* `template.spec` → Pod specification used by the Job
* `restartPolicy: OnFailure` → Restart container only if it exits with an error

The CronJob creates a Job object. The Job then creates a Pod to execute the task.

---

<br>
<br>

# Step 2: Apply the Configuration

Deploy the CronJob into the cluster:

```bash
kubectl apply -f cronjob.yaml
```

Expected output:

```text
cronjob.batch/devops created
```

Kubernetes now monitors the schedule and triggers Jobs automatically.

---

<br>
<br>

# Step 3: Verification

## Check CronJob Status

```bash
kubectl get cronjob

# OUTPUT

thor@jumphost ~$ kubectl get cronjob
NAME     SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
devops   */3 * * * *   False     0        <none>          6s
```

Expected output should include:

* NAME → devops
* SCHEDULE → */3 * * * *
* SUSPEND → False

## Manual Test (Optional)

Instead of waiting 3 minutes, create a Job immediately:

```bash
kubectl create job --from=cronjob/devops test-job
```

## Check Pods

```bash
kubectl get pods
```

Identify the Pod created by the Job.

## Check Logs

```bash
kubectl logs <pod-name>
```

Expected output:

```text
Welcome to xfusioncorp!
```

---

<br>
<br>

# How CronJobs Work Internally

1. The CronJob controller checks the schedule.
2. When the time matches, it creates a Job object.
3. The Job controller creates a Pod.
4. The Pod runs the defined command.
5. When complete, the Pod exits.

The CronJob only manages scheduling. The Job manages execution.

---

<br>
<br>

# Restart Policy Explanation

For Jobs and CronJobs, valid restart policies are:

* `OnFailure` → Restart container if it exits with non-zero status
* `Never` → Do not restart container

`Always` is not allowed because Jobs are expected to complete.

---

<br>
<br>

# Key Outcome

The CronJob `devops` is successfully configured to execute every 3 minutes. Kubernetes automatically creates Jobs and Pods according to the defined schedule, ensuring recurring execution without manual intervention.
