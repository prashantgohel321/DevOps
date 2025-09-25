# Docker Level 2, Task 5: Building Custom Images with a `Dockerfile`

Today's task was a major step up. I moved from using and managing existing Docker images to creating my own from scratch. This is the absolute core of using Docker for application development. I learned how to write a `Dockerfile`, which is a recipe for building a custom, reproducible image.

This process taught me how to codify an application's environment—from the base operating system to package installation and configuration—into a single, version-controlled text file. This is the foundation of "Infrastructure as Code" in the container world.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: The `Dockerfile` Instructions and Image Layers](#deep-dive-the-dockerfile-instructions-and-image-layers)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands Used](#exploring-the-commands-used)

---

### The Task
<a name="the-task"></a>
My objective was to create a custom Docker image on **App Server 1** by writing a `Dockerfile`. The specific requirements for the image were:
1.  The `Dockerfile` must be located at `/opt/docker/Dockerfile`.
2.  The base image must be `ubuntu:24.04`.
3.  The final image must have `apache2` installed.
4.  The Apache server must be configured to listen on port `8083`.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The process involved creating the `Dockerfile` and then, for verification, building the image and running a container from it.

#### Step 1: Prepare the Environment
First, I connected to App Server 1 (`ssh tony@stapp01`). The task required the `Dockerfile` to be in a specific location, so I created the directory first. Since `/opt` is owned by `root`, I needed `sudo`.
```bash
sudo mkdir -p /opt/docker
```

#### Step 2: Create the `Dockerfile`
I created and edited the `Dockerfile` using `vi`.
```bash
sudo vi /opt/docker/Dockerfile
```
Inside the editor, I wrote the following instructions:
```dockerfile
# Use ubuntu:24.04 as the base image
FROM ubuntu:24.04

# Update package lists and install apache2 non-interactively
RUN apt-get update && apt-get install -y apache2

# Use sed to find the default Listen port (80) and replace it with 8083
RUN sed -i 's/Listen 80/Listen 8083/g' /etc/apache2/ports.conf

# Expose the new port for documentation and networking purposes
EXPOSE 8083

# The command to start Apache in the foreground when the container runs
CMD ["apache2ctl", "-D", "FOREGROUND"]
```
I then saved and quit the file.

#### Step 3: Verification (The Professional Way)
The task was technically complete, but I wanted to prove my `Dockerfile` actually worked.
1.  **Build the Image:** I navigated to the directory and used the `docker build` command. The `-t` flag gives the image a name (`my-apache-app:latest`), and the `.` tells Docker to use the `Dockerfile` in the current directory.
    ```bash
    cd /opt/docker
    sudo docker build -t my-apache-app:latest .
    ```
2.  **Run a Container:** I launched a container from my new image, mapping the host's port 8083 to the container's port 8083.
    ```bash
    sudo docker run -d -p 8083:8083 --name test-apache my-apache-app:latest
    ```
3.  **Test the Service:** Finally, I used `curl` to test if my new Apache server was responding on the correct port.
    ```bash
    curl http://localhost:8083
    ```
> I received the HTML for the "Apache2 Ubuntu Default Page," which was the definitive proof that my Dockerfile was perfect.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>

- **`Dockerfile`**: This is a simple text file that contains a script of instructions for building a Docker image. It's the standard for creating reproducible and automated container builds. By putting my environment setup in a `Dockerfile`, I ensure that anyone on my team can create the exact same image.

- **Reproducibility**: This is the core benefit. Instead of manually modifying a container (like I did in a previous task), a Dockerfile provides a version-controlled, documented, and automated way to create an image. This is essential for CI/CD pipelines.

---

### Deep Dive: The Dockerfile Instructions and Image Layers
<a name="deep-dive-the-dockerfile-instructions-and-image-layers"></a>
This task helped me understand the most common Dockerfile instructions and the concept of layering.

- **`FROM ubuntu:24.04`**: This is the foundation. Every **`Dockerfile`** must start with a **`FROM`** instruction, specifying the base image to build upon.

- **`RUN apt-get update && ..`**.: The **`RUN`** instruction executes a command. Each RUN command creates a new, read-only layer on top of the previous one. This is a key feature. If I were to change my **`CMD`** instruction later and rebuild, Docker would use the cached layers from the **`FROM`** and **`RUN`** steps, making the rebuild almost instant.

- **`EXPOSE 8083`**: This is a form of documentation. It tells Docker (and other developers) that a container from this image is intended to listen on this port. It doesn't actually publish the port; you still have to do that with the -p flag in docker run.

- **`CMD ["apache2ctl", "-D", "FOREGROUND"]`**: This sets the default command to be executed when a container is started. The most critical part here is **`-D FOREGROUND`**. Docker containers only stay alive as long as their main process is running in the foreground. If I had used a command that started Apache in the background (like service apache2 start), the command would finish instantly, and the container would think its job was done and immediately exit.

---

### Common Pitfalls
<a name="common-pitfalls"></a>

- **Using a Background Command in `CMD`**: This is the most common beginner mistake. It causes the container to exit immediately after starting. The main process must run in the foreground.

- **Forgetting apt-get update**: Trying to install packages without first updating the package list will often fail with `"package not found"` errors. Chaining it with `&&` in the same `RUN` command is a common and efficient pattern.

- **Case Sensitivity**: The file must be named `Dockerfile` with a capital `'D'`. Naming it dockerfile would cause the docker build command to fail unless you explicitly pointed to the file with the -f flag.

- **Permissions**: I needed `sudo` to create the directory in `/opt` and to build the image, as Docker daemon operations require root privileges.

---

### Exploring the Commands Used
<a name="exploring-the-commands-used"></a>

- `sudo mkdir -p /opt/docker`: Creates the required directory. The `-p` flag creates parent directories if they don't exist.

- `sudo vi /opt/docker/Dockerfile`: Creates and edits the Dockerfile with root privileges.

- `sudo docker build -t [name:tag] .`: The command to build an image.

    - `-t`: Tags the image with a human-readable name and version.

    - `.`: Specifies the build context (the current directory), where Docker will look for the Dockerfile.

- `sudo docker run -d -p [host_port]:[container_port] [image_name]`: Runs a container from the newly built image.

