# Linux Lab 11: Network Basics & Troubleshooting

This lab focuses on core Linux networking concepts: identifying IP addresses, understanding routing tables, testing connectivity, and troubleshooting network interfaces. We walk through a scenario where a web server (`devapp01`) is unreachable due to a disabled network interface and a missing default route.

[Image of Linux networking layers]

## Table of Contents
- [Linux Lab 11: Network Basics \& Troubleshooting](#linux-lab-11-network-basics--troubleshooting)
  - [Table of Contents](#table-of-contents)
    - [Key Concepts](#key-concepts)
    - [Step-by-Step Walkthrough](#step-by-step-walkthrough)
      - [1. Identifying IP Addresses](#1-identifying-ip-addresses)
      - [2. Identifying Network Interfaces](#2-identifying-network-interfaces)
      - [3. Finding the Default Gateway](#3-finding-the-default-gateway)
      - [4. Testing Connectivity (Telnet)](#4-testing-connectivity-telnet)
      - [5. Testing Connectivity (Ping)](#5-testing-connectivity-ping)
      - [6. Alternate Interface Check](#6-alternate-interface-check)
      - [7. Troubleshooting the Interface](#7-troubleshooting-the-interface)
      - [8. Fixing the Interface](#8-fixing-the-interface)
      - [9. Fixing the Default Route](#9-fixing-the-default-route)
    - [Command Reference](#command-reference)

---

### Key Concepts
<a name="key-concepts"></a>

* **IP Address:** A unique numerical label (e.g., `172.16.238.187`) assigned to each device connected to a computer network.
* **Network Interface:** The point of interconnection between a computer and a network (e.g., `eth0`, `eth1`).
* **Default Gateway:** The node in a computer network (usually a router) that serves as the access point to another network. If a computer doesn't know where to send a packet, it sends it to the default gateway.
* **Routing Table:** A data table stored in a router or a network host that lists the routes to particular network destinations.
* **`ping`:** A utility used to test the reachability of a host on an IP network.
* **`telnet`:** A protocol used to provide bidirectional interactive text-oriented communication facility using a virtual terminal connection. Often used to test if a specific port is open.

---

### Step-by-Step Walkthrough
<a name="step-by-step-walkthrough"></a>

#### 1. Identifying IP Addresses
<a name="1-identifying-ip-addresses"></a>
**Question:** Which IP addresses are assigned to Bob's Laptop on its primary network interfaces?
**Answer:** `172.16.238.187, 172.16.239.187`

**Explanation:**
We used the `ip a` (or `ip addr`) command.
* We ignored `lo` (Loopback interface, `127.0.0.1`).
* We found `eth0` with IP `172.16.238.187/24`.
* We found `eth1` with IP `172.16.239.187/24`.
* We ignored `eth2` as it's often an internal Docker bridge or secondary management interface in these labs (though technically it is an interface with `172.17.0.4`). The question usually looks for the primary LAN IPs.

#### 2. Identifying Network Interfaces
<a name="2-identifying-network-interfaces"></a>
**Question:** What is the name of the interface that has the IPs address assigned?
**Answer:** `eth0, eth1`

**Explanation:**
Directly from the `ip a` output above:
* `2: eth0@if15...` -> Interface Name: `eth0`
* `3: eth1@if19...` -> Interface Name: `eth1`

#### 3. Finding the Default Gateway
<a name="3-finding-the-default-gateway"></a>
**Question:** What is the default gateway configured in the system?
**Answer:** `172.16.238.1`

**Explanation:**
We used the `ip r` (or `ip route`) command.
* Output: `default via 172.16.238.1 dev eth0`
* This line tells the system: "To reach any destination not explicitly listed in this table, send the traffic to `172.16.238.1` via interface `eth0`."

#### 4. Testing Connectivity (Telnet)
<a name="4-testing-connectivity-telnet"></a>
**Task:** Check connection to HTTP port 80 on `devapp01-web`.
**Command:** `telnet devapp01-web 80`
**Result:** `No route to host`

**Explanation:**
This error is specific. It doesn't mean "Connection Refused" (which means the server is up but the port is closed). "No route to host" usually means the network is unreachable, often due to a firewall blocking ICMP/traffic or a routing issue.

#### 5. Testing Connectivity (Ping)
<a name="5-testing-connectivity-ping"></a>
**Task:** Ping `devapp01-web`.
**Command:** `ping devapp01-web`
**Result:** `Destination Host Unreachable`

**Explanation:**
This confirms the telnet finding. The local machine (Bob's laptop) cannot find a path to the server's IP (`172.16.238.10`). This strongly suggests an issue on the target server or the network between them.

#### 6. Alternate Interface Check
<a name="6-alternate-interface-check"></a>
**Task:** Ping the secondary interface `devapp01` (`172.16.239.10`).
**Command:** `ping devapp01`
**Result:** `0% packet loss` (Success)

**Explanation:**
This is a HUGE clue. The server IS up. We can reach it via `172.16.239.10` (connected to our `eth1` network). However, we cannot reach `172.16.238.10` (connected to our `eth0` network). This suggests the problem is specific to the `eth0` interface on the *remote server*.

#### 7. Troubleshooting the Interface
<a name="7-troubleshooting-the-interface"></a>
**Task:** SSH into the server and inspect `eth0`.
**Command:** `ip link` (run on `devapp01`)
**Output:**
```
16: eth0@if17: <BROADCAST,MULTICAST> mtu 1500 qdisc noqueue state DOWN ...
```
**Diagnosis:** The interface state is **DOWN**. This explains why we couldn't ping `172.16.238.10`. The cable is essentially unplugged.

#### 8. Fixing the Interface
<a name="8-fixing-the-interface"></a>
**Task:** Bring up the `eth0` interface.
**Command:** `sudo ip link set dev eth0 up`

**Explanation:**
This command administratively enables the network interface. Running `ip link` again afterwards confirms the state is now **UP**.

#### 9. Fixing the Default Route
<a name="9-fixing-the-default-route"></a>
**Task:** Add the default route via `eth0`.
**Command:** `sudo ip r add default via 172.16.238.1`

**Explanation:**
Even after the interface is up, the server needs to know how to reply to traffic from the outside world.
* **Why:** Without a default route, the server can only talk to local networks (`172.16.238.0/24`). It wouldn't be able to reach the internet or other subnets.
* **Result:** Adding the route allows the server to route packets back through the gateway (`172.16.238.1`).

---

### Command Reference
<a name="command-reference"></a>

| Command | Purpose | Example |
| :--- | :--- | :--- |
| `ip a` | **Show** IP addresses and interface status | `ip a` |
| `ip r` | **Show** the routing table | `ip r` |
| `ping` | **Test** connectivity to a host | `ping google.com` |
| `telnet` | **Test** connectivity to a specific port | `telnet server 80` |
| `ip link set dev [iface] up` | **Enable** a network interface | `sudo ip link set dev eth0 up` |
| `ip link set dev [iface] down` | **Disable** a network interface | `sudo ip link set dev eth0 down` |
| `ip r add default via [gateway]` | **Add** a default gateway | `sudo ip r add default via 192.168.1.1` |

   