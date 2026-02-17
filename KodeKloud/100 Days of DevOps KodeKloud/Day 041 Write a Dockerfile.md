# DevOps Day 41: Creating a Custom Apache Image with a `Dockerfile`

Today's task was a deep dive into the most fundamental skill in the Docker ecosystem: building a custom image from scratch using a `Dockerfile`. My objective was to create a "recipe" that would take a base Ubuntu image, install the Apache web server, and configure it to run on a custom port.

This process is the foundation of creating portable, reproducible application environments. I learned how to codify the server setup into a simple text file, which is a core practice of "Infrastructure as Code." This document is my first-person guide to that entire process.

### The Task

My objective was to create a custom Docker image on **App Server 2**. The specific requirements for the image were:
-   The `Dockerfile` must be located at `/opt/docker/Dockerfile`.
-   The base image must be `ubuntu:24.04`.
-   The final image must have `apache2` installed.
-   The Apache server must be configured to listen on port `6300`.

### My Step-by-Step Solution

1.  **Prepare the Environment:** I first connected to App Server 2 (`ssh steve@stapp02`). The task required the `Dockerfile` to be in a specific location, so I created the directory first. Since `/opt` is owned by `root`, I needed `sudo`.
    ```bash
    sudo mkdir -p /opt/docker
    ```

2.  **Create the `Dockerfile`:** I created and edited the `Dockerfile` using `vi`.
    ```bash
    sudo vi /opt/docker/Dockerfile
    ```
    Inside the editor, I wrote the following instructions:
    ```dockerfile
    # Start from the specified Ubuntu base image
    FROM ubuntu:24.04

    # Run commands to update package lists and install apache2
    RUN apt-get update && apt-get install -y apache2

    # Run a command to modify the Apache port configuration file
    RUN sed -i 's/Listen 80/Listen 6300/g' /etc/apache2/ports.conf

    # Document the port the container will listen on
    EXPOSE 6300

    # Set the default command to start Apache in the foreground
    CMD ["apache2ctl", "-D", "FOREGROUND"]
    ```

3.  **Verification (Optional but Recommended):** Although the task was just to create the file, I wanted to prove it worked.
    -   First, I built the image: `cd /opt/docker && sudo docker build -t my-apache:test .`
    -   Then, I ran a container from it, mapping the ports: `sudo docker run -d -p 8080:6300 --name test-app my-apache:test`
    -   Finally, I tested it with `curl http://localhost:8080`, which returned the default Apache page, confirming my `Dockerfile` was perfect.

### Key Concepts (The "What & Why")

-   **`Dockerfile`**: This is a simple text file that contains a script of instructions for building a Docker image. It's the standard for creating reproducible and automated container builds. By putting my environment setup in a `Dockerfile`, I ensure that anyone on my team can create the exact same image.
-   **`FROM ubuntu:24.04`**: This is the foundation. Every `Dockerfile` must start with a `FROM` instruction, specifying the base image to build upon.
-   **`RUN` instruction**: This command executes a shell command inside the image during the build process. Each `RUN` instruction creates a new layer in the image, which is a key concept for build caching and efficiency.
-   **`CMD` and Foreground Processes**: The `CMD` instruction sets the default command to run when a container starts. A critical lesson is that for a service like a web server, this command **must** run in the foreground. If the command runs in the background, the container will think its main process has finished and will immediately exit. `apache2ctl -D FOREGROUND` is the standard way to achieve this for Apache.

### Commands I Used

-   `sudo mkdir -p /opt/docker`: Creates the required directory. The `-p` flag creates parent directories if they don't exist, which is a good habit.
-   `sudo vi /opt/docker/Dockerfile`: Creates and edits the `Dockerfile` with root privileges.
-   `sudo docker build -t [name:tag] .`: The command to build an image from a `Dockerfile`.
    -   `-t`: **T**ags the image with a human-readable name.
    -   `.`: Specifies that the build context (the files and the `Dockerfile`) is the current directory.
-   `sudo docker run -d -p [host_port]:[container_port] [image_name]`: Runs a container from the newly built image, which I used for verification.
   q