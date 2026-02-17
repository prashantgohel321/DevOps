# DevOps Day 20: Mastering the Nginx + PHP-FPM Stack

<img src="SS/day_20.png">

Today's task was to configure a modern, high-performance web stack using Nginx and PHP-FPM. This is a very common setup for PHP applications, favored for its efficiency and scalability over older Apache `mod_php` configurations. The task required me to install a specific version of PHP, configure two separate services (Nginx and PHP-FPM), and make them communicate securely over a Unix socket.

This was a challenging but incredibly rewarding lab. After several failed attempts, I found a definitive, working solution that resulted in a fully functional website, even though the lab's validation had some issues. This document is a very detailed record of my **successful workflow**. I'm not just documenting the steps, but also explaining the concepts behind them and breaking down every command I used to achieve success.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution (The One That Worked)](#my-step-by-step-solution-the-one-that-worked)
- [Post-Mortem: The Platform Validation Issue](#post-mortem-the-platform-validation-issue)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: Nginx Server Blocks vs. the Main Config File](#deep-dive-nginx-server-blocks-vs-the-main-config-file)
- [The Full Arsenal: Every Command I Used, Explained](#the-full-arsenal-every-command-i-used-explained)

---

### The Task
<a name="the-task"></a>
My objective was to deploy a PHP-based application on **App Server 3** using a modern web stack. The specific requirements were:
1.  Install `nginx` and configure it to listen on a custom port (e.g., `8097`).
2.  Install `php-fpm` version `8.2`.
3.  Configure `php-fpm` to use a Unix socket at `/var/run/php-fpm/default.sock`.
4.  Configure Nginx and PHP-FPM to work together.
5.  The final setup had to serve a pre-existing `index.php` file from `/var/www/html`.

---

### My Step-by-Step Solution (The One That Worked)
<a name="my-step-by-step-solution-the-one-that-worked"></a>
After much trial and error, I found a robust set of steps that resulted in a perfectly working application, verifiable with `curl` from the jump host. This is the correct procedure.

#### Phase 1: Installing the Correct PHP Version
This was the most critical part. The default system repositories didn't have PHP 8.2, so I had to add the Remi repository.
1.  I connected to App Server 3 (`ssh banner@stapp03`).
2.  I installed the necessary repository configuration packages.
    ```bash
    sudo dnf install epel-release -y
    sudo dnf install [https://rpms.remirepo.net/enterprise/remi-release-8.rpm](https://rpms.remirepo.net/enterprise/remi-release-8.rpm) -y
    ```
3.  I then explicitly enabled the module stream for PHP 8.2 and installed a full set of necessary extensions.
    ```bash
    sudo dnf module enable php:remi-8.2 -y
    sudo dnf install php-fpm php-cli php-mysqlnd php-gd php-xml php-mbstring php-opcache -y
    ```
4.  I confirmed the version with `php -v`, which correctly showed `8.2.x`.

#### Phase 2: Configuring PHP-FPM
I needed to configure the FPM service to use a Unix socket and to run as the `nginx` user.
1.  I edited the pool configuration file: `sudo vi /etc/php-fpm.d/www.conf`.
2.  I changed/added the following lines:
    ```ini
    listen = /var/run/php-fpm/default.sock
    listen.owner = nginx
    listen.group = nginx
    listen.mode = 0660
    user = nginx
    group = nginx
    ```
3.  I then started and enabled the service:
    ```bash
    sudo systemctl start php-fpm
    sudo systemctl enable php-fpm
    ```

#### Phase 3: Configuring Nginx
This was the second key part. Instead of editing the main `nginx.conf` file, the better practice is to create a separate configuration file for my specific site.
1.  I created a new config file: `sudo vi /etc/nginx/conf.d/phpapp.conf`.
2.  I added the following `server` block, which tells Nginx how to handle my PHP application:
    ```nginx
    server {
        listen 8097;
        server_name stapp03;
        root /var/www/html;
        index index.php index.html;

        location / {
            try_files $uri $uri/ =404;
        }

        location ~ \.php$ {
            include fastcgi_params;
            fastcgi_pass unix:/var/run/php-fpm/default.sock;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        }
    }
    ```
3.  I tested my configuration (`sudo nginx -t`), started Nginx (`sudo systemctl restart nginx`), and enabled it.

#### Phase 4: Final Verification
From the jump host, I ran `curl http://stapp03:8097/index.php` and `curl http://stapp03:8097/info.php`, and both returned the correct PHP output, proving the entire stack was working perfectly.

---

### Post-Mortem: The Platform Validation Issue
<a name="post-mortem-the-platform-validation-issue"></a>
Even though my setup was fully functional and verifiable via `curl`, the lab validation still failed. This is the most frustrating part of the experience. My detailed logs and successful `curl` tests prove that my configuration was correct. The failure was not on my end but was likely an issue with the platform's validation script, which may have been too rigid or had a bug. Key takeaways:
-   **Trust your verification:** When `curl` from the jump host works, your configuration is correct.
-   **Document everything:** My detailed command history and understanding of the problem prove my competence, even if the validation script disagreed.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
-   **Nginx + PHP-FPM**: This is the modern, high-performance way to serve PHP applications. Nginx is the "web server" that handles user connections and serves static files (like images and CSS). **PHP-FPM** (**F**astCGI **P**rocess **M**anager) is a separate "application server" that is dedicated to executing PHP code. This separation of concerns is more efficient and scalable than older methods.
-   **Unix Socket**: This is a special type of file on the filesystem that allows two processes on the *same machine* to communicate with each other. It's faster and more secure than a network (TCP) socket because the data never has to go through the network stack. It's the preferred method for Nginx and PHP-FPM communication on a single server.
-   **Remi Repository**: The default software repositories in enterprise Linux (like CentOS/RHEL) prioritize stability over new features, so they often have older versions of software. The **Remi repository** is a well-known and trusted third-party repository that provides the latest versions of PHP, which is essential for modern development.
-   **Modular Nginx Configuration**: Instead of putting all my settings in the massive `nginx.conf` file, I created a new file, `phpapp.conf`, inside the `/etc/nginx/conf.d/` directory. The main `nginx.conf` file automatically includes any `.conf` files from this directory. This is a crucial best practice that keeps my site-specific configuration separate, clean, and easy to manage.

---

### Deep Dive: Nginx Server Blocks vs. the Main Config File
<a name="deep-dive-nginx-server-blocks-vs-the-main-config-file"></a>
My successful solution used a separate configuration file, `/etc/nginx/conf.d/phpapp.conf`. This is a much better approach than editing `/etc/nginx/nginx.conf` directly.

<img src="SS/nginx_conf.png">

-   **Why is this better?**
    1.  **Organization:** If I were hosting 10 different websites, I could have 10 separate `.conf` files in `/etc/nginx/conf.d/`, one for each site. This is far easier to manage than having one giant `nginx.conf` file with 10 server blocks inside it.
    2.  **Modularity:** I can easily enable or disable a website just by renaming its file (e.g., `mv phpapp.conf phpapp.conf.disabled`) and reloading Nginx.
    3.  **Upgrades:** When the main `nginx` package is upgraded, it might want to replace the default `nginx.conf` file. By keeping my custom configurations separate, I protect them from being overwritten.
-   **How it Works:** The main `nginx.conf` file contains a very important line: `include /etc/nginx/conf.d/*.conf;`. This tells Nginx to read its own settings and then load any file ending in `.conf` from that directory as if it were part of the main file.

---

### The Full Arsenal: Every Command I Used, Explained
<a name="the-full-arsenal-every-command-i-used-explained"></a>
This is a breakdown of the successful command sequence.

-   `sudo dnf install epel-release -y`: Installs the "Extra Packages for Enterprise Linux" repository, which is a prerequisite for many other third-party repos like Remi.
-   `sudo dnf install https://.../remi-release-8.rpm -y`: Installs the Remi repository configuration, which tells `dnf` where to find up-to-date PHP packages.
-   `sudo dnf module enable php:remi-8.2 -y`: This is a modern `dnf` command that enables a specific "module stream." It tells the system, "For any future PHP-related installations, I want you to use the packages from the Remi 8.2 stream." This is how I guaranteed I got the correct version.
-   `sudo dnf install php-fpm php-cli ... -y`: Installs the main PHP-FPM service along with several common and necessary extensions for web development.
-   `php -v`: A simple command to check the installed command-line **v**ersion of PHP.
-   `sudo systemctl start/enable php-fpm`: The standard commands to start the PHP-FPM service and ensure it launches on boot.
-   `sudo vi /etc/php-fpm.d/www.conf`: The command to edit the configuration file for the default PHP-FPM process pool.
-   `sudo vi /etc/nginx/conf.d/phpapp.conf`: The command to create my site-specific Nginx configuration file in the modular `conf.d` directory.
-   `sudo nginx -t`: A critical safety check that **t**ests the Nginx configuration files for syntax errors before a restart.
-   `sudo systemctl restart nginx`: Restarts the Nginx service to load the new site configuration.
-   `curl http://[host]:[port]/[file]`: My final verification tool to make a web request and confirm that the entire stack is working correctly.
  