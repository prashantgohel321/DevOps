# Cloud (Azure) Day 02: Create an Azure Virtual Machine

This document outlines the solution for the second task in the Azure migration strategy: provisioning a Virtual Machine (VM). This VM will serve as a foundational compute resource for the Nautilus DevOps team in the `eastus` region.

## Table of Contents
1.  [Task Overview](#task-overview)
2.  [Prerequisites: Finding your Resource Group](#prerequisites)
3.  [Method 1: Using the Azure Portal (UI)](#method-1-portal)
4.  [Method 2: Using the Azure CLI](#method-2-cli)
5.  [Verification (SSH)](#verification)
6.  [Deep Dive: VM Storage Tiers](#deep-dive)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Provision a Linux VM based on specific hardware and security constraints.

* **VM Name:** `devops-vm`
* **Region:** `eastus`
* **Image:** `Ubuntu 24.04 LTS`
* **Size:** `Standard_B1s` (1 vCPU, 1 GiB RAM)
* **Disk:** 30 GB `Standard HDD`
* **Network:** Allow inbound SSH (Port 22) via NSG.

---

## Prerequisites: Finding your Resource Group
<a name="prerequisites"></a>

In the lab environment, you must use the existing resource group. To find its name via CLI:

```bash
az group list --output table
```
*Note the name under the **Name** column (e.g., `RG_NAME_12345`).*

---

## Method 1: Using the Azure Portal (UI)
<a name="method-1-portal"></a>

### Step 1: Create Resource
1.  Search for **Virtual Machines** in the top search bar and select it.
2.  Click **Create** -> **Azure virtual machine**.

### Step 2: Basics Tab
1.  **Project details:** Select your subscription and the **existing resource group** identified in the prerequisites.
2.  **Instance details:**
    * **Virtual machine name:** `devops-vm`.
    * **Region:** `(US) East US`.
    * **Availability options:** No infrastructure redundancy required.
    * **Image:** Select `Ubuntu Server 24.04 LTS - x64 Gen2`.
    * **Size:** Click "See all sizes" and select `Standard_B1s`.
3.  **Administrator account:**
    * **Authentication type:** SSH public key.
    * **Username:** `azureuser`.
    * **SSH public key source:** Generate new key pair (or use an existing one if you have it).
4.  **Inbound port rules:**
    * **Public inbound ports:** Allow selected ports.
    * **Select inbound ports:** `SSH (22)`.

### Step 3: Disks Tab
1.  **OS disk type:** Select **Standard HDD**.
2.  **Size:** If the default is not 30 GB, click "Change size" to set it to 30 GiB.

### Step 4: Review + create
1.  Skip the other tabs (keep defaults).
2.  Click **Review + create**.
3.  Click **Create**. If prompted, **Download private key and create resource**.

---

## Method 2: Using the Azure CLI
<a name="method-2-cli"></a>

This method is performed on the `azure-client` host.

### Step 1: Set Variables
Replace the placeholder with your actual Resource Group name.

```bash
RG="YOUR_ASSIGNED_RG_NAME"
VM_NAME="devops-vm"
LOCATION="eastus"
```

### Step 2: Create the VM
The following command handles the network, disk, size, and image requirements in one block.

```bash
az vm create \
  --resource-group $RG \
  --name $VM_NAME \
  --image Canonical:ubuntu-24_04-lts:server:latest \
  --size Standard_B1s \
  --location $LOCATION \
  --admin-username azureuser \
  --generate-ssh-keys \
  --os-disk-size-gb 30 \
  --storage-sku Standard_LRS \
  --public-ip-address-dns-name devops-vm-nautilus \
  --nsg-rule SSH
```

**Parameter Breakdown:**
* `--image`: Specifies the Ubuntu 24.04 LTS version.
* `--size`: Sets the hardware tier to `Standard_B1s`.
* `--os-disk-size-gb 30`: Forces the storage size.
* `--storage-sku Standard_LRS`: Ensures the disk is **Standard HDD**.
* `--nsg-rule SSH`: Automatically creates a security rule for port 22.

---

## Verification (SSH)
<a name="verification"></a>

Once the VM is created, obtain the Public IP:

```bash
az vm list-ip-addresses --name devops-vm --resource-group $RG --output table
```

Connect using SSH:
```bash
ssh azureuser@<PUBLIC_IP_ADDRESS>
```
*If you generated keys via the portal, ensure you use `-i path/to/key.pem`.*

---

## Deep Dive: VM Storage Tiers
<a name="deep-dive"></a>

In Azure, Managed Disks come in several performance tiers:
1.  **Premium SSD:** High-performance, low-latency. Best for production databases.
2.  **Standard SSD:** Consistent performance for web servers and light workloads.
3.  **Standard HDD (Used in this task):** Lowest cost, using magnetic drives. Best for backups or non-critical, infrequent access data.

Selecting `Standard_LRS` for the `--storage-sku` in the CLI corresponds to the **Standard HDD** requirement.
   
