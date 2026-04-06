# **Docker Image Internals → From Raw Tar Structure to Minimal Production Images**

<br>
<br>

- [**Docker Image Internals → From Raw Tar Structure to Minimal Production Images**](#docker-image-internals--from-raw-tar-structure-to-minimal-production-images)
  - [**Part 1 — What an Image Actually Is (When Docker Is Removed Completely)**](#part-1--what-an-image-actually-is-when-docker-is-removed-completely)
    - [**Manifest — The Map That Tells How to Build the Image**](#manifest--the-map-that-tells-how-to-build-the-image)
    - [**Layers — Not Filesystems, but Differences Between Filesystems**](#layers--not-filesystems-but-differences-between-filesystems)
    - [**How These Layers Become a Real Filesystem (Overlay Concept)**](#how-these-layers-become-a-real-filesystem-overlay-concept)
    - [**Whiteout Files — How Deletion Actually Works**](#whiteout-files--how-deletion-actually-works)
    - [**Config File — The Runtime Brain of the Image**](#config-file--the-runtime-brain-of-the-image)
    - [**Connecting This to containerd (What You Explored Earlier)**](#connecting-this-to-containerd-what-you-explored-earlier)
    - [**Final Realization (This Changes Everything)**](#final-realization-this-changes-everything)


<br>
<br>

## **Part 1 — What an Image Actually Is (When Docker Is Removed Completely)**

- To understand images at the deepest level, the first step is to stop thinking in terms of Docker commands and instead look at what physically exists on disk. When an image is exported and opened, it stops being an abstract concept and becomes a set of real files that describe a filesystem and how to build it step by step.

- Start by exporting any image and unpacking it. This process reveals the raw structure that Docker normally hides.

```bash
docker save ubuntu:22.04 > ubuntu.tar

mkdir ubuntu-image
cd ubuntu-image
tar -xvf ../ubuntu.tar
```

- Once extracted, the structure you see is not random. It is the exact definition of an image in its raw form. Files like `manifest.json`, a configuration JSON, and multiple layer tar files together define everything needed to reconstruct the image. 

- At this point, the important shift happens. An image is not a single filesystem. It is a collection of pieces that must be applied in a specific order.

---

<br>
<br>

### **Manifest — The Map That Tells How to Build the Image**

Inside `manifest.json`, you will see something like:

```json
[
  {
    "Config": "abcd1234.json",
    "RepoTags": ["ubuntu:22.04"],
    "Layers": [
      "layer1.tar",
      "layer2.tar",
      "layer3.tar"
    ]
  }
]
```

**This file is not data, it is instructions. It tells:**

* which configuration file defines runtime behavior
* which layers exist
* in what order those layers must be applied

That order is critical because each layer depends on the previous one. If the order changes, the filesystem changes.

So internally, Docker is not “loading an image”, it is reconstructing a filesystem by applying layers sequentially from bottom to top. 

---

<br>
<br>

### **Layers — Not Filesystems, but Differences Between Filesystems**

- Each `layer.tar` is often misunderstood as a mini filesystem, but that is not accurate. A layer is not a complete system, it is only a set of changes relative to the previous state.

**If you extract a layer:**

```bash
mkdir layer1
tar -xvf layer1.tar -C layer1

# -C means extract into this directory
```

You may see directories like:

```text
bin/
etc/
usr/
```

But this does not mean it is a full OS. It only contains files that were added or modified in that step.

For example:

* base layer → contains initial Ubuntu filesystem
* next layer → contains only new packages installed
* next layer → contains only modified or added files

So a layer is essentially a diff, a record of “what changed” at that step. 

---

<br>
<br>

### **How These Layers Become a Real Filesystem (Overlay Concept)**

- When a container runs, these layers are not merged physically into one directory. Instead, a union filesystem (like overlayfs) stacks them logically.

The idea is:

```bash
Layer 1 (base)
+ Layer 2 (changes)
+ Layer 3 (changes)
---------------------
Final merged filesystem
```

- If a file exists in multiple layers, the top-most version is visible. Lower versions are hidden but still exist in their respective layers.

- This explains why containers appear to have a normal filesystem even though it is actually built dynamically from multiple layers. 

---

<br>
<br>

### **Whiteout Files — How Deletion Actually Works**

- Deletion inside layered systems cannot remove files from previous layers because those layers are immutable. Instead, deletion is represented using special markers.

**Inside some layers, you may see files like:**

```text
.wh.filename
```

- This is called a whiteout file.

- It means: “this file existed in a lower layer, but should not appear in the final filesystem.”

So if:

* Layer 1 → has `/file.txt`
* Layer 2 → deletes `/file.txt`

Layer 2 will contain `.wh.file.txt`

- The overlay system interprets this as a deletion instruction and hides the file during merge, even though it still physically exists in Layer 1. 

- This directly explains why deleting files in later Dockerfile steps does not reduce image size.

---

<br>
<br>

### **Config File — The Runtime Brain of the Image**

- Apart from layers, there is a config JSON file referenced in the manifest.

**When opened, it contains:**

* environment variables (ENV)
* default command (CMD)
* entrypoint
* working directory

This file does not affect filesystem content. Instead, it defines how the container should behave when it runs.

So an image is actually two things combined:

* filesystem (layers)
* runtime behavior (config) 

---

<br>
<br>

### **Connecting This to containerd (What You Explored Earlier)**

Now everything aligns with what you previously explored in containerd directories.

* layer.tar → stored as compressed blobs in content store
* extracted layers → stored as snapshots
* manifest → stored as image metadata
* config.json → used when container starts

So when you run:

```bash
docker pull ubuntu
```

**Internally:**

* layers are downloaded as blobs
* stored by hash (content-addressed storage)
* extracted into snapshot directories
* overlay merges them
* container runtime uses config to start process

This is the full internal pipeline. 

---

<br>
<br>

### **Final Realization (This Changes Everything)**

**At the raw level, an image is:**

* not a virtual machine
* not a full filesystem snapshot

**It is:**

* a sequence of filesystem diffs
* plus a configuration that tells how to run it

Once this is understood, everything in Docker—layers, caching, size issues, multi-stage builds—becomes logically consistent.

---
