# **Dockerfile Deep Dive — From Writing to Internal Execution (Part 1 / 3)**

- [**Dockerfile Deep Dive — From Writing to Internal Execution (Part 1 / 3)**](#dockerfile-deep-dive--from-writing-to-internal-execution-part-1--3)
  - [**Understanding Dockerfile as a Filesystem Builder, Not Just Commands**](#understanding-dockerfile-as-a-filesystem-builder-not-just-commands)
  - [**Build Begins — Docker Starts Constructing a Filesystem**](#build-begins--docker-starts-constructing-a-filesystem)
  - [**FROM — The Starting Point of Everything**](#from--the-starting-point-of-everything)
  - [**LABEL — Adding Metadata Without Touching Filesystem**](#label--adding-metadata-without-touching-filesystem)
  - [**ARG — Variables That Exist Only During Build**](#arg--variables-that-exist-only-during-build)
  - [**ENV — Variables That Become Part of the Container**](#env--variables-that-become-part-of-the-container)
  - [**WORKDIR — Creating and Moving Into a Directory**](#workdir--creating-and-moving-into-a-directory)
  - [**RUN — Where Real Filesystem Changes Happen**](#run--where-real-filesystem-changes-happen)
  - [**COPY — Bringing Files From Host Into Image**](#copy--bringing-files-from-host-into-image)
  - [**EXPOSE — Declaring Intended Network Usage**](#expose--declaring-intended-network-usage)
  - [**CMD — Default Command When Container Starts**](#cmd--default-command-when-container-starts)
  - [**What You Have Built Till Now (Internal View)**](#what-you-have-built-till-now-internal-view)
  - [**Mental Model That Should Now Be Clear**](#mental-model-that-should-now-be-clear)


## **Understanding Dockerfile as a Filesystem Builder, Not Just Commands**

- The moment you write a Dockerfile, you are not writing a script in the traditional sense. What you are really doing is describing how a filesystem should be constructed step by step, starting from an existing base and modifying it layer by layer until it becomes your final image. This idea is the foundation of everything that follows, and once this becomes clear, Dockerfile behavior stops feeling magical and starts feeling predictable.

**Let’s start with the exact Dockerfile you worked on, because understanding comes best from something real:**

```dockerfile
FROM ubuntu:22.04

LABEL maintainer="prashant@example.com"

ARG APP_VERSION=1.0

ENV APP_HOME=/app
ENV PORT=8080

WORKDIR $APP_HOME

RUN apt update && apt install -y curl

COPY . .

EXPOSE 8080

CMD ["bash"]
```

Now instead of breaking this into isolated definitions, we will follow how Docker actually executes this from start to end, as if we are watching it internally.

---

<br>
<br>

## **Build Begins — Docker Starts Constructing a Filesystem**

**When you run:**

```bash
docker build -t myimage:v1 .
```

- Docker does not execute everything at once. It reads the Dockerfile line by line and processes each instruction sequentially, and after each step it creates a layer, which is simply a recorded change (a diff) on top of the previous filesystem.

---

<br>
<br>

## **FROM — The Starting Point of Everything**

```bash
FROM ubuntu:22.04
```

- This line defines the base filesystem. You can think of it as saying: “Start with an already prepared disk.”

- Internally, Docker first checks if this image already exists locally. If it does not, it pulls it from a registry. What gets pulled is not a single file but multiple layers, each representing a part of Ubuntu. These layers are stored inside **`containerd’s content`** store as compressed **`blobs`** and then extracted into snapshot directories.

- At this point, Docker has a complete filesystem that looks like a running Ubuntu system, but it is still just a read-only structure. This becomes your base layer, and every next instruction modifies this base.

---

<br>
<br>

## **LABEL — Adding Metadata Without Touching Filesystem**

```bash
LABEL maintainer="prashant@example.com"
```

- This step does not create files inside the container. Instead, it attaches metadata to the image configuration.

**This metadata is stored alongside the image and can later be retrieved using:**

```bash
docker inspect myimage:v1
```

- You will find labels under a section called **`“Config”`**. These are useful in real systems where automation tools, CI/CD pipelines, or even humans need to identify ownership, version, or purpose of an image without opening it.

- Even though it does not change files, Docker still records this as a layer because image configuration has changed.

---

<br>
<br>

## **ARG — Variables That Exist Only During Build**

```bash
ARG APP_VERSION=1.0
```

- This introduces a variable that exists only while the image is being built. It is not stored inside the running container.

**If later you write:**

```bash
RUN echo $APP_VERSION
```

**It will work during build. But if you run a container and check:**

```bash
docker run -it myimage:v1 env
```

- You will not see **`APP_VERSION`**.

- This is because **`ARG`** is injected into the build process, not into the final runtime environment. - It is often used to control versions, choose dependencies, or change behavior dynamically at build time.

**You can override it like this:**

```bash
docker build --build-arg APP_VERSION=2.0 .
```

- So at this moment in the build, Docker is not changing filesystem content, but it is preparing variables that later RUN commands can use.

---

<br>
<br>

## **ENV — Variables That Become Part of the Container**

```bash
ENV APP_HOME=/app
ENV PORT=8080
```

- Now this is different from **`ARG`**. These variables are stored inside the image and will exist when the container runs.

- When Docker processes this instruction, it updates the image configuration to include these environment variables. Later, when a container is started, Docker injects these variables into the container process.

**If you run:**

```bash
docker run -it myimage:v1 env
```

- You will see **`APP_HOME`** and **`PORT`**.

- These variables are commonly used by applications to configure behavior, such as which port to listen on or where files are located.

---

<br>
<br>

## **WORKDIR — Creating and Moving Into a Directory**

```bash
WORKDIR $APP_HOME
```

- At this step, Docker ensures that the directory exists inside the filesystem. If it does not exist, it creates it. Then it sets this directory as the default working location for all following instructions.

**Internally, this is equivalent to:**

```bash
mkdir -p /app
cd /app
```

- But instead of executing a shell command, Docker directly updates the filesystem snapshot and the working directory metadata.

- From now on, any RUN, COPY, or CMD instruction will assume `/app` as the current directory unless explicitly changed.

---

<br>
<br>

## **RUN — Where Real Filesystem Changes Happen**

```bash
RUN apt update && apt install -y curl
```

- This is the most important instruction because it actually modifies the filesystem in a real way.

**Here is what Docker does internally:**

1. It creates a temporary container from the previous layer.
2. Inside that container, it executes the command using a shell.
3. Whatever changes happen (new files installed, existing files modified) are tracked.
4. Docker captures these changes as a diff.
5. That diff is saved as a new layer.

- When `apt update` runs, it downloads package metadata and stores it in `/var/lib/apt/lists`. When `apt install -y curl` runs, it installs the curl binary and its dependencies into system directories like `/usr/bin`.

- All these changes become part of this layer.

- **Now an important internal behavior**: even temporary files or caches created during this step become part of the layer unless you remove them in the same command. This is why combining commands matters.

---

<br>
<br>

## **COPY — Bringing Files From Host Into Image**

```bash
COPY . .
```

- This instruction takes files from your local directory (called the build context) and copies them into the container filesystem.

- At this moment, Docker sends your entire directory (except what is ignored in `.dockerignore`) to the daemon. Then it copies those files into `/app` because that is your current **`WORKDIR`**.

- Internally, this becomes a filesystem diff layer where new files appear inside the image.

- This step is important because it also affects caching. If anything in your directory changes, this layer becomes invalid, and all layers after it must be rebuilt.

---


<br>
<br>

## **EXPOSE — Declaring Intended Network Usage**

```bash
EXPOSE 8080
```

- This does not open a port or change networking. It simply adds metadata saying that this container expects traffic on port 8080.

- This information is useful for documentation, tools, and orchestration systems, but it does not actually map ports.

**Real port mapping happens only at runtime using:**

```bash
docker run -p 8080:8080 myimage:v1
```

---

<br>
<br>

## **CMD — Default Command When Container Starts**

```bash
CMD ["bash"]
```

- This defines what should run when the container starts, unless overridden.

- Docker stores this in image configuration. When you run a container, Docker starts a process inside the container namespace using this command.

**If you override:**

```bash
docker run myimage:v1 ls
```

- Then `ls` runs instead of `bash`.

- This is why CMD is considered a default, not a fixed command.

---

<br>
<br>

## **What You Have Built Till Now (Internal View)**

**At the end of this build, Docker has created a stack of layers:**

* Base Ubuntu filesystem
* Metadata layer (LABEL, ENV, etc.)
* Filesystem change from RUN (curl installed)
* Files copied from host
* Configuration layer (CMD, EXPOSE)

All these layers are stored as compressed blobs in **`containerd`** and extracted into **`snapshots`**. When you run a container, Docker uses a storage driver like **`overlay`** to merge these layers into a single view, which becomes the container filesystem.

<br>
<br>

**`What is Overlay?`** It is a union filesystem that allows multiple layers to be stacked on top of each other. The base layer is read-only, and each new layer can add or modify files without changing the underlying layers. This is how Docker achieves both efficiency and immutability.

**`Example`**: If you have a file `/usr/bin/curl` in the base layer, and then you run `apt install curl`, the new layer will contain the modified version of `/usr/bin/curl`. When the container runs, it sees the modified version because the overlay filesystem gives priority to the topmost layer.

---

## **Mental Model That Should Now Be Clear**

- At this point, the Dockerfile should no longer feel like a list of commands. It should feel like a controlled transformation of a filesystem, where each step creates a new version of that filesystem, and Docker remembers every step as a reusable layer.

---
