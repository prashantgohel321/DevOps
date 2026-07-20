# Docker Level 4, Task 3: Deploying a Two-Tier Application with Docker Compose

Today's task was the culmination of everything I've learned about Docker Compose. I was tasked with defining and deploying a classic **two-tier application stack**—a PHP web server and a MariaDB database—using a single configuration file. This is a perfect, real-world example of how modern web applications are developed and deployed in a containerized environment.

I learned how to define multiple, interconnected "services" in one `docker-compose.yml` file, and how to use environment variables to securely configure the database on its first startup. This was a fantastic exercise in orchestrating a complete application stack with a single, simple command.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: A Line-by-Line Breakdown of My Multi-Service Compose File](#deep-dive-a-line-by-line-breakdown-of-my-multi-service-compose-file)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands Used](#exploring-the-commands-used)

---

### The Task
<a name="the-task"></a>
My objective was to deploy a two-container application stack on **App Server 3** using a single Docker Compose file located at `/opt/finance/docker-compose.yml`.

**Web Service Requirements:**
-   Container Name: `php_host`
-   Image: `php:apache`
-   Ports: Map host port `8088` to container port `80`.
-   Volumes: Map host directory `/var/www/html` to container directory `/var/www/html`.

**Database Service Requirements:**
-   Container Name: `mysql_host`
-   Image: `mariadb:latest`
-   Ports: Map host port `3306` to container port `3306`.
-   Volumes: Map host directory `/var/lib/mysql` to container directory `/var/lib/mysql`.
-   Environment: Set the database name to `database_host` and configure a custom user and password.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The solution involved preparing the host system with the necessary directories, writing a single YAML file to define the entire application, and then launching it with one command.

#### Phase 1: Preparing the Host and Writing the Compose File
1.  I connected to App Server 3: `ssh banner@stapp03`.
2.  I created all the required directories on the host machine at once. This is a crucial prerequisite for the bind mounts to work correctly.
    ```bash
    sudo mkdir -p /opt/finance /var/www/html /var/lib/mysql
    ```
3.  I created and edited the main configuration file: `sudo vi /opt/finance/docker-compose.yml`.
4.  Inside the editor, I wrote the complete definition for my two-tier application:
    ```yaml
    version: '3.8'

    services:
      web:
        image: php:apache
        container_name: php_host
        ports:
          - "8088:80"
        volumes:
          - /var/www/html:/var/www/html

      db:
        image: mariadb:latest
        container_name: mysql_host
        ports:
          - "3306:3306"
        volumes:
          - /var/lib/mysql:/var/lib/mysql
        environment:
          MYSQL_DATABASE: database_host
          MYSQL_USER: kodekloud_user
          MYSQL_PASSWORD: SomeVeryComplexPassword123!
          MYSQL_ROOT_PASSWORD: AnotherSecurePassword456!
    ```
5.  I saved and quit the file.

#### Phase 2: Launching the Application Stack
1.  I navigated to the directory containing my configuration file. This is essential for the `docker compose` command to find the file automatically.
    ```bash
    cd /opt/finance
    ```
2.  I launched the entire stack with a single command.
    ```bash
    sudo docker compose up -d
    ```

#### Phase 3: Verification
The final step was to confirm that both containers were running and configured as I had defined them.
1.  I ran `sudo docker ps`.
2.  The output showed **two** running containers, `php_host` and `mysql_host`, with their respective port mappings listed correctly. This was the definitive proof that my `docker-compose.yml` file had successfully orchestrated the deployment of the entire application.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
-   **Docker Compose**: This is the standard tool for defining and running multi-container applications. This task perfectly illustrated its power. Instead of two long `docker run` commands and a separate `docker network create` command, I defined everything in one simple, version-controllable file.
-   **Two-Tier Architecture**: This is a fundamental pattern in web development.
    -   **Tier 1 (Web Service):** The `php_host` container is the presentation layer. It handles incoming HTTP requests from users and runs the PHP application code.
    -   **Tier 2 (DB Service):** The `mysql_host` container is the data layer. It's responsible for storing and retrieving all the application's data. Separating these concerns makes the application more scalable and easier to manage.
-   **Environment Variables (`environment` key)**: This is the correct and secure way to pass configuration into a container. The official `mariadb` image is specifically designed to look for these environment variables (`MYSQL_DATABASE`, `MYSQL_USER`, etc.) on its very first startup. It uses them to automatically initialize the database, create the user, and set the passwords. This is a powerful automation feature that avoids having to manually configure the database after it starts.

---

### Deep Dive: A Line-by-Line Breakdown of My Multi-Service Compose File
<a name="deep-dive-a-line-by-line-breakdown-of-my-multi-service-compose-file"></a>
This `docker-compose.yml` file defines two distinct but related services. Docker Compose automatically creates a shared network for them so they can communicate.

[Image of a two-tier application stack with a web and DB container]

```yaml
# Specifies the version of the Docker Compose file format.
version: '3.8'

# The top-level key where all the application's services (containers) are defined.
services:

  # This is the definition for my first service, the web server.
  # 'web' is the service name. On the internal Docker network, the 'db' service
  # could connect to this service using the hostname 'web'.
  web:
    image: php:apache         # The image to use (PHP with Apache built-in).
    container_name: php_host  # The specific name for the container.
    ports:
      - "8088:80"             # Maps host port 8088 to container port 80.
    volumes:
      - /var/www/html:/var/www/html # Maps the host's web root to the container's web root.

  # This is the definition for my second service, the database.
  db:
    image: mariadb:latest        # The image to use.
    container_name: mysql_host   # The specific name for the container.
    ports:
      - "3306:3306"              # Maps the standard MySQL port.
    volumes:
      - /var/lib/mysql:/var/lib/mysql # Persists the database data on the host.
    
    # This block passes environment variables directly into the container.
    # The MariaDB image uses these variables to auto-configure itself on first run.
    environment:
      MYSQL_DATABASE: database_host # Creates the database.
      MYSQL_USER: kodekloud_user    # Creates the user.
      MYSQL_PASSWORD: SomeVeryComplexPassword123! # Sets the user's password.
      MYSQL_ROOT_PASSWORD: AnotherSecurePassword456! # Sets the root password.
```

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Forgetting to Create Host Directories:** If the host directories for the bind mounts (`/var/www/html`, `/var/lib/mysql`) didn't exist, Docker would create them as `root`. This can lead to permission errors where the application inside the container can't write to the volume. Creating them beforehand is a best practice.
-   **YAML Indentation Errors:** A single incorrect space can invalidate the entire file. All keys under a service (`image`, `ports`, etc.) must have the same indentation.
-   **Using the Wrong Environment Variable Names:** The official `mariadb` image looks for very specific variable names (e.g., `MYSQL_ROOT_PASSWORD`). Using a different name (e.g., `ROOT_PASSWORD`) would cause the auto-configuration to fail. Always check the image's documentation on Docker Hub.
-   **Forgetting `-d`:** Running `docker compose up` without the `-d` flag would attach my terminal to the logs of *both* containers, which can be very noisy and confusing.

---

### Exploring the Commands Used
<a name="exploring-the-commands-used"></a>
-   `sudo mkdir -p [paths...]`: A single command to create multiple directories and their parent directories if they don't exist. I used this to prepare the host.
-   `sudo vi /opt/finance/docker-compose.yml`: Creates and edits the YAML configuration file with root privileges.
-   `sudo docker compose up -d`: The main command for this task.
    -   `docker compose`: The main command for interacting with the Docker Compose tool.
    -   `up`: The subcommand to create and start the application stack defined in the `.yml` file.
    -   `-d`: Runs the containers in **d**etached (background) mode.
-   `sudo docker ps`: The standard Docker command to **l**i**s**t running containers. I used this to verify that both my `php_host` and `mysql_host` containers were successfully launched and running.
  