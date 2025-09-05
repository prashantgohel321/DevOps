# Docker Certification: A Complete Walkthrough

I successfully completed the Docker Certification test, which consisted of nine distinct labs designed to test my practical, hands-on skills with the Docker CLI. This document serves as a detailed log of each task, my solution, and the core concepts behind them. It covers the entire lifecycle of Docker objects: from creating containers and networks to managing images, transferring files, and troubleshooting.

## Table of Contents

- [Task 1: Create a Running Nginx Container](#task-1-create-a-running-nginx-container)
- [Task 2: Create a Container and Override CMD](#task-2-create-a-container-and-override-cmd)
- [Task 3: Copy a File From a Container to the Host](#task-3-copy-a-file-from-a-container-to-the-host)
- [Task 4: Copy a File From the Host to a Container](#task-4-copy-a-file-from-the-host-to-a-container)
- [Task 5: Pull Docker Images](#task-5-pull-docker-images)
- [Task 6: Remove Large Docker Images](#task-6-remove-large-docker-images)
- [Task 7: Remove a Docker Network](#task-7-remove-a-docker-network)
- [Task 8: Create a Custom Docker Network](#task-8-create-a-custom-docker-network)
- [Task 9: Restart Exited Containers](#task-9-restart-exited-containers)

---

### Task 1: Create a Running Nginx Container

* **Objective:** On `App Server 1`, create a container named `nginx_1` using the `nginx:alpine` image and ensure it remains running.
* **The "What & Why":** This is the most fundamental Docker command. The goal is to run a pre-built application (Nginx web server) from an image. Using the `-d` (detached) flag is crucial to run the container in the background so it stays alive. The `:alpine` tag specifies a lightweight version of the image, which is a best practice.
* **Solution:**
    ```bash
    sudo docker run -d --name nginx_1 nginx:alpine
    ```
* **Verification:** I used `sudo docker ps` to list all *running* containers. Seeing `nginx_1` in the list with a status of `Up` confirmed success.

---

### Task 2: Create a Container and Override CMD

* **Objective:** On `App Server 1`, create a container named `debug_1` from the `ubuntu/apache2:latest` image, but overwrite its default command with `sleep 1000`.
* **The "What & Why":** A common debugging technique. I needed to start a container with the application's exact environment but prevent the main application (Apache) from starting. By adding a command after the image name (`sleep 1000`), I told Docker to ignore the image's default `CMD` and run my command instead. This keeps the container alive for inspection.
* **Solution:**
    ```bash
    sudo docker run -d --name debug_1 ubuntu/apache2:latest sleep 1000
    ```
* **Verification:** The key was to check the `COMMAND` column in the output of `sudo docker ps`. Seeing `"sleep 1000"` confirmed I had successfully overridden the default.

---

### Task 3: Copy a File From a Container to the Host

* **Objective:** On `App Server 1`, copy `/tmp/test.txt.gpg` from the `development_3` container to the `/tmp` directory on the host.
* **The "What & Why":** Containers have isolated filesystems. The `docker cp` command is the bridge to move files across this boundary. This is essential for extracting logs, data, or artifacts from a container for analysis or backup.
* **Solution:**
    ```bash
    sudo docker cp development_3:/tmp/test.txt.gpg /tmp
    ```
* **Verification:** I ran `ls -l /tmp/test.txt.gpg` on the host server. The file's presence confirmed the successful copy.

---

### Task 4: Copy a File From the Host to a Container

* **Objective:** On `App Server 1`, copy `/tmp/nautilus.txt.gpg` from the host into the `/usr/src/` directory inside the `ubuntu_latest` container.
* **The "What & Why":** This is the reverse of the previous task and is fundamental for deploying code, injecting configuration, or providing data to an application running inside a container. A great feature of `docker cp` is that it automatically creates the destination directory (`/usr/src/`) if it doesn't already exist.
* **Solution:**
    ```bash
    sudo docker cp /tmp/nautilus.txt.gpg ubuntu_latest:/usr/src/
    ```
* **Verification:** I ran a command *inside* the container using `docker exec` to confirm the file had arrived: `sudo docker exec ubuntu_latest ls -l /usr/src/nautilus.txt.gpg`.

---

### Task 5: Pull Docker Images

* **Objective:** On `App Server 1`, download the `redis:alpine` and `memcached:alpine` images.
* **The "What & Why":** The `docker pull` command pre-downloads images from a registry (like Docker Hub) to the local server. This saves time during deployments, as the `docker run` command won't have to download them. It's a common pre-caching step in automated workflows.
* **Solution:**
    ```bash
    sudo docker pull redis:alpine
    sudo docker pull memcached:alpine
    ```
* **Verification:** The `sudo docker images` command lists all images stored locally. I confirmed that both `redis:alpine` and `memcached:alpine` were present in the list.

---

### Task 6: Remove Large Docker Images

* **Objective:** On `App Server 1`, find and delete all Docker images larger than 100MB.
* **The "What & Why":** A critical housekeeping task. Docker images can consume significant disk space. Regularly removing large, unused images is essential for managing storage on the host server.
* **Solution:** For the test, I identified the large images with `sudo docker images` and removed them one by one.
    ```bash
    # First, identify the image ID
    sudo docker images
    
    # Then, remove it
    sudo docker rmi [IMAGE_ID]
    ```
    * **Pro Tip:** For future use, I learned a powerful one-liner to automate this:
        ```bash
        sudo docker images | awk '($NF ~ /GB/) || ($NF ~ /MB/ && substr($NF, 1, length($NF)-2) > 100) {print $3}' | xargs sudo docker rmi -f
        ```
* **Verification:** I ran `sudo docker images` again and confirmed that no images with a size greater than 100MB remained.

---

### Task 7: Remove a Docker Network

* **Objective:** On `App Server 1`, delete the Docker network named `php-network`.
* **The "What & Why":** As applications are deployed and removed, their custom networks can be left behind. Cleaning up these unused networks is good practice to avoid clutter and prevent potential networking conflicts.
* **Solution:**
    ```bash
    sudo docker network rm php-network
    ```
* **Verification:** I ran `sudo docker network ls` and confirmed that `php-network` was no longer in the list.

---

### Task 8: Create a Custom Docker Network

* **Objective:** On `App Server 1`, create a `bridge` network named `mysql-network` with a specific subnet and gateway.
* **The "What & Why":** This is a best practice for multi-container applications. Custom bridge networks provide better isolation and, most importantly, automatic DNS resolution, allowing containers to communicate using their names instead of IP addresses. Defining a subnet gives me precise control over the network's IP range.
* **Solution:**
    ```bash
    sudo docker network create --driver bridge --subnet 182.18.0.0/24 --gateway 182.18.0.1 mysql-network
    ```
* **Verification:** I used `sudo docker network inspect mysql-network` and checked the `IPAM` (IP Address Management) section of the JSON output to confirm that my specified subnet and gateway were configured correctly.

---

### Task 9: Restart Exited Containers

* **Objective:** On `App Server 1`, find the stopped containers `lab1_container` and `lab2_container` and get them running.
* **The "What & Why":** A common real-world task. Containers can stop for various reasons. The `docker start` command is used to restart an *existing* container that is in an `Exited` or `Created` state, reusing its configuration. This is different from `docker run`, which creates a new container.
* **Solution:** I started both containers efficiently with a single command.
    ```bash
    sudo docker start lab1_container lab2_container
    ```
* **Verification:** I ran `sudo docker ps` (without the `-a` flag) to list only the *running* containers. Seeing both `lab1_container` and `lab2_container` in this list with a status of `Up` confirmed the final task was complete.
