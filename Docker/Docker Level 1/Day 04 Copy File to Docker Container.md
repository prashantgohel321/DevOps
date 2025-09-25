# Docker Day 4: Copying Files and Diagnosing a Broken Host

What started as a simple task—copying a file into a running container—quickly spiraled into one of the most intense troubleshooting sessions I've had. My goal for Day 4 was to learn how to move data between my host server and an isolated container, but I ended up diagnosing a fundamental failure in the lab environment itself.

This task was a masterclass in perseverance and demonstrated that sometimes the problem isn't your command, but the system you're running it on.

## Table of Contents
- [The Task](#the-task)
- [The Ideal Solution (The Happy Path)](#the-ideal-solution-the-happy-path)
- [My Journey: A Cascade of Failures & Solutions](#my-journey-a-cascade-of-failures--solutions)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: Container States ("Created" vs. "Running")](#deep-dive-container-states-created-vs-running)
- [Exploring the Commands Used](#exploring-the-commands-used)

---

### The Task
<a name="the-task"></a>
On `App Server 2`, I needed to copy a file from the host machine into a running container.
1.  **Source File:** `/tmp/nautilus.txt.gpg` on the host.
2.  **Destination Container:** A container named `ubuntu_latest`.
3.  **Destination Path:** The `/tmp/` directory inside the container.

---

### The Ideal Solution (The Happy Path)
<a name="the-ideal-solution-the-happy-path"></a>
In a perfect world, where the container is already running, this task would be a single command followed by verification.

#### 1. The Copy Command
```bash
sudo docker cp /tmp/nautilus.txt.gpg ubuntu_latest:/tmp/
```

#### 2. The Verification Command
```bash
sudo docker exec ubuntu_latest ls -l /tmp/nautilus.txt.gpg
```

However, my journey was far from this simple.

---

### My Journey: A Cascade of Failures & Solutions
<a name="my-journey-a-cascade-of-failures--solutions"></a>
This is where the real learning happened. My initial command failed, leading me down a deep rabbit hole of debugging.

* **Failure 1: The container wasn't running.**
    * **Symptom:** I first ran `sudo docker ps` to see all running containers, and the list was empty.
    * **Solution:** I realized I needed to check for *all* containers, including stopped ones. I used `sudo docker ps -a`.

* **Failure 2: The container's status was "Created".**
    * **Symptom:** The output of `docker ps -a` showed the `ubuntu_latest` container, but its status was "Created," not "Exited" or "Up". This meant it had been defined but had never successfully started.
    * **Solution:** A "Created" container needs to be started. I tried to start it with `sudo docker start ubuntu_latest`.

* **Failure 3: `docker start` failed with a low-level error.**
    * **Symptom:** The `start` command failed with a terrifying error: `OCI runtime create failed: runc create failed: unable to start container process: error during container init: error mounting "proc" to rootfs...`
    * **Reasoning:** This was my first clue that the problem was serious. This error comes from the very core of the container runtime. It meant the container was fundamentally broken and could not be started.
    * **Solution:** When a container is this broken, you don't fix it; you replace it. I removed the broken container with `sudo docker rm ubuntu_latest`. My plan was to create a new, healthy one.

* **Failure 4: `docker run` failed with the *exact same* error.**
    * **Symptom:** I tried to create a new container with `sudo docker run -d --name ubuntu_latest ubuntu:latest sleep infinity`. It failed with the identical `OCI runtime ... error mounting "proc"` message.
    * **Reasoning:** This was the critical diagnostic step. Since a brand new, clean container from an official image also failed, the problem wasn't the container—it was the Docker service or the host machine itself.
    * **Solution:** When the service seems broken, restart it. I ran `sudo systemctl restart docker`.

* **Failure 5: The issue persisted even after a service restart.**
    * **Symptom:** After restarting Docker, I ran the ultimate test: `sudo docker run hello-world`. This minimal, official test container failed with the *exact same OCI error*.
    * **Final Conclusion:** This was the "checkmate" moment. I had scientifically proven that the host environment provided by the lab was fundamentally broken. No Docker command I could run would ever succeed. The only solution was to **end the lab session and start a new one**, hoping to be assigned a healthy virtual machine.

I eventually restarted the lab, got a healthy machine, and the simple "Happy Path" solution worked perfectly. 
---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
The original task was about learning `docker cp`. This command is the secure bridge between the host filesystem and the isolated container filesystem. It's essential for getting configuration files, application code, or data into a running container, or for extracting logs and artifacts out of one.

However, the real lesson was in **systematic troubleshooting**. By methodically testing hypotheses and isolating the problem, I moved from blaming my own command to proving a failure in the underlying platform.

---

### Deep Dive: Container States ("Created" vs. "Running")
<a name="deep-dive-container-states-created-vs-running"></a>
This experience highlighted the different states a container can be in:
-   **Created:** The container's configuration and filesystem layers have been prepared, but the main process inside it has never been started. It exists on disk but is not a live process.
-   **Running (Up):** The container is a live, active process consuming CPU and RAM. This is the state it must be in for commands like `docker exec` to work.
-   **Exited:** The container was running, but the main process inside it has finished or crashed. Its filesystem is preserved until it is removed.

---

### Exploring the Commands Used
<a name="exploring-the-commands-used"></a>
-   `docker cp [src] [dest]`: The primary command for copying files/folders between a host and a container.
-   `docker exec [container] [command]`: Executes a command inside a **running** container.
-   `docker ps -a`: The crucial command to see *all* containers, not just the running ones. Essential for cleanup and debugging.
-   `docker start [container]`: Starts a stopped or created container.
-   `docker rm [container]`: Permanently removes a container.
-   `systemctl restart docker`: A Linux administrator command to restart the entire Docker service, used when the service itself is malfunctioning.
