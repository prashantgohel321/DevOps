# DevOps Day 15: Deploying a Secure Nginx Web Server with SSL

Today's task was a comprehensive, end-to-end web server setup. I moved beyond just starting and stopping services to performing a full-stack manual deployment: installing the Nginx web server, securing it with an SSL certificate to enable HTTPS, deploying custom content, and configuring the firewall.

This was a fantastic exercise because it mirrored the exact steps required to launch a secure website. I learned how to handle sensitive files like SSL keys, how to write a basic Nginx server block configuration, and the importance of testing the configuration before applying it.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: Anatomy of an Nginx SSL Server Block](#deep-dive-anatomy-of-an-nginx-ssl-server-block)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands Used](#exploring-the-commands-used)

---

### The Task
<a name="the-task"></a>
My objective was to deploy a secure, static website on **App Server 2**. The specific requirements were:
1.  Install the `nginx` web server.
2.  Take a self-signed SSL certificate (`nautilus.crt`) and private key (`nautilus.key`) from `/tmp`, move them to an appropriate location, and configure Nginx to use them.
3.  Create an `index.html` file in the Nginx document root with the content "Welcome!".
4.  Ensure the website was accessible from the jump host over HTTPS using `curl`.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The process involved preparing the server, configuring Nginx, deploying the content, and verifying the entire setup.

#### Step 1: Install Nginx and Prepare Certificates
First, I connected to App Server 2 (`ssh steve@stapp02`) and installed Nginx.
```bash
sudo yum install -y nginx
```
Next, I handled the SSL files. It's bad practice to leave them in `/tmp`. I created a dedicated, secure directory for them.
```bash
# Create a secure directory for SSL files
sudo mkdir -p /etc/nginx/ssl

# Move the certificate and key
sudo mv /tmp/nautilus.crt /etc/nginx/ssl/
sudo mv /tmp/nautilus.key /etc/nginx/ssl/

# CRITICAL: Set restrictive permissions on the private key so only root can read it
sudo chmod 600 /etc/nginx/ssl/nautilus.key
```

#### Step 2: Configure Nginx for SSL/HTTPS
This was the core of the task. I edited the main Nginx configuration file.
```bash
sudo vi /etc/nginx/nginx.conf
```
Inside the `http { ... }` block, I added a new `server` block specifically to handle HTTPS traffic on port 443.
```nginx
    server {
        listen       443 ssl;
        listen       [::]:443 ssl;
        server_name  stapp02.stratos.xfusioncorp.com;
        root         /usr/share/nginx/html;

        ssl_certificate "/etc/nginx/ssl/nautilus.crt";
        ssl_certificate_key "/etc/nginx/ssl/nautilus.key";
    }
```
Before restarting, I ran a crucial safety check to validate my configuration syntax.
```bash
sudo nginx -t
# Output: ... configuration file /etc/nginx/nginx.conf syntax is ok
# Output: ... configuration file /etc/nginx/nginx.conf test is successful
```
This test prevented me from accidentally breaking the server with a typo.

#### Step 3: Deploy Content and Start the Service
I created the `index.html` file in the default web root directory.
```bash
echo "Welcome!" | sudo tee /usr/share/nginx/html/index.html
```
Then, I started Nginx and opened the firewall for HTTPS traffic.
```bash
sudo systemctl start nginx
sudo systemctl enable nginx

# Add a permanent firewall rule for the 'https' service (port 443)
sudo firewall-cmd --permanent --add-service=https
# Apply the new rule immediately
sudo firewall-cmd --reload
```

#### Step 4: Final Verification
From the jump host, I ran the final test. The `-k` flag is essential to tell `curl` to trust the self-signed certificate.
```bash
# Run from the jump_host
curl -Ik https://stapp02
```

> The output HTTP/1.1 200 OK was the definitive proof that my secure web server was configured correctly and accessible.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>

**Nginx**: A high-performance web server that is incredibly popular for its speed and efficiency. I installed it to serve as the engine for our website.

**SSL/TLS (HTTPS)**: This is the security layer for the web. By installing an SSL certificate `(.crt)` and its corresponding private key `(.key)`, I enabled HTTPS. This encrypts all communication between the server and the client, protecting data from eavesdropping.

**Self-Signed Certificate**: For this lab, the certificate was "`self-signed`," meaning it wasn't validated by a trusted public Certificate Authority (CA). This is fine for testing but would show a security warning in a real browser. The `-k` flag in `curl` is the command-line equivalent of clicking "Proceed anyway."

**Nginx server Block**: This is the basic unit of configuration in Nginx. Each server block defines a virtual server that handles requests. By creating a block that listens on `port 443 ssl`, I instructed Nginx to handle secure HTTPS traffic.

---

### Deep Dive: Anatomy of an Nginx SSL Server Block
<a name="deep-dive-anatomy-of-an-nginx-ssl-server-block"></a>
The server block I added was simple but contained all the essential directives for a basic HTTPS server.

- **`listen 443 ssl;`**: This is the most important line. It tells Nginx to listen on **port 443** (the standard for HTTPS) and to expect ssl (encrypted) traffic on this port.

- **`server_name ...;`**: This directive is used for **name-based virtual hosting**. It tells Nginx which server block to use based on the domain name the client requested.

- **`root /usr/share/nginx/html;`**: This specifies the "**document root**"—the directory on the server where Nginx will look for the files to serve (like my **index.html**).

- **`ssl_certificate ...;`**: This directive points to the location of the public **SSL certificate file (.crt)**. This is the file that is sent to the client.

- **`ssl_certificate_key ...;`**: This directive points to the location of the **secret private key file (.key)**. This file must be kept secure on the server.

---

Common Pitfalls
<a name="common-pitfalls"></a>

- **Forgetting nginx `-t`**: A common mistake is to restart Nginx after editing the configuration without testing it first. A single typo in **`nginx.conf`** can prevent the entire server from starting. The nginx **`-t`** command is a critical safety net.

- **Incorrect File Permissions**: The SSL private key (.key file) is highly sensitive. If its permissions are too open (e.g., readable by any user), Nginx will often refuse to start as a security precaution. Setting permissions to 600 (read/write for the owner only) is a best practice.

- **Forgetting the Firewall**: The most common oversight. The Nginx server could be running perfectly, but if the firewall is blocking **`port 443`**, no one from the outside will be able to connect.

- **Forgetting -k with curl**: When testing a self-signed certificate, forgetting the **`-k`** flag will cause **`curl`** to fail with a certificate validation error, which might be mistaken for a server-side problem.

---

### Exploring the Commands Used
<a name="exploring-the-commands-used"></a>

- **`sudo yum install -y nginx`**: Installs the Nginx web server.

- **`sudo mkdir -p /etc/nginx/ssl`**: Creates the directory to securely store SSL certificate files.

- **`sudo mv [src] [dest]`**: Moves the certificate and key to their new, secure location.

- **`sudo chmod 600 [file]`**: Sets restrictive read/write permissions for the owner only, a critical security step for the private key.

- **`sudo nginx -t`**: Tests the Nginx configuration files for syntax errors before restarting the service.

- **`echo "..." | sudo tee [file]`**: A great way to write a simple text file as root without opening an editor.

- **`sudo systemctl start/enable nginx`**: Starts the Nginx service and enables it to launch on boot.

- **`sudo firewall-cmd --permanent --add-service=https`**: Adds a permanent rule to the firewall to allow https (TCP port 443) traffic.

- **`curl -Ik https://[host]`**:

    - **`-I`**: Fetches the HTTP headers only.

    - **`-k`**: Allows curl to connect to insecure sites (i.e., those with self-signed certificates).

