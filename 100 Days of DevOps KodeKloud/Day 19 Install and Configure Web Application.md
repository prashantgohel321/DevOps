# DevOps Day 19: Hosting Multiple Websites on a Single Apache Server

<img src="SS/day_19.png">

Today's task was a very common web administration scenario: hosting two separate websites on a single server. This required me to install and configure the Apache web server, transfer the website files from a different machine, and set them up so they were accessible under different URL paths.

This was a great practical exercise that combined multi-server operations with core Apache configuration concepts. I learned how Apache's document root and subdirectory structure work together to serve different content based on the URL the user requests. It's the simplest way to manage multiple small sites without the overhead of setting up complex virtual hosts.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: How Apache Maps URLs to Directories](#deep-dive-how-apache-maps-urls-to-directories)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands Used](#exploring-the-commands-used)

---

### The Task
<a name="the-task"></a>
My objective was to set up a web server on **App Server 1** to host two static websites. The specific requirements were:
1.  Install the Apache (`httpd`) web server.
2.  Configure Apache to listen on port `6400`.
3.  The website content was located on the **jump host** in two directories: `/home/thor/ecommerce` and `/home/thor/games`.
4.  I had to transfer these directories to App Server 1 and set them up so they were accessible at the following URLs:
    -   `http://localhost:6400/ecommerce/`
    -   `http://localhost:6400/games/`

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The process involved a multi-server workflow: configuring the app server, then transferring the files from the jump host, and finally deploying them on the app server.

#### Phase 1: Preparing the Web Server (on App Server 1)
First, I needed to get the Apache server installed and running on the correct port.
1.  I connected to App Server 1: `ssh tony@stapp01`.
2.  I installed the `httpd` package: `sudo yum install -y httpd`.
3.  I edited the main Apache configuration file (`sudo vi /etc/httpd/conf/httpd.conf`) and changed the `Listen 80` directive to `Listen 6400`.
4.  I started the service and enabled it to launch on boot: `sudo systemctl start httpd` and `sudo systemctl enable httpd`.

#### Phase 2: Transferring the Website Files (from Jump Host)
With the server ready, I needed to get the website content.
1.  I opened a new terminal and logged into the **jump host**.
2.  I used the `scp` command with the `-r` (recursive) flag to copy both directories to the home folder of the `tony` user on App Server 1.
    ```bash
    scp -r /home/thor/ecommerce /home/thor/games tony@stapp01:/home/tony
    ```
    This neatly packaged both websites and sent them to a temporary location on the destination server.

#### Phase 3: Deploying the Websites (on App Server 1)
Now I had to move the files from the temporary location into Apache's live web directory.
1.  I went back to my terminal session on **App Server 1**.
2.  The `ecommerce` and `games` directories were now in my home folder. I used `sudo mv` to move both of them into Apache's default document root.
    ```bash
    sudo mv ecommerce /var/www/html/
    sudo mv games /var/www/html/
    ```

#### Phase 4: Verification
The final step was to test my setup locally on App Server 1, as required by the task.
1.  I tested the ecommerce site:
    ```bash
    curl http://localhost:6400/ecommerce/
    ```
    I successfully received the HTML content from its `index.html` file.

2.  I tested the games site:
    ```bash
    curl http://localhost:6400/games/
    ```
    This also returned the correct HTML content. This confirmed that my setup was working perfectly.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
-   **Apache (`httpd`)**: This is one of the world's most popular open-source web servers. Its job is to listen for HTTP requests from clients (like a web browser or the `curl` command) and serve the corresponding files (like HTML, CSS, and images).
-   **Document Root**: Every Apache server has a main directory called the "document root." On my server, this was `/var/www/html`. When a request comes in for the base URL (`http://.../`), Apache looks for files in this directory. This is the starting point for all web content.
-   **Hosting via Subdirectories**: This is the core concept of the task. By creating subdirectories inside the document root (e.g., `/var/www/html/ecommerce`), I am extending the URL structure. Apache automatically maps the URL path to the directory structure. This is the simplest way to host multiple distinct sections or small websites on a single server without needing to configure separate virtual hosts.
-   **`scp` (Secure Copy)**: This is the standard command-line utility for securely transferring files between two computers over an SSH connection. The `-r` (recursive) flag is essential; it tells `scp` to copy entire directories and their contents, not just single files.

---

### Deep Dive: How Apache Maps URLs to Directories
<a name="deep-dive-how-apache-maps-urls-to-directories"></a>
This task was a perfect illustration of Apache's default URL-to-filesystem mapping. It's a simple but powerful concept.

[Image of Apache document root with subdirectories]

1.  **The Base Request:**
    -   When I send a request to `http://localhost:6400/`, Apache receives it.
    -   It looks at its configuration and finds the `DocumentRoot` is set to `/var/www/html`.
    -   It then looks for a default file (like `index.html`) inside that directory and serves it.

2.  **The Subdirectory Request:**
    -   When I send a request to `http://localhost:6400/ecommerce/`, Apache again starts at the `DocumentRoot` (`/var/www/html`).
    -   It then takes the path from the URL (`/ecommerce/`) and appends it to the document root path.
    -   This results in the final path: `/var/www/html/ecommerce/`.
    -   Apache then looks for a default file (like `index.html`) inside this new subdirectory and serves it.

This is the default behavior and requires no special configuration like `Alias` directives, making it a very quick and easy way to organize content.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Forgetting to Configure the Port:** If I hadn't changed the `Listen` directive in `httpd.conf`, Apache would be running on port 80, and my `curl` commands to port `6400` would have failed with "Connection refused."
-   **File Transfer Permissions:** If I had tried to `scp` the files directly to `/var/www/html/` from the jump host, it would have failed with "Permission denied." The `tony` user doesn't have permission to write there. The two-stage process (copying to my home directory first, then using `sudo mv`) is the correct way to handle this.
-   **Forgetting the `-r` flag with `scp`:** If I had just run `scp /home/thor/ecommerce ...`, it would have failed because `scp` without `-r` cannot copy a directory.
-   **Incorrect Final Directory Structure:** Moving the files incorrectly (e.g., ending up with `/var/www/html/ecommerce/ecommerce`) would cause a "404 Not Found" error when trying to access the URL.

---

### Exploring the Commands Used
<a name="exploring-the-commands-used"></a>
-   `sudo yum install -y httpd`: Installs the Apache web server package.
-   `sudo vi /etc/httpd/conf/httpd.conf`: The command to edit Apache's main configuration file to change settings like the listening port.
-   `sudo systemctl start/enable httpd`: The standard commands to manage the Apache service.
-   `scp -r [source1] [source2] [destination]`: Securely copies one or more directories (`-r` for recursive) from a local machine to a remote destination.
-   `sudo mv [source] [destination]`: Moves a file or directory with elevated privileges. I used this to place the website content in the root-owned web directory.
-   `curl [url]`: A versatile command-line tool for making web requests. I used it to test my local web server and verify that both sites were responding correctly.


  