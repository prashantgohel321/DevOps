# DevOps Day 8: Setting Up the Ansible Controller

Today marked a significant milestone: I set up my first Ansible controller. Ansible is the tool that will allow me to stop logging into servers one-by-one and start managing them all from a single, central point. This task was all about preparing the `jump_host` to take on this new role.

The most interesting part of this task was a nuance in how Ansible reports its version, which was a great learning experience. It highlighted the difference between the high-level community package and the core engine that powers it.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [The Verification "Gotcha": `ansible` vs. `ansible-core`](#the-verification-gotcha-ansible-vs-ansible-core)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands Used](#exploring-the-commands-used)

---

### The Task
<a name="the-task"></a>
My objective was to prepare the `jump_host` to act as an Ansible controller. The specific requirements were:
1.  Install Ansible version `4.7.0`.
2.  The installation must be done using `pip3` only.
3.  The `ansible` command must be "globally available," meaning any user on the system can run it.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The entire process was performed on the `jump_host`.

#### Step 1: Install Ansible
To meet all the requirements in one go, I used a single command. The key was using `sudo` to ensure the package was installed system-wide, not just for my user.
```bash
sudo pip3 install ansible==4.7.0
```

#### Step 2: Verification
After the installation, I ran a series of checks to confirm everything was correct.
```bash
# First, I checked the version as my regular 'thor' user
ansible --version

# Second, I checked where the command was installed from
which ansible

# Finally, I used pip to confirm the community package version
pip3 show ansible
```
The results of these checks are detailed in the next section, as they were a learning experience in themselves.

---

### The Verification "Gotcha": `ansible` vs. `ansible-core`
<a name="the-verification-gotcha-ansible-vs-ansible-core"></a>
This was the most valuable part of the task. When I first ran `ansible --version`, I was surprised by the output:
```
ansible [core 2.11.12] 
...
executable location = /usr/local/bin/ansible
...
```
I was looking for `4.7.0` but saw `core 2.11.12`. I learned that this is the expected behavior.

-   **`ansible` (The Community Package):** The version I installed, `4.7.0`, refers to a large bundle of modules, plugins, and documentation. It's the whole product.
-   **`ansible-core` (The Engine):** The version shown in the output, `2.11.12`, refers to the core engine that runs the playbooks. The `ansible 4.7.0` package contains `ansible-core 2.11.12`.

My verification was actually a success:
1.  The `executable location` of `/usr/local/bin/ansible` proved it was a **global** installation.
2.  Running `pip3 show ansible` confirmed the community package version:
    ```
    Name: ansible
    Version: 4.7.0
    ...
    ```
This cleared up all confusion and proved the task was done correctly.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
-   **Ansible**: It's a leading configuration management tool used to automate application deployment, server provisioning, and general IT tasks. Its main advantages are its simplicity (using YAML for playbooks) and its "agentless" architecture, meaning it doesn't require special software to be installed on the managed servers—it just uses SSH.
-   **Ansible Controller**: This is the central machine where Ansible is installed and from which all automation is run. My `jump_host` now serves this purpose.
-   **`pip3`**: This is the package installer for the Python 3 programming language. Using `pip` is often preferred for installing Python tools like Ansible because it gives precise version control (e.g., `ansible==4.7.0`), which is vital for maintaining a stable automation platform.
-   **Globally Available**: This means the command's location (`/usr/local/bin/ansible`) is in the system's `PATH` environment variable for all users. If I had installed it without `sudo`, it would have been placed in `/home/thor/.local/bin/`, and only the `thor` user could have run it easily. Using `sudo` ensured a system-wide installation.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Forgetting `sudo`**: Without `sudo`, `pip3` would perform a user-specific install, failing the "globally available" requirement.
-   **Wrong Version Syntax**: Forgetting the `==` for version pinning (e.g., using a single `=` or no specifier at all) would result in installing the latest version, not the specific version `4.7.0` required by the task.
-   **Version Confusion**: As I experienced, not understanding the `ansible` vs. `ansible-core` versioning can lead you to believe the installation failed when it was actually successful.

---

### Exploring the Commands Used
<a name="exploring-the-commands-used"></a>
-   `sudo pip3 install ansible==4.7.0`: The core command. It uses `sudo` for system-wide installation, `pip3` as the installer, and `ansible==4.7.0` to specify the exact package and version.
-   `ansible --version`: The standard command to check the installed version of the `ansible-core` engine and its configuration.
-   `which ansible`: A useful Linux command that shows the full path of an executable, proving where it was installed.
-   `pip3 show ansible`: Asks the `pip` package manager to show all the details for a specific installed package, which is the best way to confirm the community package version.

