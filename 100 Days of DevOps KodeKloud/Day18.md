# DevOps Day 18: My Epic Battle with the LAMP Stack

Today's task was the most complex and, ultimately, the most challenging I've faced. The goal was to deploy a high-availability WordPress site, a classic LAMP (Linux, Apache, MariaDB, PHP) stack problem. I attempted this task four times, and each time I peeled back another layer of a deeply complex and intertwined set of issues.

This document is a detailed post-mortem of my journey. While I was **still unable to solve the task**, the process was an incredible, real-world lesson in multi-server troubleshooting. I'm documenting every failure, every command I tried, and every theory I had, because sometimes you learn more from failure than from success.

## Table of Contents
- [The Task](#the-task)
- [Final Status: Unsolved](#final-status-unsolved)
- [My Troubleshooting Journey: A Chronology of Failures](#my-troubleshooting-journey-a-chronology-of-failures)
- [Why Did I Do This? (The "What & Why" of the LAMP Stack)](#why-did-i-do-this-the-what--why-of-the-lamp-stack)
- [Deep Dive: The Anatomy of a Multi-Layered Failure](#deep-dive-the-anatomy-of-a-multi-layered-failure)
- [Common Pitfalls (And I Hit Them All)](#common-pitfalls-and-i-hit-them-all)
- [The Full Arsenal: Every Command I Used](#the-full-arsenal-every-command-i-used)

---

### The Task
<a name="the-task"></a>
My objective was to deploy a WordPress website across a multi-server environment. The requirements were:
1.  **DB Server:** Install MariaDB, create a specific database and user, and grant permissions.
2.  **App Servers (x3):** Install Apache, PHP, and its dependencies. Configure Apache to run on a custom port (e.g., 8084).
3.  The app servers used a shared directory at `/var/www/html`.
4.  The final site needed to be accessible via a Load Balancer link.

---

### Final Status: Unsolved
<a name="final-status-unsolved"></a>
Despite four attempts and what I believe was a comprehensive troubleshooting process that touched every layer of the architecture, I was unable to get the final application to load. My first attempt resulted in a WordPress installation screen (which was a partial success), but my subsequent attempts ended in an `ERR_EMPTY_RESPONSE` error, indicating a deep-seated issue was preventing the backend from responding.

---

### My Troubleshooting Journey: A Chronology of Failures
<a name="my-troubleshooting-journey-a-chronology-of-failures"></a>
My approach evolved with each attempt as I discovered new problems.

#### Attempt 1 & 2: The "Full Deployment" Approach
My initial thinking was to treat this like a real-world WordPress deployment. This involved:
1.  **Database Setup:** This part was always successful. I installed MariaDB, created the user/database, and granted privileges.
2.  **App Server Setup:** I installed `httpd` and `php`, changed the port in `httpd.conf`, and started the service.
3.  **WordPress Installation:** I downloaded WordPress to `/var/www/html`, created the `wp-config.php`, and set the file permissions.
4.  **Load Balancer Setup:** I configured Nginx on the LBR server with an `upstream` block pointing to the app servers on the correct port.
5.  **The First Success and First Failure:** On my very first attempt, this worked! I saw the WordPress installation screen. However, the task still failed. This taught me that the validation script required the on-screen installation to be completed. On the second attempt, this same process led to the `ERR_EMPTY_RESPONSE` error.

#### Attempt 3 & 4: The Deep Dive into the `ERR_EMPTY_RESPONSE`
This error means the connection is being made, but the backend is crashing before it can send any data. I started digging deeper.

* **Failure 1: The LBR Port Conflict**
    -   **Symptom:** Nginx on the LBR server failed to start with an `Address already in use` error on port 80.
    -   **Diagnosis:** I used `sudo netstat -tulpn | grep :80` and discovered `haproxy` was using the port.
    -   **Solution:** I stopped and disabled the conflicting service: `sudo systemctl stop haproxy` and `sudo systemctl disable haproxy`.

* **Failure 2: The DB Server Firewall**
    -   **Theory:** Maybe the app servers couldn't reach the database.
    -   **Diagnosis:** I realized I never opened the firewall on the DB server.
    -   **Solution:** I logged into `stdb01` and added a rule for the MariaDB port.
        ```bash
        # I tried firewalld first, but it wasn't installed, so I installed it.
        sudo yum install firewalld -y
        sudo systemctl start firewalld
        sudo firewall-cmd --permanent --add-port=3306/tcp
        sudo firewall-cmd --reload
        ```
        *(Note: In other labs, I learned I should have used `iptables` if `firewalld` wasn't present).*

* **Failure 3: The SELinux Rabbit Hole**
    -   **Theory:** SELinux is a common cause for `ERR_EMPTY_RESPONSE` because it can block Apache from making network connections.
    -   **Diagnosis:** I tried to check the SELinux boolean: `sudo getsebool -a | grep httpd_can_network_connect`. This failed with `getsebool: command not found`.
    -   **Solution Attempt 1:** I installed the tools needed for `getsebool`/`setsebool`.
        ```bash
        sudo yum install -y policycoreutils-python-utils
        ```
        After installation, `sudo setsebool -P httpd_can_network_connect 1` failed with a "managed policy" error, indicating a non-standard SELinux setup.
    -   **Solution Attempt 2:** I decided to switch SELinux to permissive mode on all three app servers.
        ```bash
        sudo setenforce 0
        ```

To my surprise, `sudo getenforce` returned `Disabled` on some attempts, proving SELinux was not the issue after all.

Even after addressing all these potential issues, the final error remained.

---

### Why Did I Do This? (The "What & Why" of the LAMP Stack)
<a name="why-did-i-do-this-the-what--why-of-the-lamp-stack"></a>

- **LAMP Stack**: This is an acronym for a classic web service stack: Linux (the OS), Apache (the web server), MySQL/MariaDB (the database), and PHP (the programming language). My task was to build this entire stack from scratch across multiple servers.

- **Three-Tier Architecture**: This project used a professional 3-tier design.

    1. **Web Tier (LBR Server)**: The public-facing entry point.

    2. **Application Tier (App Servers)**: These servers run the application logic (PHP) and the web server (Apache). They are "stateless" because the code is on shared storage.

    3. **Database Tier (DB Server)**: This server stores the "state" or persistent data of the application.

- **Shared Storage**: The prompt mentioned `/var/www/html` was a shared directory mounted on all app servers. This is critical for high availability. It ensures that no matter which app server a user's request is sent to, they always see the same website files.

---

### Deep Dive: The Anatomy of a Multi-Layered Failure
<a name="deep-dive-the-anatomy-of-a-multi-layered-failure"></a>
This task was a masterclass in how a system can fail at multiple, independent layers. My troubleshooting journey showed that a single error message can have many potential root causes.

- **Initial Failure (LBR)**: A port conflict on the load balancer prevented any traffic from even entering the system.

- **Potential Failure (Network)**: I theorized that the DB server's firewall could be blocking the connection from the app servers.

- **Potential Failure (OS Security)**: I theorized that SELinux could be blocking the Apache process from making network calls.

- **The Unfound Failure**: Even after solving all of the above, something was still wrong. This could be a subtle misconfiguration in PHP, a problem with the shared storage, or an issue with the lab's pre-built test application itself. The `ERR_EMPTY_RESPONSE` simply means the PHP process is crashing, and the root cause remains elusive.

---

### Common Pitfalls (And I Hit Them All)
<a name="common-pitfalls-and-i-hit-them-all"></a>

- **Forgetting a Layer**: My biggest mistake was not considering all the layers at once. I initially forgot the LBR configuration, and later the DB firewall.

- **Assuming the Tool**: I incorrectly assumed the firewall was `firewalld` when on some servers it was `iptables`. I also assumed the `netstat` and `getsebool` commands would be present by default.

- **The Validation "Gotcha"**: My first attempt failed because I didn't complete the on-screen WordPress installation, which the validation script required. This is a classic lab-specific trap.

---

### The Full Arsenal: Every Command I Used
<a name="the-full-arsenal-every-command-i-used"></a>
This is a summary of nearly every command I tried across my four attempts, with a detailed explanation for each.

#### **DB Server Commands**
-   `sudo yum install -y mariadb-server`
    -   **What:** Installs the MariaDB database server software. `yum` is the package manager, and `-y` automatically answers "yes" to prompts.
-   `sudo systemctl start/enable mariadb`
    -   **What:** Manages the database service. `start` runs it now, and `enable` ensures it starts automatically on boot.
-   `sudo mysql -u root`
    -   **What:** Enters the MariaDB administrative command-line shell as the `root` database user.
-   `CREATE DATABASE ...;`, `CREATE USER ...;`, `GRANT ALL PRIVILEGES ...;`
    -   **What:** These are the SQL commands I used to set up the database, create the application's dedicated user, and grant that user full permissions on its database. This is a fundamental security practice.
-   `sudo iptables -I INPUT -p tcp --dport 3306 -j ACCEPT`
    -   **What:** A firewall command to allow incoming connections. `-I INPUT` **I**nserts a rule in the `INPUT` chain, `-p tcp --dport 3306` specifies the protocol and destination port for MariaDB, and `-j ACCEPT` is the action to take.
-   `sudo service iptables save`
    -   **What:** Makes the `iptables` firewall rules permanent so they survive a reboot.

#### **App Server Commands**
-   `sudo yum install -y httpd php php-mysqlnd ...`
    -   **What:** Installs the Apache web server (`httpd`), the PHP language (`php`), and crucial PHP extensions (`php-mysqlnd` for connecting to the database) that WordPress needs to function.
-   `sudo sed -i 's/^Listen .*/Listen 8084/' /etc/httpd/conf/httpd.conf`
    -   **What:** A powerful command to edit a file without opening it. `sed` is a "stream editor." `-i` means "edit in-place." The `s/.../.../` part finds the line starting with `Listen` and replaces it with `Listen 8084`.
-   `sudo systemctl restart/enable httpd`
    -   **What:** Manages the Apache web server service. `restart` is necessary to apply configuration changes.
-   `sudo wget [url]` & `sudo tar -xzf [file]`
    -   **What:** Standard Linux commands to download a file from the internet and then e**x**tract a g**z**ipped tar**f**ile archive.
-   `sudo cp [src] [dest]` & `sudo vi [file]`
    -   **What:** Basic commands to **c**o**p**y a file and edit it with the `vi` text editor. I used these to create the `wp-config.php` file.
-   `sudo chown -R apache:apache /var/www/html`
    -   **What:** Changes the ownership of files. `-R` makes it recursive. This command gives the `apache` user (which the web server runs as) permission to read and write the WordPress files, which is necessary for updates and media uploads.
-   `sudo yum install -y policycoreutils-python-utils`
    -   **What:** A troubleshooting step. This package provides the `getsebool` and `setsebool` commands needed to manage SELinux policies.
-   `sudo setenforce 0`
    -   **What:** A troubleshooting step. This command switches SELinux from `Enforcing` mode to `Permissive` mode for the current session, which is a quick way to test if an SELinux policy is blocking an application.

#### **LBR Server Commands**
-   `sudo yum install -y nginx`
    -   **What:** Installs the Nginx web server, which I used as a load balancer.
-   `sudo netstat -tulpn`
    -   **What:** A powerful networking diagnostic tool. The flags show listening (`l`) TCP (`t`) and UDP (`u`) ports, the program (`p`) using them, and uses numeric (`n`) addresses. I used this to find the `haproxy` process that was causing a port conflict.
-   `sudo systemctl stop/disable haproxy`
    -   **What:** The command I used to stop the conflicting `haproxy` service to free up port 80 for Nginx.
-   `sudo nginx -t`
    -   **What:** A critical safety check. This **t**ests the Nginx configuration files for syntax errors before you try to start the service. It prevents you from taking the server down with a typo.
   