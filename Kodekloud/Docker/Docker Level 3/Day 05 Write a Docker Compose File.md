# Docker Level 3, Task 5: Graduating to Docker Compose

Today's task was the perfect culmination of my Docker learning so far. I moved from running individual containers with long, imperative `docker run` commands to defining my application declaratively using **Docker Compose**. This is the standard, professional way to manage containerized applications.

The objective was to deploy an `httpd` (Apache) web server, but instead of typing out all the port and volume mapping flags, I codified them into a simple, readable `docker-compose.yml` file. This was a huge step forward in creating infrastructure that is version-controlled, reproducible, and easy to understand.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: A Line-by-Line Breakdown of My `docker-compose.yml` File](#deep-dive-a-line-by-line-breakdown-of-my-docker-compose.yml-file)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands Used](#exploring-the-commands-used)

---

### The Task
<a name="the-task"></a>
My objective was to deploy a containerized `httpd` server on **App Server 3** using a Docker Compose file. The specific requirements were:
1.  The configuration must be in a file named exactly `/opt/docker/docker-compose.yml`.
2.  The container must use the `httpd:latest` image.
3.  The container itself must be named `httpd`.
4.  Host port `5003` had to be mapped to container port `80`.
5.  The host directory `/opt/dba` had to be mapped as a volume to the container's document root, `/usr/local/apache2/htdocs`.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The process was very clean and involved two main phases: creating the configuration file and then launching the application with a single command.

#### Phase 1: Creating the `docker-compose.yml` File
First, I needed to write the "recipe" for my application.
1.  I connected to App Server 3: `ssh banner@stapp03`.
2.  I created the required directory, as `/opt` is a system folder that needs `sudo`.
    ```bash
    sudo mkdir -p /opt/docker
    ```
3.  I created and edited the YAML file: `sudo vi /opt/docker/docker-compose.yml`.
4.  Inside the editor, I wrote the following configuration, paying close attention to the YAML indentation.
    ```yaml
    version: '3.8'

    services:
      httpd_service:
        image: httpd:latest
        container_name: httpd
        ports:
          - "5003:80"
        volumes:
          - /opt/dba:/usr/local/apache2/htdocs
    ```
5.  I saved and quit the file.

#### Phase 2: Launching the Application
With the configuration file in place, launching the container was incredibly simple.
1.  I navigated to the directory containing my file. This is a crucial step, as `docker compose` looks for the `.yml` file in the current directory by default.
    ```bash
    cd /opt/docker
    ```
2.  I ran a single command to bring my application to life.
    ```bash
    sudo docker compose up -d
    ```

#### Phase 3: Verification
The final step was to confirm everything was running as defined in my file.
1.  I ran `sudo docker ps`.
2.  The output showed a single container running with all the correct attributes:
    -   **NAME:** `httpd`
    -   **IMAGE:** `httpd:latest`
    -   **PORTS:** `0.0.0.0:5003->80/tcp`
This was the definitive proof that my `docker-compose.yml` file was correctly written and executed.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
-   **Docker Compose**: This is a tool for defining and running multi-container Docker applications. While I only used it for a single container in this task, its real power shines when you have an application with multiple services (like a web server, a database, and a cache) that need to work together.
-   **Declarative vs. Imperative**: This is the key difference.
    -   `docker run ...`: This is **imperative**. I am giving the computer a long, detailed command telling it *how* to run a container.
    -   `docker-compose.yml`: This is **declarative**. I am creating a file that describes *what* my final application should look like (one container, with these ports, and these volumes). I then let Docker Compose figure out the "how."
-   **Benefits of Docker Compose**:
    1.  **Readability and Simplicity:** The YAML file is much easier for humans to read and understand than a long, complex `docker run` command.
    2.  **Version Control:** I can check my `docker-compose.yml` file into Git. This means my entire application's configuration is version-controlled, and I can track every change.
    3.  **Reproducibility:** Anyone on my team can clone the repository, run `docker compose up`, and get the exact same environment running instantly.

---

### Deep Dive: A Line-by-Line Breakdown of My `docker-compose.yml` File
<a name="deep-dive-a-line-by-line-breakdown-of-my-docker-compose.yml-file"></a>
Understanding the syntax of this file was the core of the task. YAML is sensitive to indentation (usually 2 spaces), which defines the structure.



```yaml
# Specifies the version of the Docker Compose file format. '3.8' is a modern, common version.
version: '3.8'

# This is the top-level key where all the application's containers are defined.
services:

  # This is the name of my service. I can call it anything I want (e.g., "web", "apache").
  # It's used to refer to this container within the Docker Compose environment.
  httpd_service:

    # Specifies the Docker image to use for this service.
    image: httpd:latest

    # This is an important distinction. It sets the ACTUAL name of the container
    # that I will see when I run 'docker ps'.
    container_name: httpd

    # This section defines the port mappings. It's a list.
    ports:
      # Each item in the list is a string in "HOST:CONTAINER" format.
      - "5003:80"

    # This section defines the volume mappings. It's also a list.
    volumes:
      # Each item is a string in "HOST_PATH:CONTAINER_PATH" format.
      - /opt/dba:/usr/local/apache2/htdocs
      ```

```

### Common Pitfalls
<a name="common-pitfalls"></a>

- **YAML Indentation Errors**: The most common problem with Docker Compose is incorrect indentation. A single wrong space can cause the file to be invalid.

- **Running docker compose from the Wrong Directory**: The `docker compose up` command must be run from the directory containing the `docker-compose.yml` file, or you have to specify the file's path with the `-f` flag.

- **container_name vs. Service Name**: It's easy to get confused. The service name (`httpd_service` in my file) is for Docker Compose's internal use. The `container_name` is what sets the actual name you see in `docker ps`.

- **Incorrect Port/Volume Syntax**: The syntax is always a string `"HOST:CONTAINER"`. Reversing them or using incorrect syntax will cause errors.

---

### Exploring the Commands Used
<a name="exploring-the-commands-used"></a>

- **`sudo mkdir -p /opt/docker`**: Makes a directory. The -p flag creates parent directories if they don't exist, which is a good habit.

- **`sudo vi /opt/docker/docker-compose.yml`**: Creates and edits the YAML configuration file with root privileges.

- **`sudo docker compose up -d`**: This is the hero command.

    - **`docker compose`**: The main command for interacting with the Docker Compose tool.

    - **`up`**: The subcommand to create and start the application as defined in the .yml file.

    - **`-d`**: Runs the containers in detached (background) mode.

- **`sudo docker ps`**: The standard Docker command to list running containers. I used this to verify that my container was created with the correct name, image, and port/volume mappings as defined in my compose file.