# DevOps Day 42: Creating Custom Docker Networks

Today's task was an important step in building robust, multi-container applications. I moved beyond Docker's default networking and learned how to create a custom, user-defined bridge network with a specific IP address configuration.

This is a foundational skill for creating isolated environments where different services (like a web app and a database) can communicate with each other securely and predictably. This document is my first-person guide to that process.

### The Task

My objective was to create a new, custom Docker network on **App Server 2**. The specific requirements were:
-   The network must be named `ecommerce`.
-   It must use the `bridge` driver.
-   It needed a specific IP configuration:
    -   Subnet: `192.168.0.0/24`
    -   IP Range: `192.168.0.0/24`

### My Step-by-Step Solution

1.  **Connect to the Server:** I first logged into App Server 2 (`ssh steve@stapp02`).

2.  **Create the Custom Network:** I used a single `docker network create` command, providing all the required configuration options as flags.
    ```bash
    sudo docker network create \
      --driver bridge \
      --subnet=192.168.0.0/24 \
      --ip-range=192.168.0.0/24 \
      ecommerce
    ```

3.  **Verification:** The crucial final step was to inspect the network to ensure it was created with the correct settings.
    ```bash
    sudo docker network inspect ecommerce
    ```
    I examined the `IPAM` (IP Address Management) section of the JSON output, which confirmed that the `Subnet` and `IPRange` values matched my command perfectly. This was the definitive proof of success.

### Key Concepts (The "What & Why")

-   **Docker Networks**: For any real application, it's a best practice to create your own user-defined networks instead of using the default one. A custom network provides a secure, isolated environment for a group of containers to communicate.
-   **`bridge` Driver**: This is the most common network driver for a single-host Docker setup. It creates a private, software-based network bridge on the host machine. Containers connected to this network can talk to each other but are isolated from containers on other networks.
-   **Automatic DNS Resolution**: The biggest advantage of a custom bridge network is its built-in DNS server. This allows containers on the same network to find each other by using their container names as hostnames (e.g., a `webapp` container can connect to `mysql://db_container:3306`). This is a huge benefit for creating robust applications.
-   **Subnet and IP Range**: These options provide precise control over the networking environment.
    -   `--subnet`: I defined the overall IP address pool for my network. `192.168.0.0/24` provides a range of 256 addresses.
    -   `--ip-range`: I specified which part of that subnet pool Docker should use to assign IPs to containers.

### Commands I Used

-   `sudo docker network create [options] [network_name]`: The primary command for this task.
    -   `--driver bridge`: Specifies the network driver to use.
    -   `--subnet=[cidr]`: Defines the IP address pool for the network.
    -   `--ip-range=[cidr]`: Defines the range within the subnet from which container IPs will be allocated.
    -   `ecommerce`: The name I assigned to my new network.
-   `sudo docker network inspect [network_name]`: A powerful diagnostic command that outputs a detailed JSON object containing all the configuration and runtime information about a network. I used it to verify the `IPAM` section was correct.
  