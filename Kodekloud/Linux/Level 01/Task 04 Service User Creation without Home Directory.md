# Linux Level 1, Task 4: Creating a User Without a Home Directory

Today's task was a quick but important lesson in creating specialized "service accounts" in Linux. The goal was to create a user account that didn't have a personal home directory, which is a common practice for users that exist only to run applications or background processes.

I learned about the `-M` flag for the `useradd` command and how to verify that the home directory was, in fact, not created.

### The Task

My objective was to create a new user on **App Server 2** with the following requirement:
-   Create a user named `anita`.
-   The user should **not** have a home directory created for them.

### My Solution

1.  **Connect to Server:** I logged into App Server 2 (`ssh steve@stapp02`).

2.  **Create the User:** I used the `useradd` command with the `-M` flag.
    ```bash
    sudo useradd -M anita
    ```

3.  **Verification:** The key to verification was to prove the directory was *not* created.
    -   First, I confirmed the user existed with `id anita`. This command succeeded.
    -   Then, I tried to list the user's would-be home directory.
        ```bash
        ls -ld /home/anita
        ```
    This command failed with No such file or directory, which was the definitive proof that my task was successful.

---



### Key Concepts (The "What & Why")
- **Service Accounts**: These are user accounts created for non-human entities, like applications or services (e.g., a web server running as the apache user). They don't need a personal workspace to store documents.

- **Why No Home Directory?** Not creating a home directory for a service account is a good practice for security and tidiness. It saves a small amount of disk space and reduces the number of places an attacker could potentially store files if the service account were ever compromised.

- **The -M flag**: This flag for the useradd command explicitly tells the system, "Make the user, but do not create a home directory."

### Commands I Used
- **`sudo useradd -M anita`**: The main command to create the user anita without a home directory.

- **`id anita`**: My first verification step to confirm the user was created.

- **`ls -ld /home/anita`**: My second verification step. The failure of this command proved the home directory did not exist.