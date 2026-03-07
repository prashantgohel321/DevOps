# Cloud (Azure) Day 01: Create SSH Key Pair for Azure Virtual Machine

This document outlines the solution for the first task in the Azure migration strategy: creating an **SSH Key Pair**. This is the fundamental security credential required to log into Linux Virtual Machines (VMs) without a password.

We will cover two methods:
1.  **Azure Portal (Web UI)** - Best for visual verification.
2.  **Azure CLI** - Best for automation and speed.

---

## Task Requirements
* **Resource:** SSH Key
* **Name:** `devops-kp`
* **Key Type:** `RSA`
* **Environment:** Azure Cloud

---

## Glossary of Terms

* **SSH Key Pair:** A set of security credentials (Public and Private keys). The public key is stored in Azure, and the private key is downloaded and kept by the user.
* **RSA:** A widely used public-key cryptosystem for secure data transmission.
* **Resource Group:** A logical container for Azure resources. Everything you create in Azure must belong to a resource group.

---

## Method 1: Using the Azure Portal (UI)

### Step 1: Login
1.  Open the **Portal URL** provided in your credentials.
2.  Login with the **Username** and **Password** provided.

### Step 2: Navigate to SSH Keys
1.  In the search bar at the top, type `SSH keys`.
2.  Select **SSH keys** from the services list.

### Step 3: Create Key Pair
1.  Click the **+ Create** button (top left).
2.  **Project details:**
    * **Subscription:** Select the default subscription provided.
    * **Resource group:** Click "Create new" or select an existing one.
3.  **Instance details:**
    * **Region:** Select any available region (e.g., `East US`).
    * **Name:** Enter `devops-kp`.
    * **SSH public key source:** Select **Generate new key pair**.
4.  Click **Review + create**.
5.  Once validation passes, click **Create**.

### Step 4: Download the Private Key
1.  A popup window titled **Generate new key pair** will appear.
2.  Click **Download private key and create resource**.
3.  Save the `devops-kp.pem` file securely. **Warning:** You cannot download this file again once the window is closed.

---

## Method 2: Using the Azure CLI

This method can be performed on the `azure-client` host.

### Step 1: Login to Azure
```bash
az login
```
*Follow the device login prompts to authenticate.*

### Step 2: Identify your assigned Resource Group
In many lab environments, you are restricted to a specific pre-created Resource Group. Using the wrong name will result in an `AuthorizationFailed` error.

```bash
# List available resource groups to find your assigned name
az group list --output table
```
*Copy the name found under the **Name** column (e.g., `RG_NAME_12345`).*

### Step 3: Create the Key Pair
Set the variable with the name you found in Step 2 and run the creation command.

```bash
# Replace the value below with the actual group name from the previous step
RG_NAME="YOUR_ASSIGNED_RG_NAME"

# Create the SSH Key resource
az sshkey create \
    --name "devops-kp" \
    --resource-group $RG_NAME \
    --location "eastus"
```

### Step 4: Verification
To list your keys and ensure `devops-kp` exists:

```bash
az sshkey list --resource-group $RG_NAME --output table
```

---

## Troubleshooting

### Issue: (AuthorizationFailed) Microsoft.Compute/sshPublicKeys/write
If you encounter this error, it means the client does not have permission to write to the specified Resource Group or the scope is invalid.

* **Cause:** You likely used a placeholder Resource Group name (like `nautilus_migration_rg`) that does not exist in your lab subscription or that you don't have permissions for.
* **Fix:** Run `az group list --output table` to identify the exact Resource Group name assigned to your user account and use that name in your command.

---

## Securing Your Private Key

Whether you used the Portal or the CLI, if you have a `.pem` file locally, you must restrict its permissions before it can be used for SSH.

**For Linux/Mac:**
```bash
chmod 400 devops-kp.pem
```

**Why?**
SSH clients will reject a private key file that is "too open" (readable by other users on your computer). `chmod 400` ensures only you have read access.
   
