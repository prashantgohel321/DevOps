# Linux Level 1, Task 5: Managing Temporary User Accounts

Today's task was a practical exercise in a very important security principle: managing temporary access. My goal was to create a user account for a developer that would automatically expire on a specific date. This is a common requirement for contractors, auditors, or any user who only needs access for a limited time.

I learned how to use the `useradd` command with the `--expiredate` flag and, just as importantly, how to use the `chage` command to verify that the expiration date was set correctly.

### The Task

My objective was to create a temporary user account on **App Server 1**. The specific requirements were:
-   Create a user named `rose`.
-   Set the account's expiration date to `2024-04-15`.

### My Solution

1.  **Connect to Server:** I logged into App Server 1 (`ssh tony@stapp01`).

2.  **Create the User with Expiry:** I used a single `useradd` command with the `--expiredate` flag.
    ```bash
    sudo useradd rose --expiredate 2024-04-15
    ```

3.  **Verification:** This was the crucial step. I used the `chage -l` command to list the account aging information for the new user.
    ```bash
    sudo chage -l rose
    ```
    The output clearly showed the expiration date I had set, confirming my success.
    ```
    Account expires                                         : Apr 15, 2024
    ```

### Key Concepts (The "What & Why")

-   **Temporary Access Management:** It's a significant security risk to have old, unused accounts sitting on a server. Creating accounts with an automatic expiration date is the best practice for any non-permanent user. It automates the process of revoking access and reduces the chance of human error.
-   **The `--expiredate` flag:** This flag for the `useradd` command sets a specific date on which the user account will be disabled. The user will no longer be able to log in after this date. It's important to note that this **disables** the account; it does not delete the user or their files.
-   **The `chage` command:** The `chage` (change age) utility is the primary tool for managing password and account expiration policies for users. The `-l` (list) flag is perfect for viewing the current settings for a user, which is how I verified my work.

### Commands I Used

-   `sudo useradd rose --expiredate 2024-04-15`: The main command to create the user `rose` and set their account expiration date.
-   `sudo chage -l rose`: My verification command. It **l**ists the account aging details for the user `rose`, allowing me to confirm the `Account expires` date was set correctly.
   