# DevOps Day 79: Automating Deployment with Jenkins, Git Triggers & SCP Deployment

This task was about building a fully automated deployment pipeline. The goal was simple:
**Any change pushed to the Git repo must automatically get deployed to the Storage Server’s `/var/www/html` directory.**

I intentionally used the simplest and most practical approach:
**sshpass + scp + Jenkins Secret Text + Poll SCM.**
No Jenkins agents, no fancy deployment plugins — just a direct, clean CD flow.

---

## The Task
1. Install and configure Apache (`httpd`) on all App Servers to run on port **8080**.
2. Create a Jenkins job that automatically deploys code changes from the `master` branch of the Git repo.
3. Ensure Jenkins can push updated content to the Storage Server.
4. Verify the deployment by modifying `index.html`, pushing to Git, and checking that Jenkins deploys it within a minute.

---

## My Updated, Actual Approach (The Real Workflow)
This section explains exactly what I did — no theoretical shortcuts.

### **1. Install Git & Credentials Plugin in Jenkins**
I installed the Git plugin and the Credentials Binding plugin.

### **2. Add Credentials for Sarah**
- Type: **Secret Text**
- ID: `sarah-pass`
- Secret: Sarah's password

This allowed Jenkins to inject the password into the build environment.

---

## Jenkins Job Setup (nautilus-app-deployment)
### **SCM Configuration**
- **Git Repo:** `http://git.stratos.xfusioncorp.com/sarah/web.git`
- **Credentials:** Sarah (username/password)
- **Branch:** `master`

### **Build Trigger**
```
* * * * *
```
This makes Jenkins poll the Git repo **every minute**.

### **Environment Injection**
Selected:
```
Use secret text(s) or file(s)
```
Added:
- Variable: `SARAH_PASS`
- Secret text: Sarah's password

### **Build Step (Execute Shell)**
I used SCP with sshpass to deploy files to the Storage Server.

```
sshpass -p "$SARAH_PASS" scp -o StrictHostKeyChecking=no -r * sarah@ststor01:/var/www/html
```

This does a brute-force but effective deployment:
- Takes the workspace files
- Copies everything to `/var/www/html` on the Storage Server

---

## Storage Server Preparation
```
sudo chown -R sarah:sarah /var/www/html
```
This prevents permission errors during deployments.

---

## Testing the Pipeline
1. SSH into Storage Server as Sarah:
   ```
   ssh sarah@ststor01
   ```
2. Navigate to cloned repo:
   ```
   cd web
   ```
3. Edit `index.html`:
   ```
   vi index.html
   ```
4. Commit & push:
   ```
   git add index.html
   git commit -m "Update welcome message"
   git push origin master
   ```
5. Wait 1 minute → Jenkins sees the change → Job triggers
6. Jenkins deploys updated files via SCP
7. Site instantly reflects new content

---

## Why This Approach Works
- **Simple:** No need for agents or plugins beyond basics
- **Direct:** SCP pushes files straight to the production directory
- **Repeatable:** Every commit = fresh deployment
- **Fast:** Zero complexity, minimal moving parts

---

## Common Pitfalls
- Wrong permissions in `/var/www/html` = deployment failure
- Forgetting to inject secret text = sshpass will fail
- Poll SCM requires correct cron format
- SCP copies the *entire workspace* — know what you're deploying

---

## Summary
You push code → Git updates → Jenkins detects change → SCP deploys files → App servers immediately serve new content from Storage Server.

This is a clean, minimal CD pipeline — reliable, transparent, and easy to debug.
