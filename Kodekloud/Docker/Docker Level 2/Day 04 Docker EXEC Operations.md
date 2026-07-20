# Docker Level 2, Task 4: Modifying a Live Container with `docker exec`

Today's task was a deep dive into the interactive side of Docker. Instead of building a new image, my goal was to modify a container that was already running. This is a crucial skill for real-world debugging and testing, where you need to get "inside the box" to see what's going on.

I learned how to use `docker exec` to gain a shell inside a container and then work as if I were on a separate Linux machine. I installed a web server, changed its configuration, and started the service, all without ever stopping the original container.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: The Power and Peril of `docker exec`](#deep-dive-the-power-and-peril-of-docker-exec)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands Used](#exploring-the-commands-used)

---

### The Task
<a name="the-task"></a>
My objective was to modify a running container named `kkloud` on **App Server 1**. The requirements were:
1.  Install the `apache2` web server package inside the container.
2.  Configure this new Apache server to listen on port `5001`.
3.  Ensure the Apache service was running inside the container.
4.  Leave the `kkloud` container in a running state.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The process involved entering the container, performing the administrative tasks, and then exiting, leaving the container running with its new service.

#### Step 1: Entering the Container
First, I connected to App Server 1 (`ssh tony@stapp01`). Then, I used `docker exec` to get an interactive bash shell inside the `kkloud` container. This was the most critical command.
```bash
sudo docker exec -it kkloud bash
```
My terminal prompt changed, confirming I was now operating inside the container's isolated environment.

#### Step 2: Installing Apache (Inside the Container)
Once inside, I worked as if I were on a standard Debian/Ubuntu system.
```bash
# First, update the package manager's list of available software
apt-get update

# Install the apache2 package, answering 'yes' to any prompts
apt-get install -y apache2
```

#### Step 3: Configuring the Port (Inside the Container)
I needed to change Apache's default port from 80 to 5001. Using `sed` was the fastest way to do this non-interactively.
```bash
sed -i 's/Listen 80/Listen 5001/g' /etc/apache2/ports.conf
```

#### Step 4: Starting and Verifying the Service (Inside the Container)
With the software installed and configured, I started the service.
```bash
service apache2 start
```
To verify it was working correctly, I used `netstat` to check for a process listening on port 5001.
```bash
netstat -tulpn | grep 5001
```
The output showed the `apache2` process was successfully listening on the new port, which was my proof of success.

#### Step 5: Exiting the Container
My work inside the container was done. I typed `exit` to return to the shell of App Server 1.
```bash
exit
```
I ran `sudo docker ps` one last time on the host to confirm that the `kkloud` container was still running, successfully completing the task.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
-   **`docker exec`**: This is the key command for this task. It allows you to **exec**ute a command inside a running container. It's the standard way to interact with and manage the processes within a container's isolated environment.
-   **Interactive Shell (`-it`)**: The flags I used are crucial:
    -   `-i` (`--interactive`): Keeps `STDIN` open, allowing me to type commands into the container.
    -   `-t` (`--tty`): Allocates a pseudo-TTY, which makes the terminal session behave like a real one.
    -   Combining `-it` with `bash` gives me a fully interactive shell, as if I had SSH'd into the container.
-   **Why Modify a Live Container?**: While production images should always be built from a `Dockerfile` for reproducibility, modifying a live container is a vital skill for:
    1.  **Debugging**: This is the #1 use case. When an application is failing, `docker exec` lets you get inside its environment to inspect logs, check network connectivity, and install diagnostic tools.
    2.  **Quick Testing**: It's a fast way to test a configuration change or a new package without going through a full image rebuild cycle.
    3.  **Emergency Hotfixes**: In a crisis, it allows a sysadmin to apply a critical patch directly to a running container while a permanent fix is being developed.

---

### Deep Dive: The Power and Peril of `docker exec`
<a name="deep-dive-the-power-and-peril-of-docker-exec"></a>
This task made me appreciate the double-edged nature of `docker exec`.

[Image of docker exec entering a container]

-   **The Power**: It gives you complete, root-level access to the inside of a container. You can see the application's environment exactly as it sees it, which is invaluable for troubleshooting problems that are hard to reproduce locally.

-   **The Peril**: The changes I made are **ephemeral**. If this container were ever stopped and a new one was created from the original `kkloud` image, all my work—the Apache installation and configuration—would be gone. This is why `docker exec` is for debugging and testing, not for making permanent changes. **Permanent changes should always be codified in a `Dockerfile` and built into a new version of the image.**

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Forgetting `apt-get update`:** A very common mistake is to try and install a package without first updating the package list. This often results in "package not found" errors.
-   **Using the Wrong Service Manager:** Inside a container, especially a minimal one, the full `systemctl` service manager might not be available. Using the older `service apache2 start` or directly calling the start script is often more reliable.
-   **Editing the Wrong Config File:** Apache has several configuration files. Knowing that `ports.conf` is the correct place to change the main listening port is key.
-   **Exiting Too Early:** If I had exited the container before starting the Apache service, the task would have failed. The goal was to leave the container running *with Apache running inside it*.

---

### Exploring the Commands Used
<a name="exploring-the-commands-used"></a>
-   `sudo docker exec -it [container] bash`: My entry point. It allowed me to get an interactive shell inside the specified running container.
-   `apt-get update && apt-get install -y apache2`: The standard Debian/Ubuntu commands to update package lists and install software non-interactively. Run *inside* the container.
-   `sed -i 's/Listen 80/Listen 5001/g' /etc/apache2/ports.conf`: A powerful command-line tool to find and replace text. I used it to change the port number in the configuration file. Run *inside* the container.
-   `service apache2 start`: A common command to start a service within a container's environment. Run *inside* the container.
-   `netstat -tulpn`: A networking utility to show all listening TCP/UDP ports and the programs using them. My primary tool for verifying that Apache was running on the correct port. Run *inside* the container.
-   `exit`: The command to close the interactive shell and return to the host machine's prompt.
 