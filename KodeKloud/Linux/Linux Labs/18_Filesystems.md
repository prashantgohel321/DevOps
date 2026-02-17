# Linux Lab 18: Filesystem Management

This lab explores the core concepts of Linux filesystems. You will learn how to identify disk partitions, determine filesystem types, create new filesystems, mount them, and ensure they persist after a reboot.

## Table of Contents
- [Linux Lab 18: Filesystem Management](#linux-lab-18-filesystem-management)
  - [Table of Contents](#table-of-contents)
    - [Key Concepts](#key-concepts)
    - [Step-by-Step Walkthrough](#step-by-step-walkthrough)
      - [1. Identifying Filesystems](#1-identifying-filesystems)
      - [2. Filesystem Types \& Journaling](#2-filesystem-types--journaling)
      - [3. Checking Mounted Disks](#3-checking-mounted-disks)
      - [4. Creating a Filesystem (mkfs)](#4-creating-a-filesystem-mkfs)
      - [5. Mounting a Filesystem](#5-mounting-a-filesystem)
      - [6. Making Mounts Persistent (fstab)](#6-making-mounts-persistent-fstab)
    - [Command Reference](#command-reference)

---

### Key Concepts
<a name="key-concepts"></a>

* **Filesystem:** The method and data structure that an operating system uses to control how data is stored and retrieved (e.g., `ext4`, `xfs`, `btrfs`).
* **Journaling:** A technique used by modern filesystems (like `ext3`, `ext4`, `xfs`) to keep a log (journal) of changes not yet committed to the main file system. This prevents corruption in case of a crash. `ext2` is non-journaled.
* **Mounting:** The process of making a filesystem accessible at a certain point in the directory tree (the mount point).
* **`/etc/fstab`:** The configuration file that defines disk partitions and other filesystems and how they should be initialized or integrated into the larger filesystem structure.

---

### Step-by-Step Walkthrough
<a name="step-by-step-walkthrough"></a>

#### 1. Identifying Filesystems
<a name="1-identifying-filesystems"></a>
**Task:** Identify the filesystem type of `/dev/vdd`.
**Command:** `sudo blkid /dev/vdd`
**Output:** `/dev/vdd: UUID="..." TYPE="ext2"`
**Answer:** `ext2`

**Explanation:**
The `blkid` command locates/prints block device attributes, specifically the filesystem type (`TYPE="ext2"`).

#### 2. Filesystem Types & Journaling
<a name="2-filesystem-types--journaling"></a>
**Question:** Which filesystem does not use a journal?
**Answer:** `ext2`

**Explanation:**
* **`ext2`:** An older filesystem. It does not have a journal, meaning if the system crashes, it must scan the entire disk to ensure consistency (which is slow).
* **`ext3` & `ext4`:** These are journaled. They write metadata changes to a journal first, allowing for very fast recovery after a crash.

#### 3. Checking Mounted Disks
<a name="3-checking-mounted-disks"></a>
**Question:** Which disk (`/dev/vdd` or `/dev/vde`) has a filesystem created?
**Command:** `sudo df -h`
**Answer:** `/dev/vdd`

**Explanation:**
* `df -h` (disk free) shows mounted filesystems.
* The output shows `/dev/vdd` is mounted at `/mnt/backups`. A disk *must* have a filesystem to be mounted.
* `/dev/vde` was absent from the list, meaning it was either unmounted or raw (no filesystem).

#### 4. Creating a Filesystem (mkfs)
<a name="4-creating-a-filesystem-mkfs"></a>
**Task:** Create an `ext4` filesystem on `/dev/vdb` (or `/dev/vde` depending on the lab instance).
**Command:** `sudo mkfs.ext4 /dev/vdb`

**Explanation:**
* `mkfs` stands for **m**a**k**e **f**ile**s**ystem.
* `mkfs.ext4` is the specific command to format the partition with the `ext4` filesystem.
* **Warning:** This erases all data on that partition!

#### 5. Mounting a Filesystem
<a name="5-mounting-a-filesystem"></a>
**Task:** Mount the newly formatted disk at `/mnt/data`.
**Commands:**
1.  `sudo mkdir -p /mnt/data` (Create the directory/mount point)
2.  `sudo mount /dev/vdb /mnt/data` (Attach the device to the directory)

**Verification:**
Running `df -h` now shows `/dev/vdb` mounted at `/mnt/data`.

#### 6. Making Mounts Persistent (fstab)
<a name="6-making-mounts-persistent-fstab"></a>
**Problem:** If you reboot now, the mount at `/mnt/data` will disappear.
**Solution:** Add an entry to `/etc/fstab`.

[Image of /etc/fstab file structure explanation]

**Steps:**
1.  Open the file: `sudo vi /etc/fstab`
2.  Add the following line:
    `/dev/vdb /mnt/data ext4 defaults 0 0`
    * **Field 1:** Device (`/dev/vdb`)
    * **Field 2:** Mount Point (`/mnt/data`)
    * **Field 3:** Filesystem Type (`ext4`)
    * **Field 4:** Options (`defaults`)
    * **Field 5:** Dump (0 = don't backup)
    * **Field 6:** Pass (0 = don't check with fsck at boot)
3.  Save and exit.

**Tip:** Always run `sudo mount -a` after editing fstab to check for errors without rebooting. If there are no errors, your config is correct!

---

### Command Reference
<a name="command-reference"></a>

| Command | Purpose | Example |
| :--- | :--- | :--- |
| `df -h` | Disk Free: Shows disk usage and mount points | `df -h` |
| `blkid` | Block ID: identifying block devices and filesystems | `sudo blkid /dev/sda1` |
| `lsblk` | List Block Devices: Tree view of disks and partitions | `lsblk` |
| `mkfs.ext4` | Format a partition with ext4 filesystem | `sudo mkfs.ext4 /dev/vdb` |
| `mount` | Mount a filesystem | `sudo mount /dev/vdb /mnt/data` |
| `umount` | Unmount a filesystem | `sudo umount /mnt/data` |
| `/etc/fstab` | Configuration file for persistent mounts | (Edit with vi/nano) |

  