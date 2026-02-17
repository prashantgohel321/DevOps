# DevOps Day 35: Setting Up a Docker Environment

Today's task was a foundational step for any modern DevOps workflow: preparing a server to run containerized applications. My objective was to install the Docker engine (`docker-ce`) and the Docker Compose plugin, then ensure the service was up and running.

This was a great exercise because it reinforced the correct, official method for installing Docker, which involves adding the official Docker repository to the system first. This ensures I'm getting the latest, trusted version of the software, rather than a potentially outdated one from the default system repositories.

### The Task

My objective was to prepare **App Server 2** for container deployments. The specific requirements were:
-   Install the `docker-ce` and `docker compose` packages.
-   Start the Docker service.

### My Step-by-Step Solution

The process involved preparing the system's package manager, installing the software, and then starting the service.

1.  **Connect to the Server:** I first logged into App Server 2 (`ssh steve@stapp02`).

2.  **Add the Docker Repository:** This was the crucial first step. I had to tell my server's package manager (`yum`) where to find the official Docker packages.
    ```bash
    # Install tools needed to manage yum repositories
    sudo yum install -y yum-utils

    # Add the official Docker repository
    sudo yum-config-manager --add-repo [https://download.docker.com/linux/centos/docker-ce.repo](https://download.docker.com/linux/centos/docker-ce.repo)
    ```

3.  **Install Docker and Compose:** With the repository in place, I could now install the complete suite of tools with a single command.
    ```bash
    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    ```

4.  **Start and Enable the Service:** After installation, I started the Docker daemon and enabled it to launch automatically on boot.
    ```bash
    sudo systemctl start docker
    sudo systemctl enable docker
    ```

5.  **Verification:** The final step was to confirm everything was working.
    -   I checked the service status: `sudo systemctl status docker`, which correctly showed `active (running)`.
    -   I checked the versions of both tools: `docker --version` and `docker compose version`, which both returned their version numbers, proving the installation was successful.

### Key Concepts (The "What & Why")

-   **Docker**: Docker is the platform that allows me to package applications into "containers." A container includes the application code, its runtime, and all its dependencies, ensuring it runs the same way everywhere. `docker-ce` is the Community Edition, the free and open-source version of the Docker engine.
-   **Docker Compose**: This is a tool for defining and running multi-container applications. While Docker can run a single container, most apps have multiple parts (e.g., a website and a database). Docker Compose uses a simple YAML file to manage this entire application stack with one command. The `docker-compose-plugin` provides this functionality as part of the main `docker` command.
-   **Official Repositories**: This is a key best practice. By adding the official Docker repository, I ensure that I am installing a version that is maintained and trusted by the Docker team. It also makes future updates (`yum update`) much easier and more reliable.

### Commands I Used

-   `sudo yum-config-manager --add-repo [URL]`: The command to add a new software repository to the system's package manager.
-   `sudo yum install -y [packages...]`: The standard command to install software packages. I installed the full suite: `docker-ce` (engine), `docker-ce-cli` (client), `containerd.io` (runtime), and `docker-compose-plugin`.
-   `sudo systemctl start docker`: The command to start the Docker service for the current session.
-   `sudo systemctl enable docker`: The command to configure the Docker service to start automatically every time the server boots.
-   `sudo systemctl status docker`: My verification command to check if the service was actively running.
 