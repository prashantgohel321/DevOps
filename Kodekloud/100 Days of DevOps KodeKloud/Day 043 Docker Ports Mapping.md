# DevOps Day 43: Deploying a Container and Exposing a Service

Today's task was a great practical exercise in one of the most common Docker workflows: deploying a containerized web server and making it accessible on the network. My objective was to run an Nginx container and use "port mapping" to expose the web server to the host machine.

This is a fundamental skill for containerizing any network-based application, from web servers and APIs to databases. I learned how to use the `-p` flag in the `docker run` command to create this network bridge. This document is my first-person guide to that essential process.

### The Task

My objective was to deploy a containerized Nginx web server on **App Server 3**. The specific requirements were:
-   Pull the `nginx:stable` image.
-   Create a container named `news`.
-   Map host port `8088` to the container's internal port `80`.
-   Ensure the container was left in a `running` state.

### My Step-by-Step Solution

1.  **Connect to the Server:** I first logged into App Server 3 (`ssh banner@stapp03`).

2.  **Pull the Image:** As a best practice, I explicitly pulled the required image first to ensure it was available locally. The `:stable` tag ensures I'm using a production-ready version of Nginx.
    ```bash
    sudo docker pull nginx:stable
    ```

3.  **Run the Container with Port Mapping:** This was the core of the task. I used a single `docker run` command with the `-p` flag to define the port mapping.
    ```bash
    sudo docker run -d --name news -p 8088:80 nginx:stable
    ```

4.  **Verification:** The crucial final step was to confirm that the container was running and the port was correctly mapped.
    -   **Check the Running Container:** I used `docker ps` to see the status. The `PORTS` column in the output was the definitive proof: `0.0.0.0:8088->80/tcp`. This clearly showed that traffic arriving on the host at port `8088` was being forwarded to port `80` inside the container.
        ```bash
        sudo docker ps
        ```
    -   **Test the Connection:** I then ran a local `curl` command to test the web server through the mapped port.
        ```bash
        curl http://localhost:8088
        ```
    I received the "Welcome to nginx!" HTML page, confirming that the entire setup was working perfectly.

### Key Concepts (The "What & Why")

-   **Container Isolation**: Docker containers run in their own isolated network. A web server listening on port `80` inside a container is completely unreachable from the host machine by default. This is a key security feature.
-   **Port Mapping (or "Publishing")**: This is the mechanism Docker provides to bridge this network gap. It creates a forwarding rule that connects a port on the host machine's network to a port inside the container. This is what makes a container's services accessible.
-   **The `-p` or `--publish` Flag**: This is the command-line flag used with `docker run` to configure port mapping. The syntax is critical: `-p <HOST_PORT>:<CONTAINER_PORT>`. The host port always comes first.
-   **`nginx:stable` Image**: This is a specific tag for the official Nginx image. While `:latest` points to the newest build (which might have experimental features), `:stable` points to the most recent, production-vetted stable release. It's a good practice to use stable tags for reliability.
-   **The `-d` Flag (Detached Mode)**: The `-d` flag is essential for running services. It tells Docker to run the container in the **background**. Without it, my terminal would be attached to the Nginx server's logs, and closing the terminal would stop the container.

### Commands I Used

-   `sudo docker pull nginx:stable`: Downloads the `nginx` image with the `stable` tag from Docker Hub.
-   `sudo docker run -d --name news -p 8088:80 nginx:stable`: The main command for this task.
    -   `-d`: Runs the container in **d**etached (background) mode.
    -   `--name`: Assigns a human-readable **name** to the container.
    -   `-p 8088:80`: **P**ublishes the port, mapping the host's port 8088 to the container's port 80.
-   `sudo docker ps`: My primary verification command. It lists all currently running containers, allowing me to check the `NAME`, `STATUS`, and `PORTS` to confirm the task was completed successfully.
-   `curl http://localhost:8088`: My secondary verification command. I used it to make a web request to the host'
