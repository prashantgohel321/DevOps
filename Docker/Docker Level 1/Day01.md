# Docker Day 1: Setting Up the Docker Environment

Today I switched gears from general DevOps tasks to focus on Docker. My first task was foundational: setting up a server to be a Docker host by installing the necessary software and ensuring the service was running.

This process taught me the correct, official way to install third-party software on a Linux system, which involves adding a new software repository before the installation itself. It's a critical skill for ensuring you're getting legitimate and up-to-date packages.

## Table of Contents
- [The Task](#the-task)
- [The Final, Correct Solution](#the-final-correct-solution)
- [My Learning Journey: Why a Simple Install Fails](#my-learning-journey-why-a-simple-install-fails)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: What is a Software Repository?](#deep-dive-what-is-a-software-repository)
- [Exploring the Commands Used](#exploring-the-commands-used)

---

### The Task
<a name="the-task"></a>
On `App Server 3`, my mission was to prepare the environment for containerization. The specific requirements were:
1.  Install the `docker-ce` (Community Edition) package.
2.  Install the `docker compose` package/plugin.
3.  Start the Docker service.

---

### The Final, Correct Solution
<a name="the-final-correct-solution"></a>
The official and most reliable method to install Docker involves telling the server's package manager where to find the Docker software first. This ensures a successful installation every time.

#### 1. Set Up the Docker Repository
Before installing, I had to add Docker's official software repository to my server's list of sources.

```bash
# Install the tool needed to manage software repositories
sudo dnf -y install dnf-plugins-core

# Add the official Docker repository
sudo dnf config-manager --add-repo [https://download.docker.com/linux/centos/docker-ce.repo](https://download.docker.com/linux/centos/docker-ce.repo)
```

#### 2. Install Docker Engine and Plugins
With the repository added, I could now tell the system to install all the necessary Docker components.

```bash
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
```

#### 3. Start and Enable the Docker Service
Finally, I started the Docker service and enabled it to launch automatically on boot.

```bash
sudo systemctl enable --now docker
```
This single command handles both starting the service for the current session and ensuring it persists after a reboot.

---

### My Learning Journey: Why a Simple Install Fails
<a name="my-learning-journey-why-a-simple-install-fails"></a>
My first instinct was to try a simple command: `sudo yum install docker-ce`. On some pre-configured systems, this might work. However, in a fresh environment, this approach is unreliable and will likely fail.

**The Problem:** The server's package manager (`yum` or `dnf`) only knows how to find software in its default, pre-configured list of sources (repositories). Docker is not included in this default list. So, when you ask it to install `docker-ce`, it's like asking a librarian to find a book that isn't in their library's catalog—they'll report that it doesn't exist.

**The Lesson:** The robust, professional approach is to **never assume** a repository is already configured. By explicitly adding the Docker repository first, I guarantee that the package manager knows exactly where to look, ensuring the installation succeeds and that I get the official version of the software.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
This task is the starting point for all modern application deployment and testing.

-   **What is Docker?** Docker is a platform that lets you package an application and all its dependencies (libraries, settings, etc.) into a single, isolated unit called a **container**. This container can then run on any machine that has Docker installed, guaranteeing that the application works the same way everywhere. This solves the classic "it works on my machine" problem. `docker-ce` is the core engine that runs these containers.
-   **What is Docker Compose?** Most applications aren't just one thing; they're multiple services working together (e.g., a website, a database, a caching service). Docker Compose is a tool that uses a simple `YAML` file to define and run all these services together with a single command (`docker compose up`). It's essential for managing the complexity of real-world applications. The `docker-compose-plugin` provides this functionality.

---

### Deep Dive: What is a Software Repository?
<a name="deep-dive-what-is-a-software-repository"></a>
A software repository (or "repo") is a centralized storage location where software packages are kept. Think of it as an app store for your server.

When I run `dnf install`, the package manager connects to the list of repositories defined in `/etc/yum.repos.d/`. It downloads a list of available software from each one and searches for the package I requested.

The command `sudo dnf config-manager --add-repo <URL>` creates a new `.repo` file in that directory. This file contains the URL and other information that tells `dnf` about this new, trusted source for software. By doing this, I essentially added the official "Docker App Store" to my server's list of trusted stores.

---

### Exploring the Commands Used
<a name="exploring-the-commands-used"></a>
-   `dnf config-manager`: This is a powerful utility for managing the list of software sources. I used it to `--add-repo`, but it can also be used to disable or remove repositories. It's a key tool for controlling what software can be installed on a system.
-   `systemctl enable --now`: This is a fantastic time-saving command. It combines two separate actions:
    -   `systemctl start docker`: Starts the service in the current session.
    -   `systemctl enable docker`: Configures the service to start automatically on the next boot.
    Using `enable --now` is efficient and ensures the service is both running and persistent.
