### Understanding Where Docker Actually Stores Everything

- We should always begin from the real situation, not from definitions. Whenever something breaks in Docker, we are usually trying to answer simple but critical questions like where our container data is actually stored, why the disk is getting full, why a file is not visible inside the container, or what Docker has really created on the host system.

- Instead of thinking about containers as something abstract, we should look directly at the host machine, because Docker is not magic. It is simply managing directories and processes on our system.

<br>
<br>

**So we would go to the main Docker storage location:**

```bash
/var/lib/docker
```

<br>
<br>

**This is the central place where Docker keeps everything. When we check it:**

```bash
sudo ls /var/lib/docker
```

**we would see folders like:**

* `overlay2`
* `containers`
* `images`
* `volumes`
* `network`

<br>
<br>

Each of these represents a specific responsibility.

- The `overlay2` directory is the most important one. It contains the actual container filesystem. In simple terms, this is where the real files of the container live, but managed in layers using a Linux feature called **`OverlayFS`**, which allows combining multiple directories into one unified view.

- The `containers` directory stores metadata (information about containers like config) and logs. So if we want to debug logs without using Docker commands, we could even look here directly.

- The `images` directory holds image layers. These are read-only building blocks. When we pull an image like nginx, Docker stores its layers here.

- The `volumes` directory is used for persistent data. This is where our database data or any long-term storage should live, because containers themselves are temporary.

- The `network` directory contains Docker’s networking configuration.

<br>
<br>

To build a strong understanding, we should always verify things practically.

**We could run a container:**

```bash
docker run -d --name test-nginx nginx
```

<br>
<br>

**Now we would inspect where its filesystem actually exists on the host:**

```bash
docker inspect test-nginx | grep -i merged
```

<br>
<br>

**This gives a path like:**

```bash
/var/lib/docker/overlay2/.../merged
```

- This `merged` directory is very important. It represents the final filesystem that the container sees. Whatever we see inside the container (like `/bin`, `/etc`, `/usr`) is actually coming from this merged directory.

<br>
<br>

**Now the key mental model we should build is this:**

A running container is not a full copy of an image. Instead, it is a combination of layers.

* **Image layers** → read-only (base structure like OS files)
* **Container layer** → writable (where changes happen)

These are merged together into one view using the `overlay2` storage driver, which is Docker’s way of efficiently combining multiple layers into a single usable filesystem.

So when we access a container, we are actually interacting with this merged filesystem, not with a single physical directory.
