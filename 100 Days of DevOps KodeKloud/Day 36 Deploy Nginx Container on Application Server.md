# DevOps Day 36: Deploying a Simple Nginx Container

Today's task was a great refresher on the most fundamental operation in Docker: running a container. My objective was to deploy a simple Nginx web server in a container on one of the app servers. This is the "Hello, World!" of containerized deployments and is a core skill for any DevOps practitioner.

I learned the importance of using lightweight images (like `nginx:alpine`) and how to correctly use the `docker run` command to launch a container in the background. This document is my first-person guide to that simple but essential process.

### The Task

My objective was to deploy a container on **App Server 3**. The specific requirements were:
-   Create a container named `nginx_3`.
-   Use the `nginx` image with the `alpine` tag.
-   Ensure the container is left in a `running` state.

### My Step-by-Step Solution

1.  **Connect to the Server:** I first logged into App Server 3 (`ssh banner@stapp03`).

2.  **Run the Container:** I used a single `docker run` command to create, name, and start the container in the background.
    ```bash
    sudo docker run -d --name nginx_3 nginx:alpine
    ```

3.  **Verification:** The crucial final step was to confirm that the container was running as expected. I used the `docker ps` command, which lists all running containers.
    ```bash
    sudo docker ps
    ```
    The output clearly showed my `nginx_3` container with a status of "Up," which was the definitive proof that my task was successful.
    ```
    CONTAINER ID   IMAGE          COMMAND                  STATUS         NAMES
    [some_id]      nginx:alpine   "/docker-entrypoint.…"   Up a few seconds   nginx_3
    ```

### Key Concepts (The "What & Why")

-   **Docker Container**: A container is a standard, isolated package that contains an application and all its dependencies. This ensures the application runs the same way regardless of the environment.
-   **Nginx**: A high-performance, open-source web server. It's incredibly popular for its speed and efficiency at serving static content.
-   **`nginx:alpine` Image**: This is a specific "flavor" of the official Nginx image. The `:alpine` tag signifies that it's built on **Alpine Linux**, an extremely minimalistic Linux distribution. Using Alpine-based images is a major best practice in the Docker world because:
    -   **Size:** They are incredibly small (the `nginx:alpine` image is only a few MB), which means faster downloads and less disk space used.
    -   **Security:** They have a minimal "attack surface." Because they include very few extra libraries or tools, there are fewer potential vulnerabilities for an attacker to exploit.
-   **The `-d` flag (Detached Mode)**: This was a critical part of the command. The `-d` flag tells Docker to run the container in the **background** and print the container ID. Without this, the container would run in the foreground, and my terminal would be attached to the Nginx server's logs. If I closed my terminal, the container would stop. Running in detached mode is essential for any long-running service like a web server.

### Commands I Used

-   `sudo docker run -d --name nginx_3 nginx:alpine`: The main command for this task.
    -   `docker run`: The command to create and run a new container.
    -   `-d`: Runs the container in **d**etached (background) mode.
    -   `--name nginx_3`: Assigns a specific, human-readable **name** to the container.
    -   `nginx:alpine`: The image (and its tag) to use as the blueprint for the container.
-   `sudo docker ps`: My verification command. It lists all currently running containers, allowing me to check the `NAME` and `STATUS` to confirm the task was completed successfully.
   