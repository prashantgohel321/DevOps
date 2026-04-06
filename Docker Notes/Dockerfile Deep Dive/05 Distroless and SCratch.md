# **Docker Image Internals → From Raw Tar Structure to Minimal Production Images**

<br>
<br>

## **Part 2 — Distroless & Scratch (How Real Production Images Are Built Minimal)**

Now that the internal structure of an image is clear as layers plus configuration, the next step is to question something deeper: if an image is just a stack of filesystem diffs, then what is the *minimum* set of files required to actually run an application?

This is where production-grade image design begins. Instead of asking “how do I build an image”, the question becomes “how little can I include and still run my app correctly”.

---

<br>
<br>



## **The Real Problem With Traditional Images**

Take a simple Dockerfile:

```dockerfile
FROM ubuntu

WORKDIR /app
COPY . .

RUN apt update && apt install -y nodejs npm

CMD ["node", "server.js"]
```

This works, but internally this image contains far more than your application needs.

When you start from a full base like Ubuntu, you are inheriting:

* shell binaries (`/bin/bash`)
* package manager (`apt`)
* system utilities
* many libraries not used by your app

From the layered filesystem perspective, all of this is part of your base layer. Even if your app only needs Node.js runtime, the entire OS is still included.

So the image becomes large not because of your code, but because of everything you started with.

---

<br>
<br>



## **Scratch — Starting From Absolute Nothing**

```dockerfile
FROM scratch
```

This is the most extreme form of minimalism. Scratch is not an image with fewer tools. It is literally an empty filesystem.

No:

* `/bin`
* `/lib`
* `/etc`
* no shell
* no package manager

When you use scratch, you are responsible for providing everything your application needs.

---

<br>
<br>



### **When Scratch Works**

Scratch only works when your application is fully self-contained. That means it does not depend on external system libraries.

This is possible with statically compiled binaries. A static binary includes all required libraries inside itself.

A typical example is a Go application.

```dockerfile
FROM golang:1.22 AS builder

WORKDIR /app
COPY . .

RUN go build -o app


FROM scratch

COPY --from=builder /app/app /app/app

CMD ["/app/app"]
```

Now follow what happens internally.

First stage builds the binary using a full Go environment. That stage includes compilers and tools, but it is temporary.

Second stage starts from scratch, meaning an empty filesystem. Only one file is copied into it: the compiled binary.

So the final image contains exactly one executable file.

---

<br>
<br>



### **Why This Works**

Because the binary is static, it does not need:

* shared libraries
* OS-level dependencies
* runtime environment

So when the container starts, the kernel executes that binary directly.

This results in extremely small images, often just a few megabytes.

---

<br>
<br>



### **Limitations of Scratch**

Scratch is powerful, but also restrictive.

If your application needs:

* SSL certificates (for HTTPS)
* timezone data
* dynamic libraries (like glibc)
* debugging tools

Then scratch will fail unless you manually include those files.

This is why scratch is ideal for simple, compiled services, but not for everything.

---

<br>
<br>



## **Distroless — Minimal but Practical**

Distroless images were created to solve the gap between full OS images and scratch.

Instead of including everything like Ubuntu, or nothing like scratch, distroless includes only what is required to run a specific runtime.

Example:

```dockerfile
FROM gcr.io/distroless/nodejs18
```

This image contains:

* Node.js runtime
* required system libraries
* minimal filesystem structure

But it removes:

* shell
* package manager
* unnecessary utilities

So from a layered perspective, the base layer is already stripped down to essentials.

---

<br>
<br>



### **What Makes Distroless Different Internally**

Distroless is still a layered image, just like any other.

But its layers are curated to include only runtime dependencies.

So instead of:

* base layer = full OS

You get:

* base layer = runtime-only environment

That means fewer files in lower layers, which directly reduces final image size.

---

<br>
<br>



## **Security Advantage (Direct Impact of Fewer Layers and Files)**

Because distroless removes unnecessary tools:

* there is no shell (`sh`, `bash`)
* no package manager (`apt`, `apk`)
* fewer binaries available

This reduces the attack surface.

If someone gains access to the container, they cannot easily execute arbitrary commands because the tools simply do not exist.

This is not a Docker feature, it is a result of controlling what goes into the image layers.

---

<br>
<br>



## **The Debugging Trade-off**

This minimalism introduces a practical challenge.

If a container fails and you try:

```bash
docker exec -it container sh
```

It will fail, because there is no shell.

So debugging inside the container becomes difficult.

This leads to a common production approach:

* use full images during development (for debugging)
* use distroless images in production (for security and size)

---

<br>
<br>



## **Real Production Flow (Putting Everything Together)**

A real-world Dockerfile often combines everything you have learned:

```dockerfile
FROM node:18 AS builder

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install

COPY . .
RUN npm run build


FROM gcr.io/distroless/nodejs18

WORKDIR /app
COPY --from=builder /app/dist .

CMD ["server.js"]
```

Now understand this deeply.

First stage:

* uses full Node environment
* installs dependencies
* builds application

Second stage:

* starts from minimal runtime image
* copies only compiled output

So final image contains:

* runtime (Node.js)
* compiled application

It does not contain:

* source code (unless included intentionally)
* build tools
* development dependencies

---

<br>
<br>



## **Comparing Image Types (Internal View)**

Instead of thinking in names, think in terms of filesystem content.

| Type       | What Exists in Layers |
| ---------- | --------------------- |
| Ubuntu     | Full OS filesystem    |
| Alpine     | Minimal OS + tools    |
| Slim       | Reduced OS            |
| Distroless | Only runtime          |
| Scratch    | Nothing               |

This is simply about how much content exists in the base layers.

---

<br>
<br>



## **Final Mental Model (Everything Connected)**

Now combine both parts together.

An image is:

* layers → filesystem diffs
* config → runtime instructions

When designing production images:

* reduce what goes into layers
* separate build and runtime (multi-stage)
* choose minimal base (distroless or scratch)

So the final flow becomes:

```text
Build stage → heavy tools, compile, install
↓
Final stage → minimal runtime only
↓
Layers → small, clean, secure
↓
Container runs efficiently
```

---

<br>
<br>



## **What You Have Now Achieved**

At this point, the understanding is complete from inside-out:

* how images are stored (tar layers, manifests)
* how layers merge (overlay, whiteouts)
* why size increases (layer history)
* how to reduce size (multi-stage)
* how to minimize runtime (distroless, scratch)

This is the level where Docker stops being a tool and becomes a system you can reason about and design around.
