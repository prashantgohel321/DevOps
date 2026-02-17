<center><h1>DevOps Day 8<br>Setting Up the Ansible Controller</h1></center>
<br>
Today, I set up my first Ansible controller, allowing me to manage servers from a central point. The task involved preparing the `jump_host` for this role. The learning experience was interesting due to the nuanced reporting of Ansible, highlighting the difference between the community package and the core engine.

## Table of Contents
- [Table of Contents](#table-of-contents)
  - [The Task](#the-task)
  - [My Step-by-Step Solution](#my-step-by-step-solution)
    - [Step 1: Install Ansible](#step-1-install-ansible)
    - [Step 2: Verification](#step-2-verification)
  - [The Verification "Gotcha": `ansible` vs. `ansible-core`](#the-verification-gotcha-ansible-vs-ansible-core)
  - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
  - [Common Pitfalls](#common-pitfalls)
  - [Exploring the Commands Used](#exploring-the-commands-used)

---

<br>
<br>

### The Task
<a name="the-task"></a>
The goal was to create an Ansible controller for `jump_host`, requiring installation of version `4.7.0`, using `pip3` exclusively, and ensuring the `ansible` command is globally available for system use.

---

<br>
<br>

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
- The entire process was performed on the `jump_host`.

#### Step 1: Install Ansible
- Using `sudo` to ensure the package was installed system-wide, not just for my user.
```bash
sudo pip3 install ansible==4.7.0
```

#### Step 2: Verification
- After the installation, I ran a series of checks to confirm everything was correct.
```bash
# First, I checked the version as my regular 'thor' user
ansible --version

# Second, I checked where the command was installed from
which ansible

# Finally, I used pip to confirm the community package version
pip3 show ansible
```

---

<br>
<br>

### The Verification "Gotcha": `ansible` vs. `ansible-core`
<a name="the-verification-gotcha-ansible-vs-ansible-core"></a>
- When I first ran `ansible --version`, I was surprised by the output:
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

---

<br>
<br>

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
-   **Ansible**: It's a leading configuration management tool used to automate application deployment, server provisioning, and general IT tasks. Its main advantages are its simplicity (using YAML for playbooks) and its "agentless" architecture, meaning it doesn't require special software to be installed on the managed servers—it just uses SSH.
-   **Ansible Controller**: The central machine that runs all automation. My `jump_host` now acts as the controller.
-   **`pip3`**: Python 3’s package installer. Installing Ansible with `pip` allows precise version control (e.g., `ansible==4.7.0`), which helps keep automation stable.
-   **Globally Available**: Installing with `sudo` puts Ansible in `/usr/local/bin/ansible`, so all users can run it. Without `sudo`, it would go to `/home/thor/.local/bin/`, limiting usage to one user.

---

<br>
<br>

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Forgetting `sudo`**: Without `sudo`, `pip3` installs Ansible only for your user, not system-wide.
-   **Wrong Version Syntax**: Using `=` or no specifier installs the latest version instead of the required `ansible==4.7.0`.
-   **Version Confusion**: Not realizing the difference between ansible and ansible-core can make you think the installation failed, even when it succeeded.

---

<br>
<br>

### Exploring the Commands Used
<a name="exploring-the-commands-used"></a>
-   `sudo pip3 install ansible==4.7.0`: Installs Ansible system-wide using `sudo`, with `pip3`, and pins it to version `4.7.0`.
-   `ansible --version`: Checks the installed Ansible version and configuration.
-   `which ansible`: Shows the full path of the Ansible executable, confirming where it’s installed.
-   `pip3 show ansible`: Displays detailed info about the installed Ansible package, confirming the exact version from the community package.