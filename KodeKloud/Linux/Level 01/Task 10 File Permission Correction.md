# Linux Level 1, Task 10: Advanced Permissions with Access Control Lists (ACLs)

Today's task was a fantastic dive into an advanced and powerful feature of the Linux permission system: **Access Control Lists (ACLs)**. The objective was to set a complex set of permissions on a critical system file that was impossible to achieve using only the standard `chmod` command.

I learned that while standard permissions are great for simple cases (one owner, one group, everyone else), ACLs are the tool you need when you have to set specific rules for multiple, individual users or groups. This document is my detailed, first-person guide to that entire process, from setting the base permissions to applying the granular ACL rules.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: Understanding the `getfacl` Output](#deep-dive-understanding-the-getfacl-output)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands I Used](#exploring-the-commands-i-used)

---

### The Task
<a name="the-task"></a>
My objective was to configure a complex set of permissions on the `/etc/hosts` file on **App Server 3**. The specific requirements were:
1.  The file's user and group owner must be `root`.
2.  "Others" (everyone who is not the owner or in the group) must have read-only permissions.
3.  A specific user, `yousuf`, must have **no permissions** at all.
4.  Another specific user, `rod`, must have **read-only** permission.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The solution required a two-phase approach: first setting the standard permissions, then layering the specific ACL rules on top.

#### Phase 1: Setting Standard Permissions
1.  I connected to App Server 3: `ssh banner@stapp03`.
2.  I first set the ownership and the base permissions for the file. This satisfied the first two requirements.
    ```bash
    # Set both the user and group owner to 'root'
    sudo chown root:root /etc/hosts
    
    # Set permissions to 644 (read/write for owner, read for group, read for others)
    sudo chmod 644 /etc/hosts
    ```

#### Phase 2: Applying the Access Control Lists (ACLs)
This was the core of the task, where I applied the user-specific rules.
1.  I used the `setfacl` command with the `-m` (modify) flag to add the new rules.
    ```bash
    # This rule denies all permissions (---) to the user 'yousuf'
    sudo setfacl -m u:yousuf:--- /etc/hosts

    # This rule grants read permission (r--) to the user 'rod'
    sudo setfacl -m u:rod:r-- /etc/hosts
    ```

#### Phase 3: Verification
The final and most important step was to verify that all the layers of permissions were correctly applied. The `getfacl` command is the only tool that shows the complete picture.
```bash
getfacl /etc/hosts
```
The output was the definitive proof of success, as it showed both the standard permissions and my new, user-specific ACL entries.
```
# file: etc/hosts
# owner: root
# group: root
user::rw-
user:rod:r--
user:yousuf:---
group::r--
mask::r--
other::r--
```
This output perfectly matched all four of the task's requirements.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **The Limitation of Standard Permissions**: The classic Linux permission model is simple: it has three categories (owner, group, others) and three permissions (read, write, execute). This works for most cases, but it's not flexible enough for complex scenarios. In my task, both `yousuf` and `rod` would fall under the "others" category. There is no way with `chmod` alone to give "others" read permission while simultaneously denying it to a specific user like `yousuf`.
-   **Access Control Lists (ACLs)**: ACLs are the solution to this problem. They are an extension to the standard permission system that allows for much more fine-grained control. With ACLs, I can set specific permissions for **any number of additional, named users and groups**. This is what allowed me to create a special rule for `yousuf` and another special rule for `rod`.
-   **`setfacl` and `getfacl`**: These are the two primary commands for managing ACLs.
    -   `setfacl`: **Set**s **F**ile **ACL**s. I used it with the `-m` (modify) flag to add my new user-specific rules.
    -   `getfacl`: **Get**s **F**ile **ACL**s. This is the command to view all the permissions on a file, including both the standard permissions and all the specific ACL entries.

---

### Deep Dive: Understanding the `getfacl` Output
<a name="deep-dive-understanding-the-getfacl-output"></a>
The output of `getfacl` is the key to understanding how all the permissions work together.

[Image of standard permissions vs. a more detailed ACL]

Let's break down the output I received:
```
# file: etc/hosts      <-- The file being described
# owner: root           <-- The standard file owner
# group: root           <-- The standard file group
user::rw-              <-- The standard permissions for the 'owner' (root can read/write)
user:rod:r--           <-- My first ACL entry: the named user 'rod' has read permission
user:yousuf:---        <-- My second ACL entry: the named user 'yousuf' has NO permissions
group::r--             <-- The standard permissions for the 'group' (the root group can read)
mask::r--              <-- The 'mask' is an advanced feature that defines the maximum effective permissions for all ACL entries.
other::r--             <-- The standard permissions for 'others' (everyone else can read)
```
When a user tries to access the file, the system checks the rules from most specific to least specific. For example:
-   When `yousuf` tries to read the file, the system sees the specific `user:yousuf:---` rule, denies access, and stops. It never even gets to the general `other::r--` rule.
-   When `rod` tries to read the file, the system sees the specific `user:rod:r--` rule, grants access, and stops.
-   When any other random user tries to read the file, they don't match any specific user rules, so the final `other::r--` rule is applied, and they are granted access.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Trying to Solve with `chmod` Alone:** The most common mistake would be to try and solve this without ACLs, which is impossible.
-   **Incorrect `setfacl` Syntax:** The syntax is very specific. Forgetting the `u:` prefix for a user or `g:` for a group, or using the wrong permission characters, would cause the command to fail.
-   **Verifying with `ls -l`:** If you run `ls -l` on a file with ACLs, you will see a `+` sign at the end of the permission string (e.g., `-rw-r--r--+`). This `+` simply tells you that an ACL is present, but it **does not** show you the detailed rules. Only `getfacl` can give you the complete picture.
-   **Forgetting `sudo`:** Modifying the permissions on a system file like `/etc/hosts` requires root privileges.

---

### Exploring the Commands I Used
<a name="exploring-the-commands-i-used"></a>
-   `sudo chown root:root /etc/hosts`: The standard command to **ch**ange the **own**er of a file. The format is `user:group`.
-   `sudo chmod 644 /etc/hosts`: The standard command to **ch**ange the permission **mod**e of a file using octal notation (`6` = `rw-`, `4` = `r--`).
-   `sudo setfacl -m u:yousuf:--- /etc/hosts`: The main command for this task.
    -   `setfacl`: The command to set file ACLs.
    -   `-m`: The flag to **m**odify the existing ACL.
    -   `u:yousuf:---`: The ACL entry itself, defining the permissions (`---`) for a specific **u**ser (`yousuf`).
-   `getfacl /etc/hosts`: The primary verification command. It displays all standard permissions and extended ACLs for a file.
   