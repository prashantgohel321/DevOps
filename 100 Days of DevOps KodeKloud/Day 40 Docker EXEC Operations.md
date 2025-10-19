# DevOps Day 40: Modifying a Live Container with `docker exec`

Today's task was a deep dive into the interactive side of Docker. My goal was to take a running container and modify it in place by installing and configuring a new service. This is a crucial skill for real-world debugging and testing, where you need to get "inside the box" to see what's going on or to try out a quick change.

I learned how to use `docker exec` to gain a shell inside a container and then work as if I were on a separate Linux machine. I installed the Apache web server, changed its configuration, and started the service, all without ever stopping the original container.

### The Task

My objective was to modify a running container named `kkloud` on **App Server 1**. The specific requirements were:
1.  Install the `apache2` web server package inside the container.
2.  Configure this new Apache server to listen on port `5000`.
3.  Ensure the Apache service was running inside the container.
4.  Leave the `kkloud` container in a running state.

### My Step-by-Step Solution

1.  **Enter the Container:** I first connected to App Server 1 (`ssh tony@stapp01`). Then, I used `docker exec` to get an interactive bash shell inside the `kkloud` container. This was the most critical command.
    ```bash
    sudo docker exec -it kkloud bash
    ```
    My terminal prompt changed, confirming I was now operating inside the container's isolated environment.

2.  **Install and Configure Apache (Inside the Container):** Once inside, I worked as if I were on a standard Debian/Ubuntu system.
    ```bash
    # First, I updated the package manager's list of available software
    apt-get update

    # I installed the apache2 package, answering 'yes' to any prompts
    apt-get install -y apache2
    
    # I used 'sed' to change the default port from 80 to 5000
    sed -i 's/Listen 80/Listen 5000/g' /etc/apache2/ports.conf

    # Finally, I started the new service
    service apache2 start
    ```

3.  **Verification and Exit:** To verify my work, I needed to check if a process was listening on the new port.
    ```bash
    # I installed the net-tools package to get the 'netstat' command
    apt-get install -y net-tools

    # I used 'netstat' to check for a process listening on port 5000
    netstat -tulpn | grep 5000
    ```
    The output showed the `apache2` process successfully listening on port 5000. My work was done, so I typed `exit` to return to the host server's shell, leaving the container running with its new service.

### Key Concepts (The "What & Why")

-   **`docker exec`**: This is the key command for this task. It allows you to **exec**ute a command inside a running container. It's the standard way to interact with and manage the processes within a container's isolated environment. The `-it` flags are crucial for getting a fully interactive shell.
-   **Why Modify a Live Container?**: While production images should always be built from a `Dockerfile` for reproducibility, modifying a live container is a vital skill for:
    1.  **Debugging**: This is the number one use case. When an application is failing, `docker exec` lets you get inside its environment to inspect logs, check network connectivity, and install diagnostic tools.
    2.  **Quick Testing**: It's a fast way to test a configuration change or a new package without going through a full image rebuild cycle.
-   **Ephemeral Changes**: A critical concept I learned is that the changes I made are **ephemeral**. If this container were ever stopped and a new one was created from the original `kkloud` image, all my work—the Apache installation and configuration—would be gone. This is why `docker exec` is for temporary changes, and `Dockerfile` is for permanent ones.

### Commands I Used

-   `sudo docker exec -it kkloud bash`: My entry point. It gave me an interactive (`-it`) `bash` shell inside the running `kkloud` container.
-   `apt-get update`: The standard command on Debian/Ubuntu systems to update the local package list. This is a mandatory first step before installing new software.
-   `apt-get install -y apache2`: The command to install the Apache web server package inside the container.
-   `sed -i 's/Listen 80/Listen 5000/g' /etc/apache2/ports.conf`: A command-line tool to find and replace text. I used it to change the port number in the Apache configuration file.
-   `service apache2 start`: A common command to start a service within a container's environment.
-   `apt-get install -y net-tools`: A command I used for verification. This package contains the `netstat` utility, which is not always present in minimal container images.
-   `netstat -tulpn`: My primary verification tool. I used it *inside the container* to show all listening TCP/UDP ports and confirm that `apache2` was running on the correct port.
  