# Linux Level 1, Task 1: Creating a Custom User

Today's task was a dive into one of the most fundamental skills of any Linux system administrator: user management. The objective wasn't just to create a user, but to create a **service account** with specific, non-default attributes. This is a crucial practice for enhancing security and setting up applications correctly.

I learned how to use the `useradd` command with specific flags to control the user's UID and home directory. This document is my detailed, first-person guide to that process, explaining not just *what* I did, but *why* it's important.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: The `/etc/passwd` File](#deep-dive-the-etcr-passwd-file)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands I Used](#exploring-the-commands-i-used)

---

### The Task
<a name="the-task"></a>
My objective was to create a custom user account on **App Server 3**. The specific requirements were:
1.  The username must be `mark`.
2.  The user's UID must be set to exactly `1082`.
3.  The user's home directory must be `/var/www/mark`.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The process was very efficient and performed entirely on the command line of App Server 3.

#### Step 1: Connect to the Server
First, I needed to log into the correct server as a user with administrative privileges.
```bash
ssh banner@stapp03
```

#### Step 2: Create the Custom User
This was the core of the task. I used a single `useradd` command with flags to specify all the required attributes.
```bash
sudo useradd -u 1082 -d /var/www/mark mark
```

#### Step 3: Verification
The final and most important step was to confirm that the user was created with the correct settings. I used two separate commands for this.
1.  **Verify the UID:** I used the `id` command to check the user's identity information.
    ```bash
    id mark
    # Output: uid=1082(mark) gid=1082(mark) groups=1082(mark)
    ```
    This output immediately confirmed the UID was set correctly to `1082`.

2.  **Verify the Home Directory:** I checked the system's user database file, `/etc/passwd`, to confirm the home directory.
    ```bash
    grep mark /etc/passwd
    # Output: mark:x:1082:1082::/var/www/mark:/bin/bash
    ```
    This output showed me the username, UID, group ID, and, crucially, the correct home directory path `/var/www/mark`. This was the definitive proof of success.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
-   **User Accounts**: In Linux, every file and process is owned by a user. Creating separate user accounts is the foundation of security and permission management.
-   **Service Accounts**: Instead of running a web server like Apache as the powerful `root` user, it's a critical security practice to run it as a dedicated, unprivileged user. My `mark` user is an example of such a "service account." If the web server were ever compromised, the attacker would only have the permissions of the `mark` user, not `root`, which dramatically limits the potential damage. This is the **Principle of Least Privilege**.
-   **UID (User Identifier)**: While humans use usernames, the Linux kernel identifies users by a number called the UID. By default, `useradd` assigns the next available UID. Using the `-u` flag to assign a *specific* UID is important for maintaining consistency across a fleet of servers. For example, if I have three app servers, ensuring the `mark` user has UID `1082` on all of them is crucial for shared network storage (NFS), where permissions are based on UIDs, not usernames.
-   **Custom Home Directory**: A normal user's home is in `/home/username`. For a service account that runs a website, it's a common and logical practice to set its home directory to be where the website's files will live, such as `/var/www/mark`. This keeps all of the application's related files organized in one place.

---

### Deep Dive: The `/etc/passwd` File
<a name="deep-dive-the-etc-passwd-file"></a>
My verification step involved looking at the `/etc/passwd` file. This is a plain text file that acts as the primary database of user information on a Linux system. Each line represents one user and contains seven colon-separated fields.

Let's break down the entry I created: `mark:x:1082:1082::/var/www/mark:/bin/bash`

1.  **`mark`**: The **username**.
2.  **`x`**: The **password** field. The `x` is a placeholder. For security, the actual encrypted password hash is stored in a separate, more secure file: `/etc/shadow`.
3.  **`1082`**: The **User ID (UID)**. This is the unique number that the kernel uses to identify the `mark` user.
4.  **`1082`**: The **Group ID (GID)**. This is the ID of the user's primary group. By default, `useradd` creates a new group with the same name and ID as the user.
5.  **`(empty)`**: The **GECOS field**. This is an optional comment field, often used for the user's full name.
6.  **`/var/www/mark`**: The user's **home directory**. This is the directory the user is placed in when they log in.
7.  **`/bin/bash`**: The user's default **login shell**. This is the command interpreter that is launched when the user opens a terminal.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **UID Already in Use:** If I had tried to create the user with a UID that was already taken by another user, the `useradd` command would have failed with an error.
-   **Permissions:** Forgetting to use `sudo` would result in a "Permission denied" error, as only the `root` user can create new users.
-   **Forgetting to Create the Home Directory:** The `useradd` command with the `-d` flag *defines* the home directory path, but it doesn't always create it. The `-m` (move/make) flag is often needed to ensure the home directory is also created (`useradd -m -d ...`). For this task, it wasn't required, but it's a good practice to know.

---

### Exploring the Commands I Used
<a name="exploring-the-commands-i-used"></a>
-   `sudo useradd -u 1082 -d /var/www/mark mark`: The main command for this task.
    -   `useradd`: The command to add a new user.
    -   `-u 1082`: Sets the **u**ser ID (UID) to `1082`.
    -   `-d /var/www/mark`: Sets the home **d**irectory to `/var/www/mark`.
    -   `mark`: The name of the user to be created.
-   `id mark`: A command to display user and group identity information. I used it to quickly verify the UID and GID.
-   `grep mark /etc/passwd`: A standard command to search for lines containing "mark" within the `/etc/passwd` file. I used it to view the user's entry and verify their home directory and other attributes.
-   `sudo groupmod -g 1567 ammar`: A related command to **mod**ify a **g**roup. The `-g` flag changes the Group ID (GID) of the `ammar` group to `1567`. This is useful for correcting a group's ID to match other systems.
-   `usermod -u 1567 ammar`: A related command to **mod**ify an existing **user**. The `-u` flag changes the **u**ser ID (UID) of the user `ammar` to a new value, `1567`.
-   `usermod -aG <group1>,<group2> <username>`: To add a user to additional groups (secondary groups), use `usermod` with the `-aG` options. The `-a` flag appends the user to the group, and `-G` specifies the group(s).
-   `usermod -g <new_primary_group> <username>`: To change a user's primary group, use `usermod` with the `-g` option.
  