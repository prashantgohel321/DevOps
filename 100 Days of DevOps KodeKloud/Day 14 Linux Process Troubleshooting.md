# DevOps Day 14: The Multi-Server Troubleshooting and Standardization Challenge

Today's task was a true test of a DevOps engineer's core responsibilities: not just fixing a problem on one server, but identifying the faulty system among many and then ensuring a consistent, correct configuration across the entire fleet. It was a journey from diagnosis to remediation and finally to standardization.

I had to investigate a failed Apache service, uncover a port conflict caused by a misconfigured service, fix it, and then apply the correct configuration (including a specific firewall type) to all app servers. This was a great lesson in the importance of consistency in an infrastructure.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: The Importance of Standardization](#deep-dive-the-importance-of-standardization)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands Used](#exploring-the-commands-used)

---

### The Task
<a name="the-task"></a>
My objective was to resolve an issue where an Apache service was down on one of the app servers and then enforce a standard configuration across all of them. The specific requirements were:
1.  Identify the faulty app server where Apache (`httpd`) was down.
2.  Fix the issue on the faulty server.
3.  Ensure the Apache service is up and running on **all three app servers**.
4.  Ensure Apache is configured to run on port `3002` on **all three app servers**.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
My approach was to first find the problem, then fix it locally, and finally roll out that fix to all other servers to create a standard, predictable environment.

#### Step 1: The Investigation - Finding the Faulty Server
I logged into each app server one by one to check the status of the `httpd` service. On `stapp01`, I immediately found the problem.
```bash
ssh tony@stapp01
sudo systemctl status httpd
```
The output showed the service was in a `failed` state. The log snippet provided the critical clue:
` (98)Address already in use`
This told me the root cause was a **port conflict**.

#### Step 2: The Diagnosis - Identifying the Culprit
To find out what port Apache was trying to use and what was blocking it, I ran two commands:
1.  **Check Apache's Config:**
    ```bash
    grep Listen /etc/httpd/conf/httpd.conf
    # Output: Listen 3002
    ```
    This confirmed Apache was correctly configured to use port `3002`.

2.  **Find the Port Squatter:**
    ```bash
    sudo netstat -tulpn | grep 3002
    # Output: tcp 0 0 127.0.0.1:3002 ... LISTEN ... /sendmail
    ```
    This was the "aha!" moment. The `sendmail` service was incorrectly using port 3002. I had found the faulty server (`stapp01`) and the exact cause of the problem.

#### Step 3: The First Fix - Resolving the Conflict
On `stapp01`, I stopped the conflicting service and started the correct one.
```bash
# Stop and disable the misconfigured sendmail service
sudo systemctl stop sendmail
sudo systemctl disable sendmail

# Start the httpd service, which can now acquire the port
sudo systemctl start httpd
```
A quick `sudo systemctl status httpd` confirmed it was now `active (running)`.

#### Step 4: The Main Fix - Standardization Across All Servers
Now that I had a working model on `stapp01`, I applied the same configuration to **all three servers** (`stapp01`, `stapp02`, `stapp03`) to ensure they were identical. For each server, I performed the following steps:

1.  **Connect to the server** (e.g., `ssh steve@stapp02`).
2.  **Ensure Correct Port Configuration:** I used `sed` to enforce the port setting, which is safe to run even if it's already correct.
    ```bash
    sudo sed -i 's/^Listen .*/Listen 3002/' /etc/httpd/conf/httpd.conf
    ```
3.  **Restart and Enable Apache:**
    ```bash
    sudo systemctl restart httpd
    sudo systemctl enable httpd
    ```
4.  **Open the Firewall Port:** This was the final, crucial step. My attempt to use `firewall-cmd` failed with "command not found," which taught me that these servers use the classic `iptables` firewall.
    ```bash
    # Add the rule to allow incoming traffic on port 3002
    sudo iptables -I INPUT 1 -p tcp --dport 3002 -j ACCEPT

    # Save the rule to make it permanent
    sudo service iptables save
    ```

#### Step 5: Final Verification
After configuring all three servers, I returned to the jump host and tested each one.
```bash
curl http://stapp01:3002
curl http://stapp02:3002
curl http://stapp03:3002
```
> I received the default Apache page HTML from all three, confirming that the issue was fully resolved and the entire environment was standardized.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>

- **Systematic Troubleshooting**: This task wasn't just about knowing commands; it was about having a logical process. By checking the `service status`, then the `logs`, then the `ports`, and finally the `firewall`, I could solve a multi-layered problem without guesswork.

- **Configuration Management (Manual)**: The core of the task was to enforce a desired state. The requirement was "all app servers must run `Apache on port 3002`." My actions—identifying the one that was broken and then applying a standard fix to all of them—is a manual form of configuration management. In the real world, this would be automated with a tool like Ansible.

- **Port Conflicts**: A very common production issue. The "Address already in use" error is a classic sign that two services are competing for the same network port, and `netstat` is the primary tool for diagnosing it.

---

### Deep Dive: The Importance of Standardization
<a name="deep-dive-the-importance-of-standardization"></a>
The most valuable lesson from this task wasn't just fixing the broken server, but the requirement to make all servers the same. This is a core principle of DevOps and Infrastructure as Code.

- **Predictability**: When all your servers are configured identically, they behave predictably. You don't have to guess why `stapp01` is behaving differently from `stapp03`.

- **Scalability**: If you need to add a fourth app server, you already have a documented, repeatable process to configure it.

- **Reduced Errors**: Inconsistent environments are a primary source of bugs ("it works on my machine!"). By standardizing, you eliminate an entire class of problems.

My process of finding the fix on one server and then applying that same "gold standard" configuration to all the others is exactly how you build a reliable and manageable infrastructure.

----

### Common Pitfalls
<a name="common-pitfalls"></a>

- **Fixing Only the Broken Server**: A common mistake would be to fix the port conflict on stapp01 and stop there. This would leave the other servers running on the wrong port, failing the overall goal of the task.

- **Forgetting the Firewall**: The most common oversight in this kind of task is forgetting that even if the service is running perfectly, it's unreachable if the server's firewall is blocking the port. You must always think about the full network path.

- **Using the Wrong Firewall Tool**: As I discovered, assuming a server uses firewalld when it actually uses iptables will cause the fix to fail. Being able to recognize this and switch tools is a key sysadmin skill.

---

### Exploring the Commands Used
<a name="exploring-the-commands-used"></a>

- `sudo systemctl status httpd`: My primary tool for checking if a service is running or why it failed.

- `grep Listen /etc/httpd/conf/httpd.conf`: A quick way to check the configured port of the Apache server.

- `sudo netstat -tulpn | grep [port]`: The essential command for finding which process is listening on a specific network port.

- `sudo sed -i 's/^Listen .*/Listen 3002/' ...`: A powerful and fast way to edit a configuration file to enforce a specific setting without opening a text editor.

- `sudo iptables -I INPUT 1 -p tcp --dport 3002 -j ACCEPT`: The command to insert a firewall rule to allow traffic on a specific port for the iptables service.

- `sudo service iptables save`: The command to make iptables rules permanent.