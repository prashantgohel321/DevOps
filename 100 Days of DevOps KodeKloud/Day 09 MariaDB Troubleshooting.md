<center><h1>DevOps Day 09<br>Real-World Production Troubleshooting</h1></center>
<br>

Today’s task felt like a real production support scenario. A critical application was down because the database service failed. My role wasn’t to create something new, but to investigate, diagnose, and fix the issue.

It was a great exercise in methodical troubleshooting. I followed clues from general errors to detailed logs, tested different hypotheses, and finally found the root cause — which was deeper than it first appeared.

## Table of Contents
- [Table of Contents](#table-of-contents)
  - [The Task](#the-task)
  - [My Troubleshooting Journey: A Step-by-Step Solution](#my-troubleshooting-journey-a-step-by-step-solution)
    - [Step 1: Initial Investigation](#step-1-initial-investigation)
    - [Step 2: Digging into the Logs](#step-2-digging-into-the-logs)
    - [Step 3: Testing Hypotheses](#step-3-testing-hypotheses)
    - [Step 4: Discovering the True Root Cause](#step-4-discovering-the-true-root-cause)
    - [Step 5: The Final Solution](#step-5-the-final-solution)
  - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
  - [Deep Dive: The Hierarchy of Troubleshooting](#deep-dive-the-hierarchy-of-troubleshooting)
  - [Common Pitfalls](#common-pitfalls)
  - [Exploring the Commands Used](#exploring-the-commands-used)

---

<br>
<br>

### The Task
<a name="the-task"></a>
- The Nautilus application was down. The production support team had identified that the `mariadb` service was not running on the database server (`stdb01`). My task was to investigate the issue and bring the database service back online.

---

<br>
<br>

### My Troubleshooting Journey: A Step-by-Step Solution
<a name="my-troubleshooting-journey-a-step-by-step-solution"></a>
- My path to resolving this outage involved a multi-step investigation.

#### Step 1: Initial Investigation
- First, I logged into the database server (`peter@stdb01`) and confirmed the problem using `systemctl`.
```bash
sudo systemctl status mariadb
# Output confirmed the service was "inactive (dead)"
```
- My first attempt to fix it with a simple `start` command failed, which told me the problem was not a simple crash.
```bash
sudo systemctl start mariadb
# Output: Job for mariadb.service failed... See "journalctl -xeu mariadb.service" for details.
```

#### Step 2: Digging into the Logs
- Following the error message's advice, I checked the detailed logs.
```bash
journalctl -xeu mariadb.service
```
The logs were filled with "Operation not permitted" and "Failed to mount" errors. These were `systemd` errors, not MariaDB errors, pointing to a problem with the underlying server environment, likely file permissions or a missing resource.

#### Step 3: Testing Hypotheses
* **Hypothesis 1: Disk Space.** My first thought was that the disk was full, as a database will refuse to start without space to write.
    ```bash
    df -h
    ```
    This showed plenty of free space. **Hypothesis was incorrect.**

* **Hypothesis 2: Incorrect Directory Ownership.** My next thought was that the data directory (`/var/lib/mysql`) was owned by the wrong user (e.g., `root` instead of `mysql`).
    ```bash
    ls -ld /var/lib/mysql
    ```

#### Step 4: Discovering the True Root Cause
- The previous command resulted in the ultimate clue:
`ls: cannot access '/var/lib/mysql': No such file or directory`

- The problem wasn't wrong permissions; the entire data directory was **missing**.

#### Step 5: The Final Solution
- With the root cause identified, I executed the full recovery procedure.
1.  **Create the missing directory:**
    ```bash
    sudo mkdir /var/lib/mysql
    ```
2.  **Set the correct ownership** so the `mysql` user could access it:
    ```bash
    sudo chown mysql:mysql /var/lib/mysql
    ```
3.  **Initialize the database structure** by running the installation script. This creates the necessary system tables in the new directory.
    ```bash
    sudo mysql_install_db --user=mysql
    ```
4.  **Start the service.** With all prerequisites in place, the service could finally start.
    ```bash
    sudo systemctl start mariadb
    ```
5.  **Enable the service** to ensure it starts after a reboot.
    ```bash
    sudo systemctl enable mariadb
    ```
6.  **Final Verification.**
    ```bash
    sudo systemctl status mariadb
    # Output now showed "active (running)"
    ```

---

<br>
<br>

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
-   **`systemd` and `systemctl`**: `systemd` is the main service manager in modern Linux. `systemctl` is the tool to start, stop, enable, or check services — a core sysadmin skill.
-   **`journalctl`**: Lets you view detailed system logs. When `systemctl status` isn’t enough, `journalctl` helps find exact error messages.
-   **Root Cause Analysis**: This task taught me to go beyond fixing symptoms. The service was down, but the real problem was a missing directory. Restarting alone wouldn’t have solved it.

---

<br>
<br>

### Deep Dive: The Hierarchy of Troubleshooting
<a name="deep-dive-the-hierarchy-of-troubleshooting"></a>
My process followed a logical hierarchy, moving from general to specific.
1.  **Confirm the problem:** Is the service *really* down? (`systemctl status`)
2.  **Attempt a simple fix:** Will a simple restart work? (`systemctl start`)
3.  **Gather more data:** The simple fix failed, so why? (`journalctl`)
4.  **Form a hypothesis:** Based on the logs (permission errors), I suspected an environmental issue. My first guess was disk space.
5.  **Test the hypothesis:** Was the disk full? (`df -h`) No.
6.  **Refine the hypothesis:** If not disk space, what else could cause permission errors? Incorrect file ownership.
7.  **Test the refined hypothesis:** Who owns the data directory? (`ls -ld`)
8.  **Discover the root cause:** The directory doesn't even exist.
9.  **Implement the full solution:** Rebuild the environment (`mkdir`, `chown`, `mysql_install_db`) and then start the service.

This methodical process is key to solving complex issues efficiently.

---

<br>
<br>

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Not Reading Error Messages:** The `start` command failed but explicitly said to run `journalctl`. Ignoring this advice would leave you guessing.
-   **Stopping at the First Clue:** The `journalctl` logs mentioned "permission denied," which could lead one to only check `chown`. But the *real* problem was a level deeper: the directory itself was gone.

---

<br>
<br>

### Exploring the Commands Used
<a name="exploring-the-commands-used"></a>
-   `sudo systemctl status mariadb`: Checks the current status of the service.
-   `sudo systemctl start mariadb`: Attempts to start the service.
-   `sudo systemctl enable mariadb`: Configures the service to start on boot.
-   `journalctl -xeu mariadb.service`: Displays detailed, service-specific logs to find the root cause of a failure.
-   `df -h`: Checks disk space usage in a human-readable format.
-   `ls -ld [directory]`: Lists the details of a directory itself, including its owner.
-   `sudo mkdir [directory]`: Creates a new directory.
-   `sudo chown -R mysql:mysql [directory]`: Changes the owner and group of a directory recursively.
-   `sudo mysql_install_db --user=mysql`: A specific command for MariaDB/MySQL that creates the initial database schema in an empty data directory.
