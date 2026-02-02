# DevOps Day 39: Creating a Docker Image from a Running Container

Today's task was a practical exercise in a very useful, though less common, method of creating Docker images. Instead of writing a `Dockerfile`, my objective was to create a new image by "snapshotting" the current state of a container that was already running. This is a powerful technique for debugging and capturing a specific, manually configured state.

I learned how to use the `docker commit` command to save a container's changes as a new, reusable image. This document is my first-person guide to that process, explaining the concepts and the commands I used.

### The Task

My objective was to create a new Docker image on **App Server 1**. The specific requirements were:
-   The new image must be named `news:devops`.
-   It had to be created from the current state of a running container named `ubuntu_latest`.

### My Step-by-Step Solution

1.  **Connect to the Server:** I first logged into App Server 1 (`ssh tony@stapp01`).

2.  **Verify the Source Container:** As a best practice, I confirmed that the source container was running using `sudo docker ps`. This showed the `ubuntu_latest` container with an "Up" status.

3.  **Create the Image from the Container:** This was the core of the task. I used a single `docker commit` command.
    ```bash
    sudo docker commit ubuntu_latest news:devops
    ```
    The command returned the unique ID of the new image, which was my first sign of success.

4.  **Verification:** The crucial final step was to confirm that my new image existed. I used the `docker images` command.
    ```bash
    sudo docker images
    ```
    The output clearly showed my new `news:devops` image at the top of the list, which was the definitive proof that my task was completed successfully.

### Key Concepts (The "What & Why")

-   **`docker commit`**: This is the key command for this task. It takes a container's current state—including any changes made to its filesystem after it was started (like new files, installed packages, or configuration changes)—and creates a new image from it. It's essentially a "snapshot" of the container's writable layer.
-   **When to use `docker commit`**: While building images with a `Dockerfile` is the standard for production because it's reproducible, `docker commit` is incredibly useful in specific scenarios:
    1.  **Debugging:** If a container is having issues, you can use `docker exec` to get inside, install debugging tools (like `vim`, `curl`), and then `commit` that container to a new `myapp:debug` image. This image can then be shared with other developers to analyze the problem in the exact same environment.
    2.  **Saving a Manual State:** Sometimes you might configure an application inside a container through a series of manual steps. Committing the result saves that specific state as a reusable image.
-   **`Dockerfile` vs. `docker commit`**: It's important to know the difference.
    -   **`Dockerfile`** is **declarative** and **reproducible**. It's a recipe that anyone can follow to get the same result. This is the professional standard for production images.
    -   **`docker commit`** is **imperative** and creates a "black box" image. No one knows how the container got into its current state unless you document it elsewhere. It's best used for temporary, ad-hoc situations like debugging.

### Commands I Used

-   `sudo docker ps`: **P**rinter **S**tatus. Lists all *running* Docker containers, which I used to verify my source container existed.
-   `sudo docker commit ubuntu_latest news:devops`: The main command for the task. It takes a snapshot of the `ubuntu_latest` container and saves it as a new image named `news:devops`. The syntax is `docker commit <CONTAINER_NAME> <NEW_IMAGE_NAME:TAG>`.
-   `sudo docker images`: Lists all the Docker images stored on the local server. I used this to verify that my new `news:devops` image was created successfully.
  