# DevOps Day 13: Securing Servers with an `iptables` Firewall

Today's task was a deep dive into network security, a fundamental responsibility for any DevOps engineer. The goal was to move from an unsecured setup, where our application servers were open to the world, to a hardened configuration using a firewall. I learned how to install, configure, and manage `iptables`, the classic Linux firewall, to enforce a very specific security policy.

The most critical lesson from this task was the importance of **rule order**. It's not enough to just add rules; you have to add them in the correct sequence for the firewall to behave as expected. This was a fantastic, hands-on demonstration of a core security principle.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: The Importance of `iptables` Rule Order](#deep-dive-the-importance-of-iptables-rule-order)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands Used](#exploring-the-commands-used)

---

### The Task
<a name="the-task"></a>
My objective was to secure the Apache web servers running on port `8086` on all three app servers. The specific requirements were:
1.  Install the `iptables` service on all app servers.
2.  Create firewall rules to **block all incoming traffic** to port `8086` **except** for traffic coming from the Load Balancer (LBR) host.
3.  Ensure these firewall rules are permanent and will survive a server reboot.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
This process had to be repeated on all three app servers (`stapp01`, `stapp02`, `stapp03`).

#### Prerequisite: Finding the LBR IP
Before I could write any rules, I needed to know the IP address of the trusted source. I checked the lab's infrastructure details and found the IP for the LBR host, `stlb01` (e.g., `172.16.238.14`).

#### Main Workflow (for each server)

1.  **Connect and Install:** I first connected to the app server (e.g., `ssh tony@stapp01`) and installed the necessary package to manage the `iptables` service.
    ```bash
    sudo yum install -y iptables-services
    ```

2.  **Start and Enable the Service:** I started the firewall and enabled it to ensure it would launch automatically on boot.
    ```bash
    sudo systemctl start iptables
    sudo systemctl enable iptables
    ```

3.  **Add the Firewall Rules (The Critical Part):** The order of these two rules is the key to success.
    * **Rule 1: Allow the LBR Host.** I **I**nserted this rule at the very top (position `1`) of the `INPUT` chain. This ensures that any traffic from the LBR is immediately accepted.
        ```bash
        # I replaced 172.16.238.14 with the actual LBR IP
        sudo iptables -I INPUT 1 -s 172.16.238.14 -p tcp --dport 8086 -j ACCEPT
        ```
    * **Rule 2: Block Everyone Else.** After the allow rule was in place, I **A**ppended a rule to the end of the chain to `REJECT` all other traffic destined for that port.
        ```bash
        sudo iptables -A INPUT -p tcp --dport 8086 -j REJECT
        ```

4.  **Save the Rules:** `iptables` rules are temporary by default. This command makes them permanent by writing them to a configuration file.
    ```bash
    sudo service iptables save
    ```

5.  **Verification:** I checked my work by listing the rules with line numbers.
    ```bash
    sudo iptables -L INPUT -n --line-numbers
    ```
    The output correctly showed my `ACCEPT` rule at number 1, proving the order was correct. A final test from the jump host (`curl http://stapp01:8086`) failed as expected, confirming the firewall was blocking untrusted traffic.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
-   **`iptables`**: This is a user-space application that allows a system administrator to configure the tables provided by the Linux kernel firewall. It's a foundational tool for network security on Linux.
-   **Defense in Depth**: This task is a perfect example of "defense in depth." Even if my Apache application had a vulnerability, this firewall provides an extra layer of security by ensuring that only the trusted Load Balancer can even attempt to connect to it.
-   **Principle of Least Privilege (Network Edition)**: The rules I created enforce a network version of the principle of least privilege. By default, no one can access the port (`REJECT`). I then opened it up *only* for the one specific source (`ACCEPT` from LBR) that absolutely needs access.

---

### Deep Dive: The Importance of `iptables` Rule Order
<a name="deep-dive-the-importance-of-iptables-rule-order"></a>
The most critical concept in this task was understanding that `iptables` processes rules sequentially from top to bottom. The first rule that a network packet matches is the one that is applied, and processing stops.

[Image of iptables firewall rule processing]

Let's consider the two possible scenarios:

1.  **Correct Order (My Solution):**
    -   `Rule 1: ACCEPT traffic from LBR_IP`
    -   `Rule 2: REJECT traffic from ANY_IP`
    * When a packet arrives from the LBR, it matches Rule 1 and is **ACCEPTED**. Processing stops.
    * When a packet arrives from anywhere else (like my jump host), it does *not* match Rule 1. It continues down the chain, matches Rule 2, and is **REJECTED**. This is the desired behavior.

2.  **Incorrect Order (A Common Mistake):**
    -   `Rule 1: REJECT traffic from ANY_IP`
    -   `Rule 2: ACCEPT traffic from LBR_IP`
    * When a packet arrives from the LBR, it matches Rule 1 (since the LBR is part of "ANY_IP") and is immediately **REJECTED**. It never even gets a chance to be evaluated against Rule 2. This would block all traffic and break the application.

This is why I used `iptables -I INPUT 1` to **I**nsert the allow rule at the very top, and `iptables -A INPUT` to **A**ppend the deny rule at the very bottom.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Getting the Rule Order Wrong:** As explained above, this is the most common and critical mistake.
-   **Forgetting to Save the Rules:** Running `sudo service iptables save` is essential. Without it, the firewall rules would disappear after the next server reboot, silently re-opening the security hole.
-   **Using the Wrong IP Address:** Using the IP of the jump host instead of the LBR host would lead to the application being inaccessible.
-   **Forgetting to Repeat the Steps:** The task required this configuration on all three app servers. Forgetting to apply it to one would leave a single server vulnerable.

---

### Exploring the Commands Used
<a name="exploring-the-commands-used"></a>
-   `sudo yum install -y iptables-services`: Installs the package that allows the `iptables` rules to be managed as a persistent service.
-   `sudo systemctl start/enable iptables`: Manages the firewall service itself.
-   `sudo iptables -I INPUT 1 -s [IP] -p tcp --dport [port] -j ACCEPT`:
    -   `-I INPUT 1`: **I**nsert a rule into the `INPUT` chain at position `1`.
    -   `-s [IP]`: Specifies the **s**ource IP address.
    -   `-p tcp --dport [port]`: Specifies the **p**rotocol (TCP) and **d**estination **port**.
    -   `-j ACCEPT`: The "jump" target. If the packet matches, `ACCEPT` it.
-   `sudo iptables -A INPUT ... -j REJECT`:
    -   `-A INPUT`: **A**ppends a rule to the end of the `INPUT` chain.
    -   `-j REJECT`: If the packet matches, `REJECT` it (and send a reply saying it was rejected).
-   `sudo service iptables save`: Saves the current in-memory rules to a configuration file in `/etc/sysconfig/iptables`.
-   `sudo iptables -L INPUT -n --line-numbers`:
    -   `-L`: **L**ists the rules in a chain.
    -   `-n`: Shows **n**umeric output (IP addresses and port numbers instead of trying to resolve names).
    -   `--line-numbers`: Displays the position of each rule in the chain, which is great for verification.
 