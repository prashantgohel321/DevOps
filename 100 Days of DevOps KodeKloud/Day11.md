# DevOps Day 11: Deploying a Java Application on Tomcat

Today's task was a deep dive into the world of Java application deployment. I was responsible for the entire end-to-end process: setting up the application server (Apache Tomcat), configuring it to meet specific requirements, and deploying a pre-packaged web application. This was a fantastic real-world scenario that involved working across multiple servers and handling configuration files.

I learned that a successful deployment is a multi-phase operation. I had to first prepare the destination server, then establish a secure connection for transferring the application, and finally, perform the deployment itself.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
    - [Phase 1: Installing and Configuring Tomcat on App Server 3](#phase-1-installing-and-configuring-tomcat-on-app-server-3)
    - [Phase 2: Preparing for Secure File Transfer](#phase-2-preparing-for-secure-file-transfer)
    - [Phase 3: Deploying the Web Application](#phase-3-deploying-the-web-application)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: The Magic of `ROOT.war`](#deep-dive-the-magic-of-rootwar)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands Used](#exploring-the-commands-used)

---

### The Task
<a name="the-task"></a>
My objective was to deploy a Java web application on **App Server 3**. The process involved several specific requirements:
1.  **Install** the Apache Tomcat application server.
2.  **Configure** Tomcat to run on port `8084` instead of its default `8080`.
3.  **Copy** a pre-built application file, `ROOT.war`, from the `/tmp` directory on the **Jump host**.
4.  **Deploy** this `.war` file to the Tomcat server.
5.  **Verify** that the application was accessible directly at the base URL (e.g., `http://stapp03:8084`).

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
I broke my solution into three logical phases to ensure a smooth and error-free deployment.

#### Phase 1: Installing and Configuring Tomcat on App Server 3
<a name="phase-1-installing-and-configuring-tomcat-on-app-server-3"></a>
First, I prepared the destination server.

1.  **Connect and Install:** I logged into App Server 3 (`banner@stapp03`) and used `yum` to install the Tomcat package.
    ```bash
    sudo yum install -y tomcat
    ```

2.  **Configure the Port:** This was a critical configuration change. I edited Tomcat's main configuration file, `server.xml`, with `vi`.
    ```bash
    sudo vi /etc/tomcat/server.xml
    ```
    Inside the file, I searched for the `Connector` tag and changed its port attribute from `8080` to `8084`.

3.  **Start and Enable the Service:** Finally, I started the Tomcat service and enabled it to ensure it would restart automatically after a reboot.
    ```bash
    sudo systemctl start tomcat
    sudo systemctl enable tomcat
    ```

#### Phase 2: Preparing for Secure File Transfer
<a name="phase-2-preparing-for-secure-file-transfer"></a>
The application file was on a different server (the Jump host). To automate the copy, I needed to set up password-less SSH from the Jump host to App Server 3.

1.  **Connect to Jump Host:** I logged into the Jump host (`thor@jump_host`).

2.  **Set up SSH Keys:** I generated an SSH key pair (if one didn't exist) and then used `ssh-copy-id` to send my public key to the `banner` user on App Server 3.
    ```bash
    ssh-keygen -t rsa
    ssh-copy-id banner@stapp03 
    ```
    I entered `banner`'s password one last time to authorize the key transfer.

#### Phase 3: Deploying the Web Application
<a name="phase-3-deploying-the-web-application"></a>
With all the prerequisites in place, I was ready for the final deployment.

1.  **Copy the `.war` File:** From the **Jump host**, I used `scp` to securely copy the application file to App Server 3. It transferred instantly without a password.
    ```bash
    scp /tmp/ROOT.war banner@stapp03:
    ```

2.  **Move to Tomcat's `webapps` Directory:** I switched back to my App Server 3 terminal. The `ROOT.war` file was now in my home directory. I used `sudo` to move it into Tomcat's special auto-deployment directory.
    ```bash
    sudo mv ROOT.war /usr/share/tomcat/webapps/
    ```
    Tomcat automatically detects new files in this directory and deploys them.

3.  **Verification:** I waited about 15 seconds for Tomcat to unpack and start the application. Then, I used `curl` to test the endpoint.
    ```bash
    curl http://stapp03:8084
    ```
    I was greeted with the HTML of the deployed application, which was the final proof of a successful deployment.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
-   **Apache Tomcat:** This is one of the most popular application servers in the Java ecosystem. It provides a runtime environment that manages Java Servlet and JavaServer Pages (JSP) technologies, which are the foundation of many Java web applications.
-   **`.war` (Web Application Archive) File:** This is the standard for distributing and deploying Java web applications. It's a single file that bundles all the application's components (Java classes, libraries, static files like HTML/CSS, etc.) into a predictable structure that any compliant application server, like Tomcat, can understand and run.
-   **Port Configuration (`server.xml`):** Editing the server's configuration is a fundamental sysadmin skill. The `server.xml` file is the heart of Tomcat's configuration, and changing the `Connector` port is necessary to avoid conflicts with other services and adhere to project requirements.

---

### Deep Dive: The Magic of `ROOT.war`
<a name="deep-dive-the-magic-of-rootwar"></a>
A key part of this task was understanding the special meaning of the filename `ROOT.war`.

Normally, if you deploy a file named `my-app.war`, Tomcat will make it available at the URL path `/my-app`. For example: `http://stapp03:8084/my-app`.

However, the filename `ROOT.war` (all caps) is a special convention. It tells Tomcat to deploy this application at the **root context**. This means the application becomes the default one for the server, and you can access it directly from the base URL: `http://stapp03:8084/`. This is perfect for when a server is dedicated to hosting a single, primary application.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Firewall Issues:** If I had been unable to `curl` the application, the next step would have been to check the firewall on App Server 3 (`sudo firewall-cmd --list-all`) to ensure that traffic on the custom port `8084` was being allowed.
-   **Forgetting to Start Tomcat:** A simple but common mistake is to configure the server but forget to `start` and `enable` the service, leading to "Connection refused" errors.
-   **Incorrect Permissions on `webapps`:** If I had tried to `scp` the file directly into `/usr/share/tomcat/webapps`, it would have failed with a permission error. The two-stage copy (copy to home directory, then `sudo mv`) is the correct pattern to handle this.
-   **Not Waiting for Deployment:** Tomcat needs a few seconds to unpack the `.war` file and start the application. Trying to `curl` the URL immediately after moving the file might result in a 404 error or connection refused, leading to false-negative troubleshooting.

---

### Exploring the Commands Used
<a name="exploring-the-commands-used"></a>
-   `sudo yum install -y tomcat`: Installs the Tomcat application server and its dependencies.
-   `sudo vi /etc/tomcat/server.xml`: Edits the main Tomcat configuration file.
-   `sudo systemctl start tomcat`: Starts the Tomcat service.
-   `sudo systemctl enable tomcat`: Ensures the Tomcat service starts on server boot.
-   `ssh-copy-id user@host`: Sets up password-less SSH for automated file transfers.
-   `scp [source] [destination]`: Securely copies the `.war` file from the jump host to the app server.
-   `sudo mv [source] [destination]`: Moves the `.war` file into Tomcat's auto-deployment directory.
-   `curl [URL]`: A command-line tool to make web requests, used here to verify that the application was running and accessible.
 