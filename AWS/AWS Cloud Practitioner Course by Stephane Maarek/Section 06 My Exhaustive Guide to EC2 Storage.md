# Section 6: My Exhaustive Guide to EC2 Storage

<img src="diagrams/section06.png">

This section is all about data persistence and performance. An EC2 instance is just compute power; without storage, it's useless. I explored the different ways to attach storage to my instances, each designed for specific use cases. I'm documenting this in extreme detail to solidify my understanding of these core concepts.

## Table of Contents
- [1. EBS (Elastic Block Store): My Virtual Hard Drive](#1-ebs-elastic-block-store-my-virtual-hard-drive)
- [2. Practical Steps: Creating, Attaching, and Managing EBS Volumes](#2-practical-steps-creating-attaching-and-managing-ebs-volumes)
- [3. EBS Snapshots: The Backup and Mobility Tool](#3-ebs-snapshots-the-backup-and-mobility-tool)
- [4. Practical Steps: Creating and Restoring from EBS Snapshots](#4-practical-steps-creating-and-restoring-from-ebs-snapshots)
- [5. AMI (Amazon Machine Image): My Custom Server Template](#5-ami-amazon-machine-image-my-custom-server-template)
- [6. Practical Steps: Building and Launching from a Custom AMI](#6-practical-steps-building-and-launching-from-a-custom-ami)
- [7. EC2 Image Builder: Automating AMI Creation](#7-ec2-image-builder-automating-ami-creation)
- [8. EC2 Instance Store: High-Speed Ephemeral Storage](#8-ec2-instance-store-high-speed-ephemeral-storage)
- [9. EFS (Elastic File System): The Shared Network Drive](#9-efs-elastic-file-system-the-shared-network-drive)
- [10. Amazon FSx: Specialized High-Performance File Systems](#10-amazon-fsx-specialized-high-performance-file-systems)
- [11. The Shared Responsibility Model for EC2 Storage](#11-the-shared-responsibility-model-for-ec2-storage)
- [12. Practical Steps: A Thorough Cleanup](#12-practical-steps-a-thorough-cleanup)

---

### 1. EBS (Elastic Block Store): My Virtual Hard Drive

-   **What is it?** EBS stands for Elastic Block Store. It's a network-attached storage volume that I can attach to my EC2 instances. I think of it as a "network USB stick" or a virtual hard drive. It's the most common type of storage for EC2. We've actually been using it all along without focusing on it—the 8 GiB volume created with my first instance was an EBS volume.

-   **Why use it?** Its primary purpose is **data persistence**. Data on an EBS volume survives even if the EC2 instance it's attached to is stopped or terminated. This means I can detach a volume from a failed instance and re-attach it to a new one, recovering all my data instantly.

-   **How does it work? Key Characteristics:**
    1.  **Network Attached:** The volume is not physically inside the server hosting my instance. It's connected over AWS's high-speed network. This allows for flexibility (detaching/re-attaching) but introduces a tiny amount of network latency.
    2.  **AZ-Locked:** This is a critical concept. An EBS volume exists in **one specific Availability Zone**. I cannot attach a volume created in `eu-west-1a` to an instance running in `eu-west-1b`. The instance and the volume must be in the same AZ.
    3.  **One-to-One Attachment:** For the purposes of the Cloud Practitioner exam, an EBS volume can only be attached to **one EC2 instance at a time**. (Note: Advanced volume types like `io1`/`io2` support Multi-Attach, but that's beyond the scope of this exam).
    4.  **Provisioned Capacity:** I have to decide the size (in GiB) and performance (IOPS - Input/Output Operations Per Second) of the volume in advance. I get billed for the capacity I provision, not what I use.
    5.  **Delete on Termination Attribute:** This is a per-volume setting that controls what happens when the attached EC2 instance is terminated.
        -   By default, the **root volume** (the one with the operating system) has this set to `True` and is **deleted**.
        -   By default, any **additional volumes** I attach have this set to `False` and are **preserved**.
        -   I can change this setting. A common use case is to set it to `False` for the root volume if I want to preserve it for forensic analysis or data recovery after termination.

### 2. Practical Steps: Creating, Attaching, and Managing EBS Volumes

I performed a detailed hands-on lab to master these concepts.

1.  **Identifying My Instance's AZ:** I first needed to know the AZ of my running EC2 instance. I selected my instance, went to the "Networking" tab, and found its Availability Zone: `eu-west-1b`. This is crucial for the next step.
2.  **Creating a New Volume:**
    -   I navigated to the EBS section of the EC2 console by clicking "Volumes" in the left-hand pane.
    -   I clicked "Create volume."
    -   I kept the type as `gp2` and set the size to `2` GiB.
    -   **Crucially**, for the "Availability Zone," I selected `eu-west-1b` to match my instance.
    -   I clicked "Create volume." After a few moments, its status changed from "creating" to "available."
3.  **Attaching the Volume:**
    -   The new volume was "available" but not in use. I selected it, clicked `Actions -> Attach volume`.
    -   In the dialog, I selected my running EC2 instance from the dropdown. The device name was filled in automatically.
    -   I clicked "Attach volume." The volume's state immediately changed to "in-use."
4.  **Verifying the Attachment:** I went back to my EC2 instance details and clicked the "Storage" tab. I could now see **two** block devices listed: the original 8 GiB root volume and my new 2 GiB volume.
5.  **Demonstrating the AZ Lock:** To prove the AZ-specific nature of EBS, I created another 2 GiB volume, but this time I placed it in `eu-west-1a`. When I tried to attach this new volume (`Actions -> Attach volume`), my instance in `eu-west-1b` was not listed as an option. This is a perfect demonstration of the rule: **Instance and Volume must be in the same AZ.** I then deleted this un-attachable volume.
6.  **Testing `Delete on Termination`:**
    -   I selected my instance and terminated it.
    -   I immediately went back to the "Volumes" screen and refreshed.
    -   The 8 GiB root volume (which had `Delete on Termination: Yes`) disappeared along with the instance.
    -   The 2 GiB data volume (which had `Delete on Termination: No` by default) remained, its status changing back to "available." This confirmed its data was preserved and it could now be attached to a different instance.

### 3. EBS Snapshots: The Backup and Mobility Tool

-   **What is it?** A snapshot is a point-in-time backup of an EBS volume. It captures the exact state of the volume at the moment the snapshot is initiated.
-   **Why use them?**
    1.  **Backup and Recovery:** To protect against data loss or corruption. I can restore a volume to the exact state of any of its snapshots.
    2.  **Mobility:** This is the key mechanism for moving data across AZs and regions.
-   **How does it work?** I create a snapshot from an EBS volume. This snapshot is stored independently and durably in Amazon S3 (though I don't see it in my S3 console). From this snapshot, I can then create a brand new, identical EBS volume in **any Availability Zone** within the same region, or I can copy the snapshot to another region and create a volume there.
-   **Advanced Features:**
    -   **EBS Snapshot Archive:** A cheaper storage tier for snapshots I don't need to restore quickly. It's 75% cheaper but takes 24-72 hours to retrieve a snapshot from the archive. Perfect for long-term archival.
    -   **Recycle Bin:** A safety net to protect against accidental snapshot deletion. I can set a retention rule (e.g., keep deleted snapshots for 7 days). When I delete a snapshot, it goes into the Recycle Bin for that period, during which I can recover it.

### 4. Practical Steps: Creating and Restoring from EBS Snapshots

I used the 2 GiB volume left over from the previous lab.

1.  **Create a Snapshot:** I selected the volume, then `Actions -> Create snapshot`. I gave it a description like `DemoSnapshot` and created it.
2.  **View the Snapshot:** I went to the "Snapshots" section. I saw my new snapshot with a "pending" status, which soon changed to "completed."
3.  **Restore Across AZs:** This was the magic moment.
    -   I selected my completed snapshot (which was from a volume in `eu-west-1b`).
    -   I clicked `Actions -> Create volume from snapshot`.
    -   In the creation dialog, I could now choose **any AZ**. I specifically chose `eu-west-1a`.
    -   I clicked "Create volume." I now had a perfect copy of my original volume, but in a completely different Availability Zone. This is how I overcome the AZ-locked nature of EBS volumes.
4.  **Copy to Another Region:** I also saw the option to right-click the snapshot and "Copy snapshot," which would allow me to replicate it to a different region (e.g., for disaster recovery).
5.  **Test the Recycle Bin:**
    -   I first went to the "Recycle Bin" and created a retention rule for EBS Snapshots, set to retain them for 1 day.
    -   I went back to "Snapshots," selected my snapshot, and deleted it. It disappeared from the list.
    -   I navigated back to the "Recycle Bin" and refreshed. My deleted snapshot was now listed there.
    -   I selected it and clicked "Recover." It was removed from the bin and reappeared in my main snapshot list, safe and sound.

### 5. AMI (Amazon Machine Image): My Custom Server Template

-   **What is it?** An AMI is a complete template for an EC2 instance. It includes the operating system, any software I've installed (like a web server or a database), and any configurations I've made.
-   **Why use them?** To achieve **speed and consistency**. Instead of launching a generic Linux server and running a 10-minute setup script every time, I can do the setup *once*, save it as an AMI, and then launch new, fully-configured instances from that AMI in seconds.
-   **How does the process work?**
    1.  Launch a standard EC2 instance from a public AMI (e.g., Amazon Linux 2).
    2.  Connect to it and customize it (e.g., `yum update`, `yum install httpd`).
    3.  Create an image (AMI) from this customized instance. Behind the scenes, AWS creates snapshots of the instance's EBS volumes to build the AMI.
    4.  Launch new instances from my custom AMI.

### 6. Practical Steps: Building and Launching from a Custom AMI

This lab perfectly demonstrated the power of AMIs.

1.  **Launch a "Base" Instance:** I launched a new `t2.micro` instance from the standard Amazon Linux 2 AMI.
2.  **Pre-install Software:** In the "User Data" field, I used a script to *only* install and start the Apache web server (`httpd`). I did **not** create the `index.html` file yet.
3.  **Verify Installation:** Once the instance was running, I accessed its public IP. I saw the default Apache test page, confirming the web server was installed correctly.
4.  **Create the AMI:**
    -   I selected the running instance.
    -   I right-clicked and chose `Image and templates -> Create image`.
    -   I gave the image a name, like `MyWebServerAMI`, and a description.
    -   I clicked "Create image."
5.  **Launch from the Custom AMI:**
    -   After a few minutes, my new AMI appeared in the "AMIs" section of the console with a status of "available."
    -   I started the "Launch instance" wizard again.
    -   This time, in the AMI selection screen, I clicked on the **"My AMIs"** tab on the left. My `MyWebServerAMI` was listed there. I selected it.
    -   I configured the rest of the instance as usual (t2.micro, key pair, security group).
    -   In the "User Data" for *this new instance*, I used a very short script containing only one command: the `echo "Hello World..." > /var/www/html/index.html` line. I didn't need to install anything because the web server was already part of my AMI.
6.  **The Result:** I launched this second instance. It booted up noticeably faster. As soon as it was in the "running" state, I accessed its public IP, and my "Hello World" page was displayed immediately. This proved the concept: the AMI saved me the time and effort of reinstalling software.

### 7. EC2 Image Builder: Automating AMI Creation

-   **What is it?** A service that builds a complete, automated pipeline for creating, testing, and distributing AMIs.
-   **Why use it?** While creating a manual AMI is fine for a one-time task, managing a fleet of images requires automation. I need to keep them patched with the latest security updates. Image Builder automates this entire lifecycle.
-   **How does it work?** I define a "pipeline" that consists of:
    1.  **Build:** It launches a temporary instance and runs scripts to install and configure my software (my "components").
    2.  **Test:** After the AMI is created, it launches another temporary instance from that new AMI and runs validation tests that I define to ensure it's working correctly and is secure.
    3.  **Distribute:** If the tests pass, it automatically copies the AMI to other AWS Regions I specify. This can be set to run on a schedule (e.g., weekly) to continuously produce updated, secure AMIs.

### 8. EC2 Instance Store: High-Speed Ephemeral Storage

-   **What is it?** A type of storage that is **physically attached** to the host server where my EC2 instance is running. It is **not** a network drive like EBS.
-   **Why use it?** For one reason: **extreme performance**. Because it's a local disk, it offers much higher I/O performance (IOPS) and throughput than network-attached EBS volumes. It's ideal for temporary data, caches, buffers, or any "scratch" space where I need lightning-fast access.
-   **The CRITICAL CAVEAT: It's Ephemeral.** Ephemeral means temporary. The data on an instance store is **lost forever** if the instance is **stopped** or **terminated**. It's not persistent storage. This is a vital distinction from EBS and a very common exam topic.

### 9. EFS (Elastic File System): The Shared Network Drive

-   **What is it?** EFS is a managed Network File System (NFS) that can be accessed by multiple EC2 instances at the same time.
-   **Why use it?** This solves a major challenge. If I have a fleet of web servers that all need to access the same set of files (e.g., website assets, user-uploaded content), I can mount a single EFS file system on all of them.
-   **How does it work? Key Differentiators from EBS:**
    1.  **Multi-Attach:** Can be mounted on hundreds of Linux instances simultaneously.
    2.  **Multi-AZ:** An EFS file system exists at the **regional level**. Instances from *any* AZ within that region can connect to it.
    3.  **Elastic:** It's pay-per-use. It grows and shrinks automatically as I add or remove files. I don't have to provision capacity upfront.
-   **EFS Infrequent Access (EFS-IA):** A cost-saving feature. I can set a lifecycle policy (e.g., "after 60 days of no access"). EFS will automatically move files that haven't been touched for that period to a cheaper storage class, saving me money. This is transparent to my application.

### 10. Amazon FSx: Specialized High-Performance File Systems

-   **What is it?** A family of managed services for third-party file systems.
-   **Why use it?** When I need the features of a specific file system that EFS doesn't provide.
-   **The Two Flavors to Know:**
    1.  **FSx for Windows File Server:** This is the EFS equivalent for Windows. It provides a fully managed, native Windows file system that uses the standard SMB protocol and integrates with Microsoft Active Directory. This is the go-to solution for shared storage for Windows EC2 instances.
    2.  **FSx for Lustre:** The keyword here is **High-Performance Computing (HPC)**. Lustre (Linux + Cluster) is a file system designed for massive-scale, parallel workloads like machine learning, financial modeling, and video processing. Whenever I see "HPC" in an exam question, I should think of FSx for Lustre.

### 11. The Shared Responsibility Model for EC2 Storage

-   **AWS's Responsibility:**
    -   Durability of the underlying hardware.
    -   Replicating data within their infrastructure (e.g., for EBS volume durability).
    -   Replacing faulty hardware.
    -   Ensuring their employees cannot access my data.
-   **My Responsibility:**
    -   Deciding on and implementing a backup strategy (e.g., creating EBS snapshots).
    -   Configuring data encryption.
    -   The data itself that I place on the drives.
    -   Understanding and managing the risks of ephemeral storage like Instance Store (i.e., knowing that I need to back up important data from it).

### 12. Practical Steps: A Thorough Cleanup

To avoid any costs, I performed a detailed cleanup of all the resources I created in this section.

1.  **Terminate EC2 Instances:** I went to the EC2 Instances dashboard, selected all running instances, and terminated them.
2.  **Delete EBS Volumes:** I navigated to the "Volumes" section. Any root volumes would have been deleted automatically. I manually selected any remaining data volumes and deleted them.
3.  **Deregister AMI:** An AMI is backed by a snapshot. To delete the snapshot, I first had to deregister the AMI. I went to the "AMIs" section, selected my custom AMI, and chose "Deregister AMI."
4.  **Delete Snapshots:** With the AMI gone, I could now go to the "Snapshots" section, select the snapshots created by the AMI process and any others I made, and delete them permanently.

After these steps, my EC2 console was clean, ensuring no lingering resources would incur costs.
