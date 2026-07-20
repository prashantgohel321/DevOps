# Linux Certification Test: Solution Guide

This document provides step-by-step solutions for the 10 tasks in the Linux Certification test. All tasks are performed within the Stratos Datacenter environment.

---

## 1. Create Non-Interactive User
**Task:** Create user `eric` with a non-interactive shell on App Server 3.
**Command:**
```bash
ssh banner@stapp03
sudo useradd -s /sbin/nologin eric
```
*Verification:* `grep eric /etc/passwd` (Should show `/sbin/nologin`).

---

## 2. User Expiry and File Management
**Task:** Set `mariyam` expiry to `2027-02-17` and copy her files from `/home/usersdata` to `/blog`.
**Commands:**
```bash
ssh banner@stapp03
# 1. Set expiration
sudo chage -E 2027-02-17 mariyam

# 2. Copy files and maintain ownership
sudo mkdir -p /blog
sudo find /home/usersdata -type f -user mariyam -exec cp -p {} /blog/ \;
```
*Verification:* `chage -l mariyam` and `ls -l /blog`.

---

## 3. Restrict Crontab Access
**Task:** Allow `top`, deny `kodekloud_roy` on App Server 3.
**Commands:**
```bash
ssh banner@stapp03
# Deny user
echo "kodekloud_roy" | sudo tee -a /etc/cron.deny
# Allow user
echo "top" | sudo tee -a /etc/cron.allow
```

---

## 4. Create Directory Structure
**Task:** Create `/opt/app/backup/latest` on App Server 3.
**Command:**
```bash
ssh banner@stapp03
sudo mkdir -p /opt/app/backup/latest
```

---

## 5. Permissions Management
**Task:** Change `/usr/share/data` permissions to `700` on App Server 3.
**Command:**
```bash
ssh banner@stapp03
sudo chmod 700 /usr/share/data
```

---

## 6. Archiving and Compression
**Task:** Create `logs.tar` and `logs.tar.gz` of `/var/log` in `natasha`'s home on Storage Server.
**Commands:**
```bash
ssh natasha@ststor01
# Create uncompressed tar
tar -cvf ~/logs.tar /var/log/
# Create compressed tar.gz
tar -zcvf ~/logs.tar.gz /var/log/
```

---

## 7. Text Processing with SED
**Task:** Edit `/home/BSD.txt` on App Server 3. Delete "copyright" lines and replace "or" with "is".
**Commands:**
```bash
ssh banner@stapp03
# a. Delete lines containing 'copyright'
sed '/copyright/d' /home/BSD.txt > /home/BSD_DELETE.txt

# b. Replace whole word 'or' with 'is'
sed 's/\bor\b/is/g' /home/BSD.txt > /home/BSD_REPLACE.txt
```

---

## 8. Set Process Limits
**Task:** Limit `nfsuser` processes on Storage Server (Soft: 1024, Hard: 2024).
**Command:**
```bash
ssh natasha@ststor01
sudo vi /etc/security/limits.conf

# Add these lines at the bottom:
nfsuser soft nproc 1024
nfsuser hard nproc 2024
```

---

## 9. SELinux Installation and Configuration
**Task:** Install SELinux on App Server 3 and disable permanently.
**Commands:**
```bash
ssh banner@stapp03
# Install packages
sudo yum install selinux-policy-targeted selinux-utils -y

# Disable permanently
sudo vi /etc/selinux/config
# Change line: SELINUX=enforcing -> SELINUX=disabled
```

---

## 10. Install and Enable Bind
**Task:** Install `bind` on all app servers, start and enable service.
**Command (Run on each: stapp01, stapp02, stapp03):**
```bash
sudo yum install bind -y
sudo systemctl start named
sudo systemctl enable named
```
*Note: The service name for the bind package is `named`.*
   
