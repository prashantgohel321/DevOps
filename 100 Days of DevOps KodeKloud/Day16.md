# DevOps Day 16: Building a High-Availability Stack with an Nginx Load Balancer

Today, I leveled up my infrastructure skills by tackling a core concept of modern web architecture: load balancing. The task was to take a web application running on multiple servers and put an Nginx load balancer in front of them. This is the fundamental step in creating a scalable and highly available system that can handle increased traffic and tolerate server failures.

The process was a fantastic real-world exercise. It wasn't just about writing a configuration file; it started with a crucial investigation phase. I had to diagnose the state of the backend servers first, which even involved installing missing tools. Only after I had all the correct information could I properly configure the load balancer.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: The "Investigate First" Principle](#deep-dive-the-investigate-first-principle)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands Used](#exploring-the-commands-used)

---

### The Task
<a name="the-task"></a>
My objective was to improve the performance and reliability of a website by setting up a load balancer. The specific requirements were:
1.  Install `nginx` on the designated Load Balancer (LBR) server.
2.  Configure Nginx to act as a load balancer, distributing traffic to all three backend app servers.
3.  I had to do this without changing the existing Apache configuration on the app servers. This meant I first had to figure out what port they were using.
4.  The final setup had to be accessible through a button in the lab UI.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
My approach was to first gather intelligence on the backend servers and then use that information to configure the LBR server.

#### Step 1: The Investigation Phase
I knew I couldn't configure the load balancer without knowing the IP addresses and, most importantly, the port numbers of the app servers.

* **Failure 1: `netstat` command not found**
    I logged into the first app server (`ssh tony@stapp01`) and tried to find the Apache port:
    ```bash
    sudo netstat -tulpn | grep httpd
    # Output: sudo: netstat: command not found
    ```
    This was a great lesson: never assume a minimal server has all the tools you're used to.

* **Solution 1: Install `net-tools`**
    The fix was to install the package that provides the `netstat` command.
    ```bash
    sudo yum install -y net-tools
    ```

* **Discovery:** After installing the package, I re-ran the command and found the critical piece of information.
    ```bash
    sudo netstat -tulpn | grep httpd
    # Output: tcp 0 0 0.0.0.0:6200 ... LISTEN ... /httpd
    ```
    I now knew the backend Apache servers were all running on port `6200`. I also made sure the `httpd` service was `active (running)` on all three app servers.

#### Step 2: LBR Server Configuration
With the backend port confirmed, I moved to the LBR server (`ssh loki@stlb01`).

1.  **Install Nginx:**
    ```bash
    sudo yum install -y nginx
    ```

2.  **Configure the Load Balancer:**
    This was the main part of the task. I edited the Nginx configuration file (`sudo vi /etc/nginx/nginx.conf`) and made two critical additions.
    * **a) Define the `upstream` server pool:** Right inside the `http { ... }` block, I defined a named group for my app servers, using the port I discovered.
        ```nginx
        upstream my_app_servers {
            server 172.16.238.10:6200;  # App Server 1
            server 172.16.238.11:6200;  # App Server 2
            server 172.16.238.12:6200;  # App Server 3
        }
        ```
    * **b) Configure the `proxy_pass`:** Inside the default `server` block, I modified the `location /` section to pass all incoming traffic to my `upstream` pool.
        ```nginx
        location / {
            proxy_pass http://my_app_servers;
        }
        ```

3.  **Test and Start the Service:** I never restart a service without testing the configuration first.
    ```bash
    sudo nginx -t
    # It returned 'syntax is ok' and 'test is successful'

    sudo systemctl start nginx
    sudo systemctl enable nginx
    ```

---

### Step 3: Verification
The final step was to click the "StaticApp" button in the lab UI. The website loaded perfectly, proving that the load balancer was correctly receiving traffic and forwarding it to one of the backend app servers on **port 6200**.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>

- **Load Balancer**: This is a server that acts as a "traffic cop" for a website. It accepts all incoming user requests and distributes them across a pool of backend servers. This is the foundation of a scalable and reliable web architecture.

- **High Availability**: If one of my app servers were to fail, the load balancer would detect this and automatically stop sending traffic to it. Users would continue to be served by the remaining healthy servers, experiencing no downtime.

- **Scalability**: If my website traffic grew, I could simply add a fourth or fifth app server. I would only need to add one line to my Nginx upstream block to instantly increase the capacity of my application.

- **Nginx upstream block**: This is a key Nginx feature. It lets you define a named group of servers. Nginx can then use different algorithms (like round-robin, least connections) to distribute traffic among them.

- **Nginx proxy_pass directive**: This is the instruction that does the work. It tells Nginx, "For any request that matches this location, forward it to the specified upstream group."

---

### Deep Dive: The "Investigate First" Principle
<a name="deep-dive-the-investigate-first-principle"></a>
The most important lesson from this task was to investigate before you configure. I could have guessed the backend port was 80 or 8080, and my Nginx configuration would have been syntactically correct, but it would have failed in practice. The load balancer would have tried to connect to the wrong port, found nothing, and returned a "502 Bad Gateway" error to the user.

My methodical approach was key:

- **Form a hypothesis**: "I need to know the backend port."

- **Choose a tool**: netstat is the right tool for checking listening ports.

- **Encounter a problem**: The tool was missing.

- **Solve the sub-problem**: Install the net-tools package.

- **Gather the data**: Run netstat again and get the correct port (6200).

- **Configure with confidence**: Write the Nginx configuration file using the verified data.

This process prevents guesswork and is the fastest way to a correct solution.

---

### Common Pitfalls
<a name="common-pitfalls"></a>

- **Guessing the Backend Port**: The most common failure would be assuming the backend port is 80 and not checking. This would lead to 502 errors.

- **Firewall on the LBR**: Forgetting to open port 80 (HTTP) on the load balancer server's own firewall would mean no users could connect to it in the first place.

- **Backend Server Down**: Not checking that the httpd service is actually running on all app servers. The load balancer can't forward traffic to a service that's stopped.

- **Typo in an IP Address**: A simple typo in one of the server lines in the upstream block would cause that specific server to be unreachable.

---

### Exploring the Commands Used
<a name="exploring-the-commands-used"></a>

- **`sudo yum install -y net-tools`**: Installs the package containing classic networking utilities like `netstat`.

- **`sudo netstat -tulpn | grep httpd`**: My primary investigation tool. It shows all listening TCP/UDP ports and the programs using them, filtered to show only the httpd process.

- **`sudo vi /etc/nginx/nginx.conf`**: The command to edit the main Nginx configuration file.

- **`sudo nginx -t`**: A critical safety check that tests the Nginx configuration files for syntax errors before a restart.

- **`sudo systemctl start/enable nginx`**: The standard commands to start the Nginx service and ensure it launches on boot.