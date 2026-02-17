# Docker Level 3, Task 1: Creating Custom Networks

<img src="diagrams/docker_L3T1.png">

Today, I moved into a more advanced and powerful area of Docker: networking. The task was to create a custom, user-defined bridge network with a specific IP address configuration. This is a foundational skill for building secure and scalable multi-container applications, moving beyond the limitations of the default Docker network.

I learned how to define a network's topology, including its subnet and the range of IPs available for containers. This exercise was the first step in understanding how to build isolated environments where different services (like a web app and a database) can communicate with each other securely.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: The Magic of Automatic DNS Resolution](#deep-dive-the-magic-of-automatic-dns-resolution)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands Used](#exploring-the-commands-used)

---

### The Task
<a name="the-task"></a>
My objective was to create a new, custom Docker network on **App Server 2**. The specific requirements were:
1.  The network must be named `media`.
2.  It must use the `bridge` driver.
3.  It needed a specific IP configuration:
    -   Subnet: `192.168.30.0/24`
    -   IP Range: `192.168.30.0/24`

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The process was very straightforward and performed entirely on the command line of App Server 2.

#### Step 1: Connect to the Server
First, I logged into App Server 2 as the `steve` user.
```bash
ssh steve@stapp02
```

#### Step 2: Create the Custom Network
I used a single `docker network create` command, providing all the required configuration options as flags.
```bash
sudo docker network create \
  --driver bridge \
  --subnet=192.168.30.0/24 \
  --ip-range=192.168.30.0/24 \
  media
```
The command returned the unique ID of the new network, which was my first confirmation of success.

#### Step 3: Verification
The final and most important step was to inspect the network to ensure it was created with the correct settings.
```bash
sudo docker network inspect media
```
I carefully examined the JSON output, specifically the `IPAM` (IP Address Management) section.
```json
"IPAM": {
    "Driver": "default",
    "Options": {},
    "Config": [
        {
            "Subnet": "192.168.30.0/24",
            "IPRange": "192.168.30.0/24"
        }
    ]
},
```
Seeing that the `Subnet` and `IPRange` values matched my command perfectly was the definitive proof that the task was completed successfully.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
-   **Docker Networks**: By default, Docker gives you a simple `bridge` network, but for any real application, you should create your own. A user-defined network provides a secure, isolated environment for a group of containers to communicate.
-   **`bridge` Driver**: This is the most common network driver for a single-host Docker setup. It creates a private, software-based network bridge on the host machine. Any container connected to this network can talk to any other container on the same network, but they are isolated from containers on other networks.
-   **Subnet and IP Range**: These options give me precise control over the networking environment.
    -   `--subnet`: I defined the overall IP address pool for my network. `192.168.30.0/24` gave me a range of 256 addresses (from `192.168.30.0` to `192.168.30.255`).
    -   `--ip-range`: I specified which part of that subnet pool Docker should use to assign IPs to containers. In my case, I made the range the same as the subnet, which is a common setup. This is useful if you want to reserve a portion of your subnet for static IPs or other services.

---

### Deep Dive: The Magic of Automatic DNS Resolution
<a name="deep-dive-the-magic-of-automatic-dns-resolution"></a>
The biggest reason to use a custom user-defined bridge network is its **built-in DNS server**. This is a feature that the default bridge network does not have.

[Image of an isolated Docker bridge network with two containers]

-   **How it Works:** When you create a custom network, Docker runs a DNS server for that network. When you attach a container to this network, Docker automatically registers the container's name and its IP address with this internal DNS server.
-   **The Benefit:** This means containers can find each other simply by using their names. For example, if I have a `webapp` container and a `database` container on my `media` network, my web app's connection string doesn't need a hardcoded IP address. It can simply be:
    `mysql_connection_string = "mysql://user:pass@database:3306/mydb"`
    Docker's internal DNS will automatically resolve the hostname `database` to the correct private IP address of the `database` container. If the database container is restarted and gets a new IP address, the DNS updates automatically, and my `webapp` never breaks. This is a huge advantage for creating robust, loosely coupled applications.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **IP Address Conflicts:** If I had tried to create a network with a subnet that was already in use by my host machine or another Docker network, the command would have failed.
-   **Invalid CIDR Notation:** A typo in the subnet or IP range (e.g., `192.168.30.0/33` or forgetting the `/24`) would cause the command to fail.
-   **Not Inspecting the Network:** A common mistake is to run the `create` command and assume it worked. The `docker network inspect` command is the only way to be 100% sure that all the specific IP configurations were applied correctly.
-   **Forgetting the Driver:** While `bridge` is the default, explicitly stating `--driver bridge` makes the command clearer and is a good practice.

---

### Exploring the Commands Used
<a name="exploring-the-commands-used"></a>
-   `sudo docker network create [options] [network_name]`: The primary command for this task.
    -   `--driver bridge`: Specifies the network driver to use.
    -   `--subnet=[cidr]`: Defines the IP address pool for the network.
    -   `--ip-range=[cidr]`: Defines the range within the subnet from which container IPs will be allocated.
    -   `media`: The name I assigned to my new network.
-   `sudo docker network inspect [network_name]`: A powerful diagnostic command. It outputs a detailed JSON object containing all the configuration and runtime information about a network. I used it to verify the `IPAM` section.
-   `sudo docker network ls`: A useful command to **l**i**s**t all the available networks on the host, which is a good first step before creating a new one.
   