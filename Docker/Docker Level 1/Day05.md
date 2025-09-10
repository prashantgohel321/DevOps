# Docker Day 5: The Case of the Connection Refused

My fifth Docker task was a real-world debugging challenge. Instead of building something new, I was tasked with investigating a broken application. A static website running in a container was inaccessible, and I had to put on my detective hat, use Docker's built-in tools to gather evidence, and ultimately solve the mystery.

This was one of my favorite tasks so far because it mirrored a common scenario in any DevOps role: a service is down, and you need to find out why—fast.

## Table of Contents
- [The Task](#the-task)
- [My Investigation & Solution](#my-investigation--solution)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: The "Nuke and Replace" Philosophy](#deep-dive-the-nuke-and-replace-philosophy)
- [Exploring the Commands Used](#exploring-the-commands-used)

---

### The Task
<a name="the-task"></a>
On `App Server 1`, a container named `nautilus` was malfunctioning. My mission was to:
1.  Check if its volume mapping was correct: host `/var/www/html` to container `/usr/local/apache2/htdocs`.
2.  Check if its port mapping was correct: host port `8080` to the container's web server port.
3.  Verify if the website was accessible using `curl http://localhost:8080/`.

---

### My Investigation & Solution
<a name="my-investigation--solution"></a>
This was a classic process of elimination. I used `docker inspect` to check the container's configuration and `curl` to test its behavior.

#### Step 1: Gathering Evidence - Inspecting the Container
I started by looking at the container's configuration to verify the mappings. `docker inspect` produces a lot of JSON, so I used `grep` to find the specific parts I needed.

* **Checking the Volume Mount:**
    ```bash
    sudo docker inspect nautilus | grep -A 4 Mounts
    ```
    **Result:** The output clearly showed `Source: "/var/www/html"` and `Destination: "/usr/local/apache2/htdocs"`. **Conclusion: The volume mapping was correct.**

* **Checking the Port Binding:**
    ```bash
    sudo docker inspect nautilus | grep -A 4 PortBindings
    ```
    **Result:** The output showed `HostPort: "8080"` was correctly mapped to the container's `80/tcp` port. **Conclusion: The port mapping was correct.**

#### Step 2: The "Smoking Gun" - Testing the Connection
With the configuration confirmed as correct, the final test was to try and access the website.
```bash
curl http://localhost:8080/
```
**Result:** `curl: (7) Failed to connect to localhost port 8080: Connection refused`.

#### Step 3: The Diagnosis and Solution
This was the "aha!" moment.
* The `docker inspect` output proved that Docker was set up correctly to forward traffic.
* The `Connection refused` error proved that when the traffic arrived at the container, there was **no process listening** on port 80.
* **Final Diagnosis:** The Docker configuration was fine, but the Apache web server process *inside* the container had crashed or failed to start.

The solution was to apply the "Nuke and Replace" strategy.

* **Remove the Broken Container:**
    ```bash
    sudo docker rm -f nautilus
    ```
* **Re-create a Healthy Container:**
    I re-launched the container from scratch using the official `httpd` image and explicitly defining the correct volume and port mappings.
    ```bash
    sudo docker run -d --name nautilus -p 8080:80 -v /var/www/html:/usr/local/apache2/htdocs httpd:latest
    ```
After this, a final `curl http://localhost:8080/` test worked perfectly, and the website's HTML was displayed. Case closed! 

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
This task was a crucial lesson in debugging containerized applications.
-   **`docker inspect`:** This is the primary tool for looking "under the hood" of a container. It allows you to see its network settings, volume mounts, startup commands, and more, without which you'd be flying blind.
-   **Volume Mounts (`-v`):** These are essential for decoupling an application's data from the application itself. They allow you to serve files from the host machine, making it easy to update website content without having to rebuild the entire container.
-   **Port Mappings (`-p`):** Containers have their own isolated network. Port mappings are the bridge that connects a port on the host server to a port inside the container, allowing external traffic to reach the application.

---

### Deep Dive: The "Nuke and Replace" Philosophy
<a name="deep-dive-the-nuke-and-replace-philosophy"></a>
This exercise perfectly illustrates a core principle of modern infrastructure: **containers are ephemeral and should be treated as immutable.**

-   **Don't Repair, Replace:** In the old days, if a service on a server crashed, you would SSH in and try to debug and fix it. With containers, this is an anti-pattern. Because they are so cheap and fast to create, it's almost always faster, safer, and more reliable to simply destroy the broken container and launch a fresh, healthy one from a known-good image.
-   **Immutable Infrastructure:** This concept means that once a piece of infrastructure (like a container) is deployed, it is never changed. If an update is needed, you destroy the old one and deploy a new one. This leads to more predictable and reliable systems.

---

### Exploring the Commands Used
<a name="exploring-the-commands-used"></a>
-   `docker inspect [container]`: The key command to get detailed, low-level information about a Docker object in JSON format.
-   `grep -A 4 [pattern]`: A Linux utility to find text. The `-A 4` flag tells it to show the matching line **A**nd the **4** lines **A**fter it, which is useful for seeing a whole section of a JSON file.
-   `curl [URL]`: A command-line tool for transferring data with URLs. It's the simplest way to check if a web server is responding.
-   `docker rm -f [container]`: Removes a container. The `-f` (force) flag will stop it first if it's running.
-   `docker run -p [host_port]:[container_port] -v [host_path]:[container_path] ...`: The full command to create and run a container, defining port (`-p`) and volume (`-v`) mappings.
