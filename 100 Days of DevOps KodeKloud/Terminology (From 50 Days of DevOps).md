# The Ultimate DevOps Terminology Guide (from 50 Days of DevOps)

This document is a comprehensive glossary of all the key terminologies and concepts encountered throughout the "50 Days of DevOps" document. The terms are organized by category and progress from foundational concepts to more advanced topics, providing clear definitions and real-world context based on the tasks you completed.

---

### Table of Contents
1.  [**General DevOps & IT Concepts**](#part-1-general-devops--it-concepts)
2.  [**Linux & System Administration**](#part-2-linux--system-administration)
3.  [**Networking & Security**](#part-3-networking--security)
4.  [**Version Control (Git & GitHub)**](#part-4-version-control-git--github)
5.  [**Containerization (Docker)**](#part-5-containerization-docker)
6.  [**Container Orchestration (Kubernetes)**](#part-6-container-orchestration-kubernetes)
7.  [**Configuration Management & Automation (Ansible)**](#part-7-configuration-management--automation-ansible)

---

## Part 1: General DevOps & IT Concepts
<a name="part-1-general-devops--it-concepts"></a>

* **DevOps:** A culture and set of practices that combines software development (Dev) and IT operations (Ops). The goal is to shorten the development lifecycle and provide continuous delivery with high software quality. Your 50-day journey is a practical application of DevOps principles, automating tasks from user creation to application deployment.
* **Automation:** The use of technology to perform tasks with minimal human intervention. This is the central theme of your journey, seen in your cron jobs, backup scripts, Ansible playbooks, and Git hooks.
* **Troubleshooting:** The systematic process of identifying, diagnosing, and resolving a problem. Your experience fixing the MariaDB and Apache services (Days 9, 12, 14) are classic examples of real-world troubleshooting.
* **Root Cause Analysis:** The process of digging deeper than the initial symptom of a problem to find the fundamental, underlying cause. You did this on Day 9 when you found the MariaDB service was down not because it crashed, but because its entire data directory was missing.
* **High Availability:** Designing a system to remain operational for a long time, often by eliminating single points of failure. Setting up an Nginx load balancer (Day 16) is a primary technique for achieving high availability.
* **Scalability:** The ability of a system to handle a growing amount of work. The load balancer you configured also provides scalability, as you can easily add more app servers to handle more traffic.
* **Two-Tier Architecture:** A common application architecture that separates the Presentation Tier (the web server, e.g., Apache/PHP) from the Data Tier (the database, e.g., MariaDB). You deployed this on Day 46 with Docker Compose.

---

## Part 2: Linux & System Administration
<a name="part-2-linux--system-administration"></a>

* **Shell:** A command-line interface that allows you to interact with the operating system.
    * **Interactive Shell:** A shell that provides a command prompt and waits for human input (e.g., `/bin/bash`). This is what you use when you `ssh` into a server.
    * **Non-Interactive Shell:** A shell that does not provide a command prompt and is used for service accounts that should not be logged into by humans (e.g., `/sbin/nologin`). You used this on Day 1.
* **Root User:** The superuser account in Linux with unlimited privileges to perform any action on the system.
* **Service Account:** A user account created for a specific application or automated process (like a backup agent) rather than a person. These are often given non-interactive shells for security.
* **Home Directory:** A dedicated directory for a user to store their files (e.g., `/home/james`).
* **Daemon:** A background process that runs without direct user interaction to handle system tasks (e.g., `sshd`, `crond`, `httpd`).
* **Package Manager (yum/dnf):** A tool that automates the process of installing, updating, and removing software packages (e.g., `yum install nginx`).
* **Software Repository:** A central storage location from which a package manager retrieves and installs software. You added the official Docker and Remi repositories to your system.
* **Cron Job:** A scheduled task that runs automatically at a specified time or interval, managed by the `cron` daemon. You used this on Day 6 to automate a simple script.
* **Permissions (rwx):** The rules that control access to files and directories.
    * **Read (r):** Permission to view the contents of a file or list the contents of a directory.
    * **Write (w):** Permission to modify a file or create/delete files within a directory.
    * **Execute (x):** Permission to run a file as a program or enter a directory. You set this on Day 4.
* **File Ownership:** Every file and directory is owned by a specific user and a specific group.
* **Symbolic & Octal Notation:** Two ways to represent file permissions. `a+x` is symbolic, while `755` is octal.

---

## Part 3: Networking & Security
<a name="part-3-networking--security"></a>

* **SSH (Secure Shell):** A cryptographic network protocol for operating network services securely over an unsecured network. It's how you remotely connect to and manage your servers.
* **Public Key Authentication:** A secure method for SSH login that uses a pair of cryptographic keys (a private key and a public key) instead of a password. This is essential for automation, as you learned on Day 7.
* **Server Hardening:** The process of securing a server by reducing its surface of vulnerability. Disabling direct root SSH login (Day 3) is a fundamental server hardening practice.
* **Port:** A communication endpoint in a computer's operating system. Services "listen" on specific ports for incoming connections (e.g., Apache on port 80).
* **Port Conflict:** An error that occurs when two applications try to listen on the same port at the same time. You diagnosed this on Day 12 with `netstat`.
* **Firewall (iptables/firewalld):** A network security system that monitors and controls incoming and outgoing network traffic based on predetermined security rules. You configured `iptables` on Day 13.
* **SSL/TLS (HTTPS):** (Secure Sockets Layer/Transport Layer Security) Cryptographic protocols that provide secure, encrypted communication over a computer network. You configured Nginx with SSL on Day 15 to enable HTTPS.
* **Load Balancer:** A device or server that acts as a reverse proxy and distributes network or application traffic across a number of servers to improve capacity and reliability. You configured Nginx as a load balancer on Day 16.
* **Upstream:** In Nginx, a named group of backend servers that a load balancer can distribute traffic to.
* **Proxy Pass:** The Nginx directive that forwards a request to a proxied server or an upstream group.

---

## Part 4: Version Control (Git & GitHub)
<a name="part-4-version-control-git--github"></a>

* **Version Control System (VCS):** A system that records changes to a file or set of files over time so that you can recall specific versions later. Git is the most popular VCS.
* **Repository (Repo):** The database containing the entire history of your project.
    * **Bare Repository:** A central repository used for sharing, with no working files (e.g., `project.git`). You created one on Day 21.
    * **Working Repository:** A local copy of a project with all the files visible and editable, created with `git clone`.
* **Commit:** A snapshot of your project's files at a specific point in time.
* **Branch:** An independent line of development. The main branch is often called `master` or `main`.
* **Merge:** The process of integrating changes from one branch into another.
* **Remote (`origin`):** A version of your repository hosted on another server (like GitHub or Gitea). `origin` is the default name for the remote you cloned from.
* **Push / Pull:** The actions of sending your local commits to a remote (`push`) or fetching changes from a remote (`pull`).
* **Fork:** A new copy of a repository that is created on the server, belonging to you. This is the first step in the "Fork and Pull Request" workflow for contributing to projects you don't have write access to.
* **Pull Request (PR):** A formal proposal to merge your changes from your branch (or fork) into the main project. It's the central place for code review and discussion.
* **HEAD:** A special pointer in Git that points to the most recent commit of your currently checked-out branch.
* **`git revert`:** The **safe** way to undo a commit on a shared branch. It creates a *new* commit that is the inverse of the commit you are reverting.
* **`git reset --hard`:** The **dangerous** way to undo commits. It rewrites history by deleting commits from a branch. It should only be used on private, local branches.
* **Force Push (`--force`):** A push command that overwrites the history of the remote branch with your local history. It is required after a `reset` or `rebase`.
* **`git cherry-pick`:** A surgical command that allows you to select a single commit from one branch and apply it as a new commit on another branch.
* **`git stash`:** A command to temporarily save your uncommitted work so you can switch branches to work on something else.
* **`git rebase`:** A command to rewrite history by re-applying your commits on top of another branch, resulting in a clean, linear history.
* **Git Hooks:** Custom scripts that Git automatically executes at specific points in its workflow (e.g., `post-update`). You used this on Day 34 to automate release tagging.

---

## Part 5: Containerization (Docker)
<a name="part-5-containerization-docker"></a>

* **Container:** A standard, isolated package that contains an application and all its dependencies, ensuring it runs the same way everywhere.
* **Image:** A read-only template with instructions for creating a Docker container.
* **Dockerfile:** A text file that contains a script of instructions for building a custom Docker image.
* **Docker Compose:** A tool for defining and running multi-container Docker applications using a simple YAML file (`docker-compose.yml`).
* **Tag:** A label or pointer to a specific version of an image (e.g., `nginx:alpine`).
* **Layer:** Each instruction in a Dockerfile creates a read-only layer in the image. This is key for Docker's build cache.
* **Build Context:** The set of files at a specified location (usually `.`) that is sent to the Docker daemon when building an image.
* **Volume (Bind Mount):** A mechanism for persisting data by mapping a directory from the host machine into a container.
* **Docker Network (Bridge):** An isolated, software-based network that allows containers to communicate with each other.

---

## Part 6: Container Orchestration (Kubernetes)
<a name="part-6-container-orchestration-kubernetes"></a>

* **Kubernetes (K8s):** A container orchestration platform that automates the deployment, scaling, and management of containerized applications.
* **Cluster:** A set of worker machines, called nodes, that run containerized applications.
* **Node:** A worker machine in a Kubernetes cluster, either a VM or a physical machine.
* **Pod:** The smallest and simplest unit in the Kubernetes object model. It's a wrapper for one or more containers that share storage and network resources.
* **Deployment:** A higher-level Kubernetes object that manages a set of replica Pods. Its key feature is **self-healing**—if a Pod dies, the Deployment will automatically create a new one.
* **ReplicaSet:** An object managed by a Deployment whose job is to ensure that a specified number of replica Pods are always running.
* **Manifest (YAML):** A declarative configuration file, usually written in YAML, that describes the desired state of a Kubernetes resource (like a Pod or a Deployment).
* **`kubectl`:** The command-line tool for interacting with a Kubernetes cluster.
* **Declarative vs. Imperative:** The core concept of Kubernetes. You write a manifest declaring the *what* (the desired end state), and `kubectl apply` tells the cluster to figure out the *how*.
* **Resource Management (Requests/Limits):**
    * **Requests:** The guaranteed amount of CPU/Memory a container will get. Used for scheduling.
    * **Limits:** The maximum amount of CPU/Memory a container is allowed to use. Used for enforcement.

---

## Part 7: Configuration Management & Automation (Ansible)
<a name="part-7-configuration-management--automation-ansible"></a>

* **Ansible:** A powerful, agentless configuration management tool that automates software provisioning, configuration management, and application deployment.
* **Configuration Management:** The process of maintaining computer systems and software in a desired, consistent state.
* **Infrastructure as Code (IaC):** Managing and provisioning infrastructure through machine-readable definition files (like an Ansible Playbook), rather than manual configuration.
* **Controller Node:** The central machine where Ansible is installed and from which all automation is run.
* **Playbook:** A YAML file that contains a list of "plays" or tasks to be executed by Ansible. This is your automation "recipe."
* **Inventory:** A file that defines the list of servers (hosts) that Ansible will manage.
* **Task:** A single action that Ansible performs (e.g., "install nginx").
* **Module:** A reusable, standalone script that Ansible uses to perform tasks (e.g., the `yum` module, the `service` module).
* **Idempotence:** A core principle of Ansible. It means that running the same playbook multiple times will result in the same system state, and changes are only made if necessary.
* **Agentless:** A key feature of Ansible. It does not require any special software (agents) to be installed on the managed nodes; it communicates over standard SSH.
