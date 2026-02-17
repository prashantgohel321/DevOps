# DevOps Day 57: One-Off Tasks and Environment Variables in Kubernetes

Today's task was a fantastic lesson in a different kind of Kubernetes workload: a one-off task. Instead of creating a long-running service like a web server, my objective was to create a Pod that would run a single command, print some output, and then exit cleanly.

This was a great exercise for learning three critical concepts: how to inject configuration into a Pod using **environment variables**, how to override a container's default startup command, and how to use a `restartPolicy` to tell Kubernetes that it's okay for the container to finish its job. This document is my very detailed, first-person guide to that entire process, written from the perspective of a complete beginner to these concepts.

## Table of Contents
- [DevOps Day 57: One-Off Tasks and Environment Variables in Kubernetes](#devops-day-57-one-off-tasks-and-environment-variables-in-kubernetes)
  - [Table of Contents](#table-of-contents)
    - [The Task](#the-task)
    - [My Step-by-Step Solution](#my-step-by-step-solution)
      - [Phase 1: Writing the Pod Manifest](#phase-1-writing-the-pod-manifest)
      - [Phase 2: Applying the Manifest and Verifying](#phase-2-applying-the-manifest-and-verifying)
    - [Why Did I Do This? (The "What \& Why" for a K8s Beginner)](#why-did-i-do-this-the-what--why-for-a-k8s-beginner)
    - [Deep Dive: A Line-by-Line Explanation of My Pod YAML File](#deep-dive-a-line-by-line-explanation-of-my-pod-yaml-file)
    - [Common Pitfalls for Beginners](#common-pitfalls-for-beginners)
    - [Exploring the Essential kubectl Commands](#exploring-the-essential-kubectl-commands)

---

### The Task
<a name="the-task"></a>
My objective was to create a single Kubernetes Pod that would run a simple `echo` command. The specific requirements were:
1.  The Pod must be named `print-envars-greeting`.
2.  The container inside must be named `print-env-container` and use the `bash` image.
3.  Three environment variables must be defined:
    -   `GREETING` = `Welcome to`
    -   `COMPANY` = `Stratos`
    -   `GROUP` = `Industries`
4.  The container must run the specific command: `["/bin/sh", "-c", 'echo "$(GREETING) $(COMPANY) $(GROUP)"']`.
5.  The Pod's `restartPolicy` must be set to `Never`.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The professional way to create this Pod is with a YAML manifest file.

#### Phase 1: Writing the Pod Manifest
1.  I connected to the jump host.
2.  I created a new file named `print-envars-pod.yaml` using `vi`.
3.  Inside the editor, I wrote the following YAML code, which defines the Pod, its environment variables, the command override, and the restart policy.
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: print-envars-greeting
    spec:
      containers:
      - name: print-env-container
        image: bash:latest
        env:
        - name: GREETING
          value: "Welcome to"
        - name: COMPANY
          value: "Stratos"
        - name: GROUP
          value: "Industries"
        command: ["/bin/sh", "-c", "echo \"$(GREETING) $(COMPANY) $(GROUP)\""]
      restartPolicy: Never
    ```
4.  I saved and quit the file.

#### Phase 2: Applying the Manifest and Verifying
1.  I used `kubectl` to send my manifest to the Kubernetes API server.
    ```bash
    kubectl apply -f print-envars-pod.yaml
    ```
2.  **Verification:** The final part of the task was to confirm that the Pod ran its command successfully.
    -   First, I checked the status of the Pod. Because this job runs so quickly, by the time I checked, it was already finished.
        ```bash
        kubectl get pods
        ```
        The output correctly showed `print-envars-greeting` with a `STATUS` of `Completed`. This was the first sign of success.
    -   For the definitive proof, I checked the logs of the completed Pod.
        ```bash
        kubectl logs print-envars-greeting
        ```
    The output showed the exact string that the command was supposed to print: `Welcome to Stratos Industries`. This was the final proof that the environment variables were injected and used correctly.

---

### Why Did I Do This? (The "What & Why" for a K8s Beginner)
<a name="why-did-i-do-this-the-what--why-for-a-k8s-beginner)"></a>
-   **Environment Variables (`env`)**: This is the standard and most common way to pass configuration data into a container. Instead of hardcoding values like database connection strings or API keys into your application, you define them in the Pod's YAML. The application inside the container can then read these values from its operating system environment. This **decouples the application from its configuration**, which is a critical best practice.
-   **Overriding Container Command (`command`)**: Every Docker image has a default command it runs when it starts (defined by `CMD` or `ENTRYPOINT`). The `command` field in a Pod `spec` allows me to **override** that default. This is incredibly useful for running one-off tasks (like a database migration script) or for debugging purposes. In this task, I overrode the `bash` image's default behavior of starting an interactive shell.
-   **`restartPolicy: Never`**: This is a crucial setting for any Pod that is designed to run a task and then exit.
    -   By default, Kubernetes uses `restartPolicy: Always`. This means if a container in a Pod stops, Kubernetes assumes it crashed and immediately restarts it.
    -   For a task like my `echo` command, the container runs, prints the message, and exits with a success code (0). This is the correct behavior.
    -   If I had left the restart policy as `Always`, Kubernetes would see the container exit, think it had crashed, and restart it. The container would run the command again, exit again, and get stuck in an endless loop of restarts called a `CrashLoopBackOff`.
    -   By setting `restartPolicy: Never`, I am telling Kubernetes, "This Pod is supposed to run once and finish. When its container exits successfully, mark the Pod as `Completed` and do not try to restart it." The other option is `OnFailure`, which would only restart the container if it exited with an error.

---

### Deep Dive: A Line-by-Line Explanation of My Pod YAML File
<a name="deep-dive-a-line-by-line-explanation-of-my-pod-yaml-file"></a>
The YAML for this task demonstrates three very important concepts in the Pod `spec`.



```yaml
apiVersion: v1
kind: Pod
metadata:
  name: print-envars-greeting
spec:
  # The 'containers' block is a list of containers to run in the Pod.
  containers:
  - name: print-env-container
    image: bash:latest
    
    # The 'env' block is a list of environment variables to inject into the container.
    env:
    # Each item in the list is a key-value pair.
    - name: GREETING      # The name of the environment variable.
      value: "Welcome to" # The value of the environment variable.
    - name: COMPANY
      value: "Stratos"
    - name: GROUP
      value: "Industries"
      
    # The 'command' block overrides the Docker image's default command.
    # It is a list of strings, where the first string is the executable
    # and the subsequent strings are its arguments.
    command: ["/bin/sh", "-c", "echo \"$(GREETING) $(COMPANY) $(GROUP)\""]
    
  # The 'restartPolicy' is defined at the Pod 'spec' level.
  # 'Never' is the correct policy for one-off tasks that should not be restarted
  # after they complete successfully.
  restartPolicy: Never
  ```

### Common Pitfalls for Beginners
<a name="common-pitfalls-for-beginners"></a>

- **Forgetting restartPolicy**: Never: This is the most common mistake for a task-based Pod. It will cause the Pod to get stuck in a CrashLoopBackOff state even though the command is running successfully each time.

- **Incorrectly Quoting the Command**: Shell commands with variables can be tricky to quote correctly in YAML. The format ["`/bin/sh`", "`-c`", "`...`"] is the standard way to ensure the shell correctly interprets the variables.

- **Checking get pods too early**: A beginner might see the Pod in a Completed state and think something is wrong. For this task, Completed is the desired final state.

- **Using describe to check output**: The kubectl describe command is great for seeing configuration and events, but it does not show the output of the container's command. The only way to see the "Welcome..." message is with `kubectl logs`.

---

### Exploring the Essential kubectl Commands
<a name="exploring-the-essential-kubectl-commands"></a>

- **`kubectl apply -f [filename.yaml]`**: The standard way to create or update resources from a manifest file.

- **`kubectl get pods`**: Gets a summary list of all Pods. I used this to check for the Completed status.

- **`kubectl logs [pod-name]`**: This was the most important verification command for this task. It shows the standard output (the "logs") from the container that ran inside the Pod, allowing me to see the output of my echo command.

- **`kubectl describe pod [pod-name]`**: Describes a Pod in great detail. I could have used this to verify that the environment variables and the custom command were configured correctly for the container.