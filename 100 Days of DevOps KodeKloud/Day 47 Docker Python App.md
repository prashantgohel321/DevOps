# DevOps Day 47: "Dockerizing" a Python Application from Scratch

Today's task was another excellent, real-world scenario that is central to modern software development: "Dockerizing" an application. I was given the source files for a Python web application and had to create a portable, self-contained Docker image for it. This involved writing a `Dockerfile` from scratch, building the custom image, and finally running it as a container.

This exercise reinforced the standard pattern for building application images, particularly how to handle dependencies and optimize the build process using Docker's layer caching. It was a complete end-to-end workflow, from source code to a running, containerized application. This document is my detailed, first-person guide to that entire process.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: A Line-by-Line Explanation of My Python `Dockerfile`](#deep-dive-a-line-by-line-explanation-of-my-python-dockerfile)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands I Used](#exploring-the-commands-i-used)

---

### The Task
<a name="the-task"></a>
My objective was to take a Python application located in `/python_app` on **App Server 2** and create a running container from it. The specific requirements were:
1.  Create a `Dockerfile` in the `/python_app` directory.
2.  Use a `python` image as the base.
3.  The `Dockerfile` must install the app's dependencies from the `/python_app/src/requirements.txt` file.
4.  The container's default command should be to run `server.py`.
5.  The image must expose port `8088`.
6.  Build an image from this `Dockerfile` and name it `nautilus/python-app`.
7.  Run a container from this image named `pythonapp_nautilus`.
8.  Map the host port `8097` to the container's port `8088`.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The solution followed a logical progression: write the recipe (`Dockerfile`), build the image, and then run the container.

#### Phase 1: Writing the `Dockerfile`
First, I needed to create the blueprint for my custom image.
1.  I connected to App Server 2: `ssh steve@stapp02`.
2.  I navigated to the application directory: `cd /python_app`.
3.  I created and edited the `Dockerfile`: `sudo vi Dockerfile`.
4.  Inside the editor, I wrote the following optimized instructions for a Python app:
    ```dockerfile
    # Start from an official Python runtime. Using a 'slim' variant is a good practice.
    FROM python:3.9-slim

    # Set the working directory inside the container.
    WORKDIR /app

    # Copy the requirements file from the host's src directory first.
    # This is a key optimization for layer caching.
    COPY src/requirements.txt .

    # Install the Python dependencies.
    RUN pip install --no-cache-dir -r requirements.txt

    # Copy the rest of the application's source code from the host's src directory.
    COPY src/ .

    # Document that the application listens on this port.
    EXPOSE 8088

    # The command to run when the container starts.
    CMD ["python", "server.py"]
    ```
5.  I saved and quit the file.

#### Phase 2: Building the Custom Image
With the recipe written, I could now build the image.
1.  Ensuring I was still in the `/python_app` directory, I ran the build command, giving it the required tag (`-t`).
    ```bash
    sudo docker build -t nautilus/python-app .
    ```
2.  After the build completed, I verified its existence with `sudo docker images`, which showed `nautilus/python-app` at the top of the list.

#### Phase 3: Running the Container
The final step was to launch the application.
1.  I ran the container using the image I just built, specifying the name and port mapping.
    ```bash
    sudo docker run -d --name pythonapp_nautilus -p 8097:8088 nautilus/python-app
    ```
2.  I first verified the container was running with `sudo docker ps`, which showed the `pythonapp_nautilus` container and the `0.0.0.0:8097->8088/tcp` port mapping.
3.  Finally, I performed the required test with `curl`.
    ```bash
    curl http://localhost:8097
    ```
    I received the success message from the Python web application, confirming the entire process was successful.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **"Dockerizing" an Application**: This is the core process of creating a self-contained, portable package for an application. By putting my Python app in a Docker image, I ensure that it runs the same way everywhere, because it always brings its own environment (the correct Python version and all its dependencies) with it.
-   **`requirements.txt`**: This is the standard file used in the Python ecosystem to declare a project's library dependencies.
-   **`pip install -r requirements.txt`**: This is the command for the **P**ackage **I**nstaller for **P**ython. When run inside the Dockerfile with the `-r` (requirements) flag, it reads the `requirements.txt` file and installs all the necessary libraries from the Python Package Index (PyPI).
-   **Layer Caching Optimization**: The order of operations in my `Dockerfile` is very important. By copying `requirements.txt` first and running `pip install` *before* copying the rest of the source code, I take advantage of Docker's layer caching. My dependencies don't change very often, but my source code does. This way, if I only change `server.py` and rebuild, Docker can reuse the expensive, time-consuming `pip install` layer from its cache, making my rebuilds significantly faster.

---

### Deep Dive: A Line-by-Line Explanation of My Python `Dockerfile`
<a name="deep-dive-a-line-by-line-explanation-of-my-python-dockerfile"></a>
This `Dockerfile` follows a standard and highly optimized pattern for Python applications.

[Image of a Python Dockerfile build process]

```dockerfile
# 1. Start from an official Python base image. 'slim' is a good choice as it's smaller
# than the full image but has all the common tools.
FROM python:3.9-slim

# 2. Set the working directory inside the image. All subsequent commands
# (COPY, RUN, CMD) will be run relative to this /app directory.
WORKDIR /app

# 3. Copy the dependency manifest first for layer cache optimization.
# The source path is relative to the build context ('/python_app' on my host).
COPY src/requirements.txt .

# 4. Install dependencies. This creates a new layer that only contains the installed
# packages. This layer will be cached and reused as long as requirements.txt doesn't change.
# '--no-cache-dir' is a good practice to keep the image size down.
RUN pip install --no-cache-dir -r requirements.txt

# 5. Copy the application source code.
# The '.' copies everything from the host's 'src' directory into the image's '/app' directory.
COPY src/ .

# 6. Expose the port. This is documentation for the user and for Docker.
EXPOSE 8088

# 7. Define the startup command. This tells the container to run 'python server.py'
# when it starts, which launches the application. It runs in the foreground,
# which is essential for keeping the container alive.
CMD ["python", "server.py"]
```

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Inefficient Layering:** The most common mistake is to copy all the source code (`COPY src/ .`) *before* running `pip install`. This breaks the caching optimization, because a small change to any source file would force a slow re-installation of all dependencies on every single build.
-   **Forgetting `requirements.txt`:** If the `requirements.txt` file is not copied into the image, `pip install` will fail, and the application will crash at runtime from missing libraries.
-   **Incorrect Source Path in `COPY`:** The `COPY` command's source path is relative to the build context. Since my `requirements.txt` and `server.py` were in a `src` subfolder, I had to use `COPY src/...`. A common mistake is to forget this and write `COPY requirements.txt .`, which would fail.

---

### Exploring the Commands I Used
<a name="exploring-the-commands-i-used"></a>
-   `sudo vi Dockerfile`: The command to create and edit my `Dockerfile`.
-   `sudo docker build -t nautilus/python-app .`: The command to build my custom image.
    -   `-t`: **T**ags the image with the specified name (`repository/name`).
    -   `.`: Sets the build context to the current directory (`/python_app`).
-   `sudo docker run -d --name pythonapp_nautilus -p 8097:8088 nautilus/python-app`: The command to run my application.
    -   `-d`: Runs the container in **d**etached mode.
    -   `--name`: Assigns a specific name to my container.
    -   `-p 8097:8088`: **P**ublishes the port, mapping the host's port 8097 to the container's port 8088.
-   `curl http://localhost:8097`: My final verification step to test that the running application was accessible and responding correctly.
  