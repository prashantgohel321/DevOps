# Linux Lab 15: Cronjobs - Automating Tasks

This lab focuses on `cron`, the time-based job scheduler in Unix-like operating systems. You will learn how to list scheduled jobs for different users, understand the cron syntax for scheduling, and create new cron jobs to automate script execution.

[Image of crontab syntax breakdown]

## Table of Contents
- [Linux Lab 15: Cronjobs - Automating Tasks](#linux-lab-15-cronjobs---automating-tasks)
  - [Table of Contents](#table-of-contents)
    - [Key Concepts](#key-concepts)
    - [Step-by-Step Walkthrough](#step-by-step-walkthrough)
      - [1. Listing User Cronjobs](#1-listing-user-cronjobs)
      - [2. Counting Scheduled Tasks](#2-counting-scheduled-tasks)
      - [3. Listing Root Cronjobs](#3-listing-root-cronjobs)
      - [4. Interpreting Cron Schedules](#4-interpreting-cron-schedules)
      - [5. Creating a Monthly Job](#5-creating-a-monthly-job)
      - [6. Analyzing Complex Schedules](#6-analyzing-complex-schedules)
      - [7. Creating a Step-Based Schedule](#7-creating-a-step-based-schedule)
    - [Command Reference](#command-reference)

---

### Key Concepts
<a name="key-concepts"></a>

* **Cron:** A daemon (background service) that executes scheduled commands.
* **Crontab (Cron Table):** A file that contains a list of commands meant to be run at specified times. Each user has their own crontab.
* **Cron Syntax:** A specific format with 5 fields to define the time and date:
    ```
    .---------------- minute (0 - 59)
    |  .------------- hour (0 - 23)
    |  |  .---------- day of month (1 - 31)
    |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
    |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue ...
    |  |  |  |  |
    * * * * * command_to_execute
    ```
* **Operators:**
    * `*`: Any value (every minute, every hour, etc.)
    * `,`: List of values (e.g., `1,15` for 1st and 15th)
    * `-`: Range of values (e.g., `1-5` for 1 through 5)
    * `/`: Step values (e.g., `*/10` for every 10 units)

---

### Step-by-Step Walkthrough
<a name="step-by-step-walkthrough"></a>

#### 1. Listing User Cronjobs
<a name="1-listing-user-cronjobs"></a>
**Question:** Which command is used to list all the cronjobs created for a user?
**Answer:** `crontab -l`

**Explanation:**
* `crontab`: The command to maintain crontab files.
* `-l`: The flag to **l**ist the current crontab.

#### 2. Counting Scheduled Tasks
<a name="2-counting-scheduled-tasks"></a>
**Task:** Count the cronjobs scheduled for user `bob`.
**Command:** `crontab -l`
**Output:**
```
11 11 * * 3 /usr/local/bin/system-reporter.sh
23 11 * * 2 /usr/local/bin/system-checker.sh
23 23 * * 2 /usr/local/bin/system-debugger.sh
11 23 * * * /usr/local/bin/system-tester.sh
11 23 * 2 * /usr/local/bin/system-troubleshooter.sh
11 23 * * 2 /usr/local/bin/system-identifier.sh
```
**Answer:** 6 lines = 6 jobs.

#### 3. Listing Root Cronjobs
<a name="3-listing-root-cronjobs"></a>
**Task:** List cronjobs for the `root` user.
**Command:** `sudo crontab -l`
**Answer:** 1 job (`0 21 * * * date >> /tmp/date.txt`)

**Explanation:**
* `sudo` runs the command as root.
* `crontab -l` then lists the crontab for the *current effective user* (which is now root).
* Alternatively, you could use `sudo crontab -u root -l`.

#### 4. Interpreting Cron Schedules
<a name="4-interpreting-cron-schedules"></a>
**Question:** Which command runs at 11 minutes past 11 PM every Tuesday?
**Analysis:**
* **Minute:** 11
* **Hour:** 11 PM = 23 (24-hour format)
* **Day of Week:** Tuesday = 2
* **Pattern:** `11 23 * * 2`

**Looking at Bob's crontab:**
`11 23 * * 2 /usr/local/bin/system-identifier.sh` matches perfectly.

**Answer:** `/usr/local/bin/system-identifier.sh`

#### 5. Creating a Monthly Job
<a name="5-creating-a-monthly-job"></a>
**Task:** Schedule `/usr/local/bin/last-reboot.sh` to run on the 1st of every month at 6 AM.
**Schedule Breakdown:**
* **Minute:** 0 (at the top of the hour)
* **Hour:** 6 (6 AM)
* **Day of Month:** 1 (1st day)
* **Month:** * (Every month)
* **Day of Week:** * (Any day)

**Command:**
```bash
crontab -e
```
Add the line:
`0 6 1 * * /usr/local/bin/last-reboot.sh`

#### 6. Analyzing Complex Schedules
<a name="6-analyzing-complex-schedules"></a>
**Question:** When will `/usr/local/bin/system-troubleshooter.sh` run?
**Entry:** `11 23 * 2 *`
**Breakdown:**
* `11`: Minute 11
* `23`: Hour 23 (11 PM)
* `*`: Any day of the month
* `2`: Month 2 (February)
* `*`: Any day of the week

**Answer:** 11 minutes past 11 PM on all days in the month of February.

#### 7. Creating a Step-Based Schedule
<a name="7-creating-a-step-based-schedule"></a>
**Task:** Schedule `/usr/local/bin/system-debugger.sh` to run every half hour (minute 0 and 30).
**Schedule Breakdown:**
* **Minute:** `*/30` (Every 30 minutes starting from 0: 0, 30) OR `0,30`
* **Hour:** `*` (Every hour)
* **Day/Month/Week:** `*` (Every day)

**Command:**
```bash
crontab -e
```
Add the line:
`*/30 * * * * /usr/local/bin/system-debugger.sh`

---

### Command Reference
<a name="command-reference"></a>

| Command | Purpose | Example |
| :--- | :--- | :--- |
| `crontab -l` | **List** the current user's cronjobs | `crontab -l` |
| `crontab -e` | **Edit** the current user's cronjobs | `crontab -e` |
| `crontab -r` | **Remove** the current user's crontab | `crontab -r` |
| `sudo crontab -u [user] -l` | List another user's cronjobs (requires root) | `sudo crontab -u bob -l` |
| `sudo crontab -u [user] -e` | Edit another user's cronjobs (requires root) | `sudo crontab -u bob -e` |

   