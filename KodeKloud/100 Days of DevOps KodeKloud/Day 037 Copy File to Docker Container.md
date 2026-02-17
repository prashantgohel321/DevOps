# DevOps Day 37: Transferring Files into a Running Docker Container

Today's task was a very practical, real-world operation that is essential for managing containerized applications: copying a file from the host server into a running container. This is a common need when deploying configuration files, injecting data, or updating application assets without rebuilding an image.

I learned how to use the `docker cp` command to bridge the gap between the host's filesystem and the container's isolated filesystem, and the `docker exec` command to verify the result.

### The Task

My objective was to copy a file into a container on **App Server 2**. The specific requirements were:
-   The source file was `/tmp/nautilus.txt.gpg` on the host.
-   The destination was the `/home/` directory inside a running container named `ubuntu_latest`.

### My Step-by-Step Solution

1.  **Connect to the Server:** I first logged into App Server 2 (`ssh steve@stapp02`).

2.  **Pre-flight Checks:** Before running the main command, I performed two quick verifications. First, I checked that the source file existed (`ls -l /tmp/nautilus.txt.gpg`). Second, I confirmed the `ubuntu_latest` container was running (`sudo docker ps`).

3.  **Copy the File:** This was the core of the task. I used a single `docker cp` command.
    ```bash
    sudo docker cp /tmp/nautilus.txt.gpg ubuntu_latest:/home/
    ```

4.  **Verification:** The crucial final step was to look *inside* the container to confirm the file had arrived. I used `docker exec` to run a command within the container's environment.
    ```bash
    sudo docker exec ubuntu_latest ls -l /home
    ```
    The output listed the `nautilus.txt.gpg` file, which was the definitive proof that my task was successful.

### Key Concepts (The "What & Why")

-   **Container Isolation**: Docker containers have their own isolated filesystem, which is a key security feature. This means I can't use the standard Linux `cp` command to move files in or out; a special command is needed.
-   **`docker cp` command**: This is Docker's built-in utility to securely **c**o**p**y files between a host and a container. It acts as a bridge across the isolation boundary. The syntax is always `docker cp <SOURCE> <DESTINATION>`, where one of the paths must include the container name followed by a colon (e.g., `my-container:/path/to/dest`).
-   **`docker exec` command**: This command is essential for verification and debugging. It lets me **exec**ute a command inside a running container. It's the standard way to inspect a container's internal state, check logs, or run diagnostic tools without stopping the container.

### Commands I Used

-   `sudo docker cp [host_path] [container_name]:[container_path]`: The main command to copy the file from the host into the container.
-   `sudo docker exec [container_name] [command]`: My verification command. I used it to run `ls -l /home` inside the container to confirm the file was successfully copied.
-   `sudo docker ps`: A helpful pre-flight check to list all running containers and confirm my target container was active.
  