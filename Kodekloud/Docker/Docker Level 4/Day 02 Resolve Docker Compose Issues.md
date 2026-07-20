# Docker Level 4, Task 2: Debugging a Broken `docker-compose.yml` File

Today's task was a very realistic DevOps scenario: I was given a broken Docker Compose file and had to debug it. This was a fantastic exercise because it taught me how to read and interpret Docker Compose's validation errors, which almost always point to syntax issues in the YAML file.

I learned that when it comes to Docker Compose, the most common problems are not with Docker itself, but with the strict indentation and keyword rules of the YAML format. This document is my detailed, first-person account of how I used the error message to find and fix the problems.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: Reading the Error and Fixing the YAML](#deep-dive-reading-the-error-and-fixing-the-yaml)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands Used](#exploring-the-commands-used)

---

### The Task
<a name="the-task"></a>
My objective was to fix a broken `docker-compose.yml` file located at `/opt/docker` on **App Server 3**. The goal was to get the multi-container application defined in the file to run successfully, without changing the specified container names or any other valid settings.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
My approach was to first reproduce the error to understand it, then apply the fix, and finally verify my work by successfully launching the application.

#### Phase 1: The Diagnosis
1.  I connected to App Server 3: `ssh banner@stapp03`.
2.  I navigated to the directory: `cd /opt/docker`.
3.  I attempted to run the compose file to see the error for myself.
    ```bash
    sudo docker compose up
    ```
4.  The command failed as expected. The error message was the key to the entire task:
    ```
    validating /opt/docker/docker-compose.yml: services.web additional properties 'volume', 'depends' not allowed
    ```
    This told me that the keys `volume` and `depends` were considered invalid *at the location they were placed in the file*. This immediately pointed to an indentation or keyword error.

#### Phase 2: The Fix
Based on the error, I knew I had to correct the YAML syntax.
1.  I opened the `docker-compose.yml` file for editing: `sudo vi /opt/docker/docker-compose.yml`.
2.  I identified three distinct errors:
    -   **Incorrect Indentation:** The `redis` service was indented under the `web` service, making it a child. Services must be siblings at the same level.
    -   **Incorrect Keyword:** The key `volume` should be plural: `volumes`.
    -   **Incorrect Keyword:** The key `depends` should be `depends_on`.
3.  I corrected the file to look like this:
    ```yaml
    version: '3.8'

    services:
      web:
        build: ./app
        container_name: python
        ports:
          - "5000:5000"
        # Fixed: 'volumes' is now correctly indented and plural
        volumes:
          - ./app:/code
        # Fixed: 'depends_on' is now correctly indented and named
        depends_on:
          - redis

      # Fixed: 'redis' service is now correctly indented at the same level as 'web'
      redis:
        image: redis:alpine
        container_name: redis
    ```
4.  I saved and quit the file.

#### Phase 3: Verification
With the file corrected, I relaunched the application.
```bash
# Still in /opt/docker directory
sudo docker compose up -d
```
The command now worked, building the `web` image and pulling the `redis` image, then starting both containers. A final check with `sudo docker ps` showed both `python` and `redis` containers in a running state, which was the final proof of success.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
-   **Docker Compose Debugging**: This task was all about learning to debug the configuration file, not the containers themselves. This is a critical skill, as a single syntax error in a `docker-compose.yml` file will prevent the entire application stack from launching.
-   **YAML (YAML Ain't Markup Language)**: This is the language used for Docker Compose files. It's a human-readable data serialization language. Its most important feature is that it uses **indentation** (spaces, not tabs!) to define the structure and relationship between data. This was the root cause of my errors.
-   **Service Dependencies (`depends_on`)**: This is a crucial Docker Compose feature for multi-container applications. By adding `depends_on: - redis` to my `web` service, I am telling Docker Compose: "**Do not start the `web` container until after the `redis` container has been successfully started.**" This is essential for any application that relies on a backend service like a database or cache to be available at startup.

---

### Deep Dive: Reading the Error and Fixing the YAML
<a name="deep-dive-reading-the-error-and-fixing-the-yaml"></a>
The error message `services.web additional properties 'volume', 'depends' not allowed` was my guide. Let's break it down:

[Image of a YAML file with incorrect indentation]

-   **`services.web`**: This is a "path" that points to the exact location of the error in the YAML structure. It means, "Look inside the `services` block, then inside the `web` block."
-   **`additional properties ... not allowed`**: This means Docker Compose found keys (`volume`, `depends`) that it didn't expect to find *in that location*.

**The Original Broken File:**
```yaml
# ...
    web:
        # ...
        ports:
            - "5000:5000"
        volume:          # <-- Indented under 'ports', which is wrong
            - ./app:/code
        depends:         # <-- Indented under 'ports', which is wrong
            - redis
    redis:               # <-- Indented under 'web', which is wrong
        # ...
```

My fix was to correct the structure so that `ports`, `volumes`, and `depends_on` were all direct children of `web`, and `redis` was a direct child of `services`.

**The Corrected File Structure:**
```yaml
services:
  web:
    # ...
    ports:
      # ...
    volumes:
      # ...
    depends_on:
      # ...
  redis:
    # ...
```

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Indentation Errors:** This is the #1 problem in YAML files. Using tabs instead of spaces, or having inconsistent indentation, will always break the file.
-   **Incorrect Keywords:** As I found, using a singular `volume` instead of the plural `volumes`, or `depends` instead of `depends_on`, are common mistakes that the validator will catch.
-   **Forgetting `version`:** While not always strictly required, specifying the `version` at the top of the file is a strong best practice that helps Docker Compose interpret the file correctly.

---

### Exploring the Commands Used
<a name="exploring-the-commands-used"></a>
-   `sudo docker compose up`: The main command to run an application from a `docker-compose.yml` file.
    -   It creates the network, builds any images that need building, pulls any images that need pulling, and then creates and starts the containers.
    -   The `-d` flag is crucial for running the containers in **d**etached (background) mode. Without it, my terminal would be attached to the logs of all the containers.
-   `sudo docker compose down`: This is the complementary command. It stops and removes the containers, and by default, also removes the network that was created.
-   `sudo docker ps`: The standard Docker command to **l**i**s**t running containers. I used this to verify that both my `python` and `redis` containers were successfully launched and running.
-   `sudo vi [file]`: The command-line text editor I used to open and correct the `docker-compose.yml` file.
  