# DevOps Day 53: Troubleshooting a Multi-Container Pod in Kubernetes

Today's task was a fantastic, real-world troubleshooting scenario in Kubernetes. My objective was to fix a broken Nginx and PHP-FPM application. The challenge was that the `kubectl get pods` command showed the Pod and both its containers were `Running` perfectly. This was a great lesson that "Running" does not always mean "Working."

This was a deep dive into the inner workings of multi-container pods, shared volumes, and ConfigMaps. I had to play detective, using `kubectl describe`, `logs`, and `edit` to find a subtle but critical misconfiguration in how the two containers were communicating. This document is my very detailed, first-person guide to that entire successful troubleshooting journey.

## Table of Contents
- [DevOps Day 53: Troubleshooting a Multi-Container Pod in Kubernetes](#devops-day-53-troubleshooting-a-multi-container-pod-in-kubernetes)
  - [Table of Contents](#table-of-contents)
    - [The Task](#the-task)
    - [My Step-by-Step Solution](#my-step-by-step-solution)
      - [Phase 1: The Investigation](#phase-1-the-investigation)
      - [Phase 2: Applying the Fix](#phase-2-applying-the-fix)
      - [Phase 3: Deploying the Content](#phase-3-deploying-the-content)
    - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
    - [Deep Dive: The Anatomy of a Multi-Container Failure](#deep-dive-the-anatomy-of-a-multi-container-failure)
    - [Common Pitfalls for Beginners](#common-pitfalls-for-beginners)
    - [Exploring the Essential `kubectl` Commands](#exploring-the-essential-kubectl-commands)

---

### The Task
<a name="the-task"></a>
My objective was to investigate and fix a broken Nginx and PHP-FPM setup running in a Kubernetes Pod. The key components were:
1.  A Pod named `nginx-phpfpm`.
2.  A ConfigMap named `nginx-config` that held the Nginx configuration.
3.  After fixing the configuration, I had to copy an `index.php` file from the jump host into the container's document root.
4.  The final website had to be accessible.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
My approach was to systematically investigate each component to find the root cause, apply the fix, and then deploy the final piece of content.

#### Phase 1: The Investigation
1.  I connected to the jump host. My first command, `kubectl get pods`, showed the `nginx-phpfpm` pod was `2/2 Running`. This was a misleading sign of health.
2.  The "Website" button showed "File not found" or a 404 error, confirming a problem.
3.  **This was the first key clue.** I checked the logs of the Nginx container:
    ```bash
    kubectl logs nginx-phpfpm -c nginx-container
    ```
    The logs contained the error: `FastCGI sent in stderr: "Primary script unknown"`. This told me Nginx was successfully passing a request to PHP-FPM, but PHP-FPM could not find the script file Nginx asked for.

4.  **This was the second key clue.** I used `kubectl describe pod nginx-phpfpm` to inspect the Pod's structure. I looked at the `Mounts` for both containers and found the critical mismatch:
    -   The `nginx-container` mounted the shared volume at `/var/www/html`.
    -   The `php-fpm-container` mounted the *same* shared volume at `/usr/share/nginx/html`.

5.  Finally, I inspected the Nginx configuration in the `nginx-config` ConfigMap with `kubectl describe configmap nginx-config`. It showed that Nginx was passing the `SCRIPT_FILENAME` to PHP-FPM using its own document root: `$document_root$fastcgi_script_name`, which resolved to `/var/www/html/index.php`. This confirmed the path mismatch.

#### Phase 2: Applying the Fix
1.  I edited the ConfigMap directly in the cluster.
    ```bash
    kubectl edit configmap nginx-config
    ```
2.  Inside the editor, I changed a single line in the `nginx.conf` data. I changed the `fastcgi_pass` parameter to use the correct communication method for containers within the same pod. The original `fastcgi_pass 127.0.0.1:9000;` was replaced. In my successful attempt, I updated the configuration as follows to ensure Nginx and PHP-FPM could communicate and find files correctly.
    ```nginx
    # ... inside the location ~ \.php$ block ...
    fastcgi_param SCRIPT_FILENAME /var/www/html$fastcgi_script_name; # Hardcoded path for PHP-FPM
    fastcgi_pass localhost:9000;
    ```
    *(Note: The exact fix can vary; another valid fix is to change the pod definition so both containers use the same mount path. Editing the config is often faster.)*
3.  After saving the ConfigMap, I needed to tell the running Nginx container to reload its configuration.
    ```bash
    kubectl exec nginx-phpfpm -c nginx-container -- nginx -s reload
    ```

#### Phase 3: Deploying the Content
1.  The `kubectl cp` command would fail if the destination directory didn't exist. I first created it inside the container using `exec`.
    ```bash
    kubectl exec nginx-phpfpm -c nginx-container -- mkdir -p /var/www/html
    ```
2.  Now I could copy the file. I specified the `nginx-container` with the `-c` flag because the Pod has multiple containers.
    ```bash
    kubectl cp /home/thor/index.php nginx-phpfpm:/var/www/html/index.php -c nginx-container
    ```
3.  Finally, clicking the "Website" button showed the correct output from the `index.php` file.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **Multi-Container Pods:** This task was a perfect example of this powerful pattern. Instead of putting Nginx and PHP in the same container (which is an anti-pattern), they are in separate containers within the same Pod. This allows me to manage and update them independently. Because they are in the same Pod, they share a network namespace (so they can talk via `localhost`) and can share volumes.
-   **Shared `EmptyDir` Volume:** An `EmptyDir` volume is a temporary directory that is created when a Pod starts and is destroyed when the Pod is deleted. Its primary purpose is to provide a shared filesystem for containers running within the same Pod. In my task, it was the shared space where the `nginx-container` would look for `index.php` and the `php-fpm-container` would execute it.
-   **ConfigMaps**: A ConfigMap is a Kubernetes object used to store non-confidential configuration data in key-value pairs. In this task, the entire `nginx.conf` file was stored in a ConfigMap. This is a crucial best practice because it decouples the configuration from the container image. I was able to fix the Nginx configuration by editing the ConfigMap, and Kubernetes automatically updated the file inside the running container, without me needing to rebuild the image.

---

### Deep Dive: The Anatomy of a Multi-Container Failure
<a name="deep-dive-the-anatomy-of-a-multi-container-failure"></a>
The "Primary script unknown" error was the key. This error comes from PHP-FPM and it means "The web server asked me to run a script, but I can't find that script at the path it gave me." My troubleshooting revealed the exact sequence of this failure.

[Image of a multi-container Kubernetes Pod]

1.  **The Request:** A user request for `index.php` arrives at the Nginx container.
2.  **Nginx's View:** Nginx is configured with `root /var/www/html`. It sees the request for `/index.php` and combines them. It decides the script's filename is `/var/www/html/index.php`.
3.  **The Hand-off:** Nginx passes the request to PHP-FPM over the network (`fastcgi_pass localhost:9000`) and includes the parameter `SCRIPT_FILENAME = /var/www/html/index.php`.
4.  **PHP-FPM's View:** The PHP-FPM container receives this request. It looks in its *own* filesystem for the file at `/var/www/html/index.php`.
5.  **The Failure Point:** In my `describe` output, I saw that the shared volume was mounted at `/usr/share/nginx/html` inside the PHP-FPM container. The path `/var/www/html/` did not exist in its world.
6.  **The Error:** Because it couldn't find the file, PHP-FPM returned the "Primary script unknown" error back to Nginx, which in turn sent a `404 Not Found` to the user.

My fix in the ConfigMap—hardcoding the `SCRIPT_FILENAME` path to what Nginx saw—was one way to solve it. An equally valid solution would be to edit the Pod's YAML definition to make both containers mount the shared volume at the exact same path.

---

### Common Pitfalls for Beginners
<a name="common-pitfalls-for-beginners"></a>
-   **`Running` != `Working`:** My first lesson. A Pod showing `Running` and `2/2 Ready` is a good sign, but it only means the container processes have started. It says nothing about whether the application inside is configured correctly.
-   **Forgetting the `-c` flag:** When a Pod has multiple containers, you **must** use the `-c <container-name>` flag for commands like `kubectl logs`, `exec`, and `cp` to tell Kubernetes which container you want to interact with.
-   **Forgetting to Reload Config:** After editing a ConfigMap that's mounted as a file, the application inside the container often needs to be told to reload its configuration. For Nginx, the command `nginx -s reload` does this gracefully without restarting the process.
-   **`kubectl cp` Destination Must Exist:** The `kubectl cp` command will fail if the parent directory of the destination path does not already exist inside the container. I had to create it first with `kubectl exec ... mkdir -p`.

---

### Exploring the Essential `kubectl` Commands
<a name="exploring-the-essential-kubectl-commands"></a>
-   `kubectl get pods`: Lists a summary of all Pods.
-   `kubectl describe pod [pod-name]`: My primary tool for troubleshooting. It shows the Pod's full configuration, including its container definitions, volume mounts, and recent events.
-   `kubectl describe configmap [cm-name]`: Shows the data stored inside a ConfigMap.
-   `kubectl logs [pod-name] -c [container-name]`: Shows the logs from a specific container within a multi-container Pod. This was essential for finding the "Primary script unknown" error.
-   `kubectl edit configmap [cm-name]`: The command to open a ConfigMap's YAML definition in a text editor to make live changes in the cluster.
-   `kubectl exec [pod-name] -c [container-name] -- [command]`: Executes a command in a specific container. I used this to reload Nginx and to create the destination directory.
-   `kubectl cp [source] [pod-name]:[dest] -c [container-name]`: Copies a file from the local machine into a specific container in a Pod.
