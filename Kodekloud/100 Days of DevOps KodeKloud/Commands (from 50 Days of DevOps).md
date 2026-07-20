# The Ultimate DevOps Command Reference (from 50 Days of DevOps)

This document is a comprehensive reference guide to every command used in the "50 Days of DevOps" document. The commands are organized by category and progress from basic to more advanced concepts, reflecting the structure of the learning journey. Each command includes an explanation of its purpose, a breakdown of the specific flags used, and the real-world example from the document.

---

### Table of Contents
1.  [**Linux Fundamentals & User Management**](#part-1-linux-fundamentals--user-management)
2.  [**File System & Permissions**](#part-2-file-system--permissions)
3.  [**System & Service Management**](#part-3-system--service-management)
4.  [**Networking & Troubleshooting**](#part-4-networking--troubleshooting)
5.  [**Scripting & Automation**](#part-5-scripting--automation)
6.  [**Version Control with Git**](#part-6-version-control-with-git)
7.  [**Containerization with Docker**](#part-7-containerization-with-docker)
8.  [**Orchestration with Kubernetes (kubectl)**](#part-8-orchestration-with-kubernetes-kubectl)
9.  [**Configuration Management with Ansible**](#part-9-configuration-management-with-ansible)

---

## Part 1: Linux Fundamentals & User Management
<a name="part-1-linux-fundamentals--user-management"></a>

### `sudo`
* **Meaning:** (Super User Do) Executes a command with elevated (root/administrator) privileges. It is prepended to almost any command that modifies system-level configurations or resources.
* **Example:** `sudo useradd james ...`

### `useradd`
* **Meaning:** The primary command for adding a new user account to a Linux system.
* **Flags Used:**
    * `-s /sbin/nologin`: Sets the user's login shell to `/sbin/nologin`, which prevents interactive logins.
    * `--expiredate YYYY-MM-DD`: Sets a specific date on which the user account will be automatically disabled.
* **Examples:**
    * `sudo useradd james -s /sbin/nologin`
    * `sudo useradd anita --expiredate 2024-01-28`

### `chage`
* **Meaning:** (Change Age) A utility for viewing and modifying user account and password aging information.
* **Flags Used:**
    * `-l <username>`: Lists the current account aging information for the specified user.
* **Example:** `sudo chage -l anita`

### `grep`
* **Meaning:** A powerful command-line tool for searching plain-text data for lines that match a regular expression or a simple string.
* **Examples:**
    * `grep 'james' /etc/passwd` (Searches the user database file for any line containing "james").
    * `grep Listen /etc/httpd/conf/httpd.conf` (Finds the line containing the "Listen" directive in the Apache config).

---

## Part 2: File System & Permissions
<a name="part-2-file-system--permissions"></a>

### `ls`
* **Meaning:** (List) Lists files and directories.
* **Flags Used:**
    * `-l`: Long format, showing detailed information like permissions, owner, size, and modification date.
    * `-a`: All files, including hidden dotfiles (e.g., `.git`).
    * `-d`: Directory, lists the directory itself, not its contents.
    * `-R`: Recursive, lists the contents of all subdirectories.
* **Examples:**
    * `ls -l /tmp/xfusioncorp.sh`
    * `ls -ld /var/lib/mysql`
    * `ls -la`
    * `ls -R`

### `chmod`
* **Meaning:** (Change Mode) The primary command for changing the access permissions of a file or directory.
* **Arguments Used:**
    * `a+x`: Adds (`+`) execute (`x`) permission for all (`a`) users.
    * `+x`: A shorthand to add execute permission for the owner, group, and others if they have read permission.
    * `600`: Numeric (octal) notation to set read/write for the owner and no permissions for anyone else.
* **Examples:**
    * `sudo chmod a+x /tmp/xfusioncorp.sh`
    * `chmod +x /scripts/news_backup.sh`
    * `sudo chmod 600 /etc/nginx/ssl/nautilus.key`

### `vi`
* **Meaning:** A powerful, ubiquitous command-line text editor. Used to edit configuration files, scripts, and other text files.
* **Example:** `sudo vi /etc/ssh/sshd_config`

### `cat`
* **Meaning:** (Concatenate) Primarily used to display the content of a file to the standard output.
* **Example:** `cat /tmp/cron_text`

### `touch`
* **Meaning:** Creates an empty file if it doesn't exist, or updates the modification timestamp of an existing file.
* **Example:** `touch /scripts/news_backup.sh`

### `mkdir`
* **Meaning:** (Make Directory) Creates a new directory.
* **Flags Used:**
    * `-p`: Parent, creates parent directories as needed.
* **Examples:**
    * `sudo mkdir /var/lib/mysql`
    * `sudo mkdir -p /scripts /backup`

### `chown`
* **Meaning:** (Change Owner) Changes the user and/or group ownership of a file or directory.
* **Examples:**
    * `sudo chown mysql:mysql /var/lib/mysql`
    * `sudo chown steve:steve /scripts /backup`

### `mv`
* **Meaning:** (Move) Moves or renames files and directories.
* **Example:** `sudo mv /tmp/nautilus.crt /etc/nginx/ssl/`

### `cp`
* **Meaning:** (Copy) Copies files or directories.
* **Example:** `sudo cp /tmp/index.html .`

### `cd`
* **Meaning:** (Change Directory) Navigates to a different directory in the file system.
* **Example:** `cd /usr/src/kodekloudrepos/`

---

## Part 3: System & Service Management
<a name="part-3-system--service-management"></a>

### `systemctl`
* **Meaning:** The central management tool for the `systemd` init system, used to control services (daemons).
* **Actions Used:**
    * `status <service>`: Checks the current running status of a service.
    * `start <service>`: Starts a service for the current session.
    * `stop <service>`: Stops a running service.
    * `restart <service>`: Stops and then starts a service.
    * `reload <service>`: Reloads a service's configuration without a full restart.
    * `enable <service>`: Configures a service to start automatically on boot.
    * `disable <service>`: Prevents a service from starting on boot.
* **Examples:**
    * `sudo systemctl restart sshd`
    * `sudo systemctl status mariadb`
    * `sudo systemctl start crond`
    * `sudo systemctl enable crond`

### `journalctl`
* **Meaning:** A command to query and display the logs from the `systemd` journal. It's the primary tool for in-depth service troubleshooting.
* **Flags Used:**
    * `-xeu <service>`: Shows detailed log entries (`-e`), provides explanations (`-x`), specifically for the given unit (`-u`).
* **Example:** `journalctl -xeu mariadb.service`

### `service`
* **Meaning:** An older command for managing system services. On modern systems, it often acts as a wrapper for `systemctl`. It is still commonly used for interacting with `iptables`.
* **Example:** `sudo service iptables save`

---

## Part 4: Networking & Troubleshooting
<a name="part-4-networking--troubleshooting"></a>

### `ssh`
* **Meaning:** (Secure Shell) The standard command for securely connecting to a remote Linux server.
* **Example:** `ssh tony@stapp01`

### `ssh-keygen`
* **Meaning:** Generates a new SSH authentication key pair (a public key and a private key).
* **Flags Used:**
    * `-t rsa`: Specifies the type (`-t`) of key to create, in this case, the `RSA` algorithm.
* **Example:** `ssh-keygen -t rsa`

### `ssh-copy-id`
* **Meaning:** A utility to securely copy a public SSH key to a remote server, correctly setting it up in the `authorized_keys` file for password-less login.
* **Example:** `ssh-copy-id clint@stbkp01`

### `scp`
* **Meaning:** (Secure Copy) Copies files between hosts on a network using the SSH protocol.
* **Flags Used:**
    * `-r`: Recursive, used to copy entire directories and their contents.
* **Example:** `scp -r /home/thor/ecommerce tony@stapp01:/home/tony`

### `curl`
* **Meaning:** A command-line tool for transferring data with URLs. It's essential for testing web servers and APIs.
* **Flags Used:**
    * `-Ik`: Shows the headers (`-I`) and allows insecure (`-k`) connections (for self-signed SSL certificates).
* **Example:** `curl http://stapp01:6400`

### `df`
* **Meaning:** (Disk Free) Reports file system disk space usage.
* **Flags Used:**
    * `-h`: Human-readable format (e.g., MB, GB).
* **Example:** `df -h`

### `netstat`
* **Meaning:** A networking tool that displays network connections, routing tables, and interface statistics.
* **Flags Used:**
    * `-tulpn`: Shows TCP (`t`), UDP (`u`), listening (`l`) ports, the program (`p`) using them, and uses numeric (`n`) addresses.
* **Example:** `sudo netstat -tulpn | grep 6400`

### `firewall-cmd`
* **Meaning:** The command-line interface for `firewalld`, the modern default firewall on many Linux distributions.
* **Flags Used:**
    * `--permanent`: Makes a rule persistent across reboots.
    * `--add-service=https`: Allows traffic for a predefined service (https is TCP port 443).
    * `--reload`: Applies permanent rules to the live firewall.
* **Example:** `sudo firewall-cmd --permanent --add-service=https`

### `iptables`
* **Meaning:** A user-space utility for configuring the Linux kernel firewall. The classic, powerful firewall tool.
* **Flags Used:**
    * `-I INPUT 1`: Inserts a rule into the `INPUT` chain at position 1.
    * `-A INPUT`: Appends a rule to the end of the `INPUT` chain.
    * `-p tcp`: Specifies the protocol (TCP).
    * `--dport <port>`: Specifies the destination port.
    * `-j ACCEPT`: The "jump" target, telling the firewall to accept the packet.
    * `-j REJECT`: The target to reject the packet.
    * `-L`: Lists the rules.
    * `-n`: Numeric output.
    * `--line-numbers`: Shows the rule numbers in the chain.
* **Examples:**
    * `sudo iptables -I INPUT 1 -p tcp --dport 3002 -j ACCEPT`
    * `sudo iptables -L INPUT -n --line-numbers`

---

## Part 5: Scripting & Automation
<a name="part-5-scripting--automation"></a>

### `crontab`
* **Meaning:** (Cron Table) The command to manage the `cron` jobs for a user.
* **Flags Used:**
    * `-e`: Edits the user's crontab file.
    * `-l`: Lists the current cron jobs.
* **Example:** `sudo crontab -e`

### `echo`
* **Meaning:** A shell builtin that displays a line of text.
* **Example:** `echo "Welcome!" | sudo tee /usr/share/nginx/html/index.html`

### `zip`
* **Meaning:** A utility to create `.zip` archive files.
* **Flags Used:**
    * `-r`: Recursive, to include all files and subdirectories.
* **Example:** `zip -r /backup/xfusioncorp_news.zip /var/www/html/news`

### `sed`
* **Meaning:** (Stream Editor) A powerful utility for parsing and transforming text.
* **Example:** `sudo sed -i 's/^Listen .*/Listen 3002/' /etc/httpd/conf/httpd.conf` (Finds the line starting with "Listen" and replaces the entire line with "Listen 3002").

---

## Part 6: Version Control with Git
<a name="part-6-version-control-with-git"></a>

### `git init`
* **Meaning:** Initializes a new Git repository.
* **Flags Used:**
    * `--bare`: Creates a "bare" repository, which is a central repository for sharing that has no working files.
* **Example:** `sudo git init --bare /opt/official.git`

### `git clone`
* **Meaning:** Creates a local copy (a "clone") of a remote repository.
* **Example:** `git clone /opt/media.git`

### `git branch`
* **Meaning:** Manages branches. When run without arguments, it lists local branches.
* **Example:** `sudo git branch xfusioncorp_games`

### `git checkout`
* **Meaning:** Switches between branches or restores working tree files.
* **Flags Used:**
    * `-b <branch-name>`: Creates a new branch and immediately switches to it.
* **Example:** `sudo git checkout -b datacenter`

### `git add`
* **Meaning:** Adds file contents to the staging area, marking them to be included in the next commit.
* **Example:** `sudo git add index.html`

### `git commit`
* **Meaning:** Records changes to the repository by creating a new commit.
* **Flags Used:**
    * `-m "message"`: Sets the commit message directly from the command line.
* **Example:** `sudo git commit -m "Add new index file"`

### `git merge`
* **Meaning:** Joins two or more development histories (branches) together.
* **Example:** `sudo git merge datacenter`

### `git push`
* **Meaning:** Updates remote refs along with associated objects. It's how you send your local commits to a remote server like GitHub.
* **Flags Used:**
    * `--force`: Forcefully overwrites the remote branch. **Use with extreme caution.**
* **Example:** `sudo git push origin master datacenter`

### `git pull`
* **Meaning:** Fetches from and integrates with another repository or a local branch. It's how you get updates from others.
* **Example:** `git pull origin master`

### `git log`
* **Meaning:** Shows the commit logs.
* **Flags Used:**
    * `--oneline`: Shows each commit on a single, condensed line.
    * `--graph`: Draws a text-based graph of the commit history.
    * `--all`: Shows all branches.
* **Example:** `sudo git log --oneline --graph --all`

### `git remote`
* **Meaning:** Manages the set of tracked remote repositories.
* **Subcommands:**
    * `add <name> <url>`: Adds a new remote.
    * `rename <old> <new>`: Renames a remote.
    * `-v`: Verbose, shows the URLs of the remotes.
* **Example:** `sudo git remote add dev_official /opt/xfusioncorp_official.git`

### `git revert`
* **Meaning:** Creates a new commit that is the inverse of a previous commit, safely undoing changes on a shared branch.
* **Flags Used:**
    * `--no-commit`: Performs the revert in the working directory but does not automatically create a new commit.
* **Example:** `sudo git revert --no-commit HEAD`

### `git reset`
* **Meaning:** Resets the current `HEAD` to a specified state, rewriting history. **Dangerous on shared branches.**
* **Flags Used:**
    * `--hard`: Resets the branch pointer, staging area, and working directory, discarding all changes.
* **Example:** `sudo git reset --hard a1b2c3d`

### `git cherry-pick`
* **Meaning:** Applies the changes introduced by an existing commit as a new commit on the current branch.
* **Example:** `sudo git cherry-pick a1b2c3d`

### `git stash`
* **Meaning:** Temporarily shelves (or stashes) uncommitted changes in your working directory.
* **Subcommands:**
    * `list`: Lists all stashed changes.
    * `apply <stash_id>`: Re-applies the stashed changes without removing them from the stash list.
* **Example:** `sudo git stash apply stash@{1}`

### `git rebase`
* **Meaning:** Re-applies commits on top of another base tip, creating a linear history.
* **Example:** `sudo git rebase master`

### `git fetch`
* **Meaning:** Downloads objects and refs from another repository.
* **Flags Used:**
    * `--tags`: Fetches all tags from the remote.
* **Example:** `sudo git fetch origin --tags`

### `git tag`
* **Meaning:** Creates, lists, deletes, or verifies a tag object signed with GPG.
* **Example:** `sudo git tag`

---

## Part 7: Containerization with Docker
<a name="part-7-containerization-with-docker"></a>

### `docker run`
* **Meaning:** Runs a command in a new container.
* **Flags Used:**
    * `-d`: Detached mode, runs the container in the background.
    * `--name <name>`: Assigns a name to the container.
    * `-p <host_port>:<container_port>`: Publishes a container's port to the host.
* **Example:** `sudo docker run -d --name news -p 8088:80 nginx:stable`

### `docker ps`
* **Meaning:** Lists running containers.
* **Example:** `sudo docker ps`

### `docker cp`
* **Meaning:** Copies files/folders between a container and the local filesystem.
* **Example:** `sudo docker cp /tmp/nautilus.txt.gpg ubuntu_latest:/home/`

### `docker exec`
* **Meaning:** Executes a command in a running container.
* **Flags Used:**
    * `-it`: Interactive terminal, allowing you to get a shell inside the container.
* **Example:** `sudo docker exec -it kkloud bash`

### `docker pull`
* **Meaning:** Pulls an image or a repository from a registry.
* **Example:** `sudo docker pull busybox:musl`

### `docker tag`
* **Meaning:** Creates a tag (an alias) that refers to a source image.
* **Example:** `sudo docker tag busybox:musl busybox:local`

### `docker images`
* **Meaning:** Lists all images on the local system.
* **Example:** `sudo docker images`

### `docker commit`
* **Meaning:** Creates a new image from a container's changes.
* **Example:** `sudo docker commit ubuntu_latest news:devops`

### `docker build`
* **Meaning:** Builds an image from a Dockerfile.
* **Flags Used:**
    * `-t <name:tag>`: Tags the resulting image.
* **Example:** `sudo docker build -t my-apache:test .`

### `docker network`
* **Meaning:** Manages Docker networks.
* **Subcommands:**
    * `create`: Creates a new network.
    * `inspect`: Displays detailed information on a network.
* **Example:** `sudo docker network create --driver bridge --subnet=192.168.0.0/24 ecommerce`

### `docker compose`
* **Meaning:** The command for defining and running multi-container Docker applications using a `docker-compose.yml` file.
* **Subcommands:**
    * `up -d`: Creates and starts containers in detached mode.
* **Example:** `sudo docker compose up -d`

---

## Part 8: Orchestration with Kubernetes (kubectl)
<a name="part-8-orchestration-with-kubernetes-kubectl"></a>

### `kubectl apply`
* **Meaning:** Applies a configuration to a resource by filename. It's the standard way to create or update Kubernetes objects.
* **Flags Used:**
    * `-f <filename>`: Specifies the filename of the manifest.
* **Example:** `kubectl apply -f pod-httpd.yaml`

### `kubectl get`
* **Meaning:** Displays one or many resources.
* **Resources:** `pods`, `deployments`, `all`.
* **Example:** `kubectl get pods`

### `kubectl describe`
* **Meaning:** Shows a detailed description of a resource. This is the primary tool for troubleshooting.
* **Resources:** `pod <pod-name>`, `deployment <deployment-name>`.
* **Example:** `kubectl describe pod httpd-pod`

### `kubectl logs`
* **Meaning:** Prints the logs for a container in a pod.
* **Example:** `kubectl logs pod-httpd`

### `kubectl exec`
* **Meaning:** Executes a command in a container.
* **Flags Used:**
    * `-it`: Interactive terminal.
* **Example:** `kubectl exec -it pod-httpd -- /bin/bash`

### `kubectl delete`
* **Meaning:** Deletes resources by filename or name.
* **Example:** `kubectl delete deployment httpd`

### `kubectl scale`
* **Meaning:** Sets a new size for a Deployment, ReplicaSet, or Replication Controller.
* **Example:** `kubectl scale deployment httpd --replicas=3`

### `kubectl top`
* **Meaning:** Displays resource (CPU/Memory) usage.
* **Example:** `kubectl top pod httpd-pod`

---

## Part 9: Configuration Management with Ansible
<a name="part-9-configuration-management-with-ansible"></a>

### `pip3`
* **Meaning:** The package installer for Python 3.
* **Example:** `sudo pip3 install ansible==4.7.0`

### `ansible`
* **Meaning:** The main Ansible command-line tool.
* **Flags Used:**
    * `--version`: Displays the version of Ansible (specifically, `ansible-core`).
* **Example:** `ansible --version`

### `ansible-playbook`
* **Meaning:** The command to run an Ansible playbook.
* **Flags Used:**
    * `-i <inventory_file>`: Specifies the inventory file to use.
* **Example:** `ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.ini playbook.yaml`
