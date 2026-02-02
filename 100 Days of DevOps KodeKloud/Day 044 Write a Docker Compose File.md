# DevOps Day 44: Declarative Container Management with Docker Compose

Today's task was a major step up in how I manage containers. I moved from using long, imperative `docker run` commands to defining my application's configuration declaratively using a **Docker Compose** file. This is the standard, professional way to manage containerized applications, making them version-controlled, reproducible, and easy to understand.

My objective was to deploy an `httpd` (Apache) web server, but instead of typing out all the port and volume mapping flags, I codified them into a simple, readable `docker-compose.yml` file. This was a fantastic exercise in "Infrastructure as Code" at the container level.

### The Task

My objective was to deploy a containerized `httpd` server on **App Server 1** using a Docker Compose file. The specific requirements were:
-   The configuration must be in a file named exactly `/opt/docker/docker-compose.yml`.
-   The container must use the `httpd:latest` image.
-   The container itself must be named `httpd`.
-   Host port `8083` had to be mapped to container port `80`.
-   The host directory `/opt/data` had to be mapped as a volume to the container's document root, `/usr/local/apache2/htdocs`.

### My Step-by-Step Solution

1.  **Prepare the Host:** I first connected to App Server 1 (`ssh tony@stapp01`). I then created the necessary directories on the host system.
    ```bash
    sudo mkdir -p /opt/docker /opt/data
    ```

2.  **Create the `docker-compose.yml` file:** This was the core of the task. I created the file (`sudo vi /opt/docker/docker-compose.yml`) and wrote the following YAML configuration, paying close attention to the indentation.
    ```yaml
    version: '3.8'

    services:
      apache_service:
        image: httpd:latest
        container_name: httpd
        ports:
          - "8083:80"
        volumes:
          - /opt/data:/usr/local/apache2/htdocs
    ```

3.  **Launch the Application:** With the configuration file in place, launching the container was incredibly simple. I first navigated to the correct directory.
    ```bash
    cd /opt/docker
    ```
    Then, I launched the entire stack with a single command.
    ```bash
    sudo docker compose up -d
    ```

4.  **Verification:** The final step was to confirm everything was running as defined in my file. I ran `sudo docker ps` and the output showed a single container running with all the correct attributes: the name `httpd`, the `httpd:latest` image, and the `0.0.0.0:8083->80/tcp` port mapping. This was the definitive proof of success.

### Key Concepts (The "What & Why")

-   **Docker Compose**: This is a tool for defining and running multi-container Docker applications. Even for a single container like in this task, it's a best practice because it makes your configuration declarative and easy to manage.
-   **Declarative vs. Imperative**: This is the key difference.
    -   `docker run ...`: This is **imperative**. I am giving the computer a long, detailed command telling it *how* to run a container. It's a one-time action.
    -   `docker-compose.yml`: This is **declarative**. I am creating a file that describes *what* my final application should look like (one container, with these ports, and these volumes). I then let Docker Compose figure out the "how."
-   **Benefits of Docker Compose**:
    1.  **Readability and Simplicity:** The YAML file is much easier for humans to read and understand than a long `docker run` command with many flags.
    2.  **Version Control:** I can check my `docker-compose.yml` file into Git. This means my entire application's configuration is version-controlled, and I can track every change.
    3.  **Reproducibility:** Anyone on my team can clone the repository, run `docker compose up`, and get the exact same environment running instantly.

### Commands I Used

-   `sudo mkdir -p /opt/docker /opt/data`: **M**a**k**es **dir**ectories. The `-p` flag creates parent directories if they don't exist, which is a good habit.
-   `sudo vi /opt/docker/docker-compose.yml`: Creates and edits the YAML configuration file with root privileges.
-   `cd /opt/docker`: A critical step to **c**hange **d**irectory into the location of the compose file before running it.
-   `sudo docker compose up -d`: The hero command.
    -   `docker compose`: The main command for interacting with the Docker Compose tool.
    -   `up`: The subcommand to create and start the application as defined in the `.yml` file.
    -   `-d`: Runs the containers in **d**etached (background) mode.
-   `sudo docker ps`: The standard Docker command to **l**i**s**t running containers. I used this to verify that my container was created with the correct name, image, and port/volume mappings as defined in my compose file.
  