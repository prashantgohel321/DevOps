### Seeing Container Files Clearly (Without Confusion)

We should simplify everything and connect it directly to what we saw on the system, instead of trying to understand all terms at once.

**First, we should accept one simple rule:**

**A container shows files from only two places:**

* the image (default files that come with the container)
* mounts (host folders attached inside the container)

Now we look at the real output we already have.

```bash
docker inspect gitlab | jq '.[0].Mounts'
```

**This showed:**

* `/etc/gitlab` → `/datadisk/home/gitlabuser/docker-setup/gitlab/data/config`

<br>
<br>

**This means when we go inside the container and access:**

```bash
/etc/gitlab/gitlab.rb
```

**we are actually reading a file from the host:**

```bash
/datadisk/home/gitlabuser/docker-setup/gitlab/data/config/gitlab.rb
```

So instead of thinking there are two different files, we should understand it is the same file, just viewed from two sides.

<br>
<br>

Now we should verify it practically.

**On the host:**

```bash
cd /datadisk/home/gitlabuser/docker-setup/gitlab/data/config
ls
```

- We would see `gitlab.rb` there.

- This directly explains why we could not find it inside the overlay directory. Because overlay is not used at all for this path.

**When Docker sees a mount like this:**

```bash
host folder → /etc/gitlab (inside container)
```

it completely replaces that directory inside the container. So whatever overlay or image had in `/etc/gitlab` becomes irrelevant.

**So for `/etc/gitlab`, the priority becomes:**

```bash
host mount → used
overlay → ignored
image → ignored
```

<br>
<br>

Now we bring overlay back, but in a simpler way.

**Overlay is only used when there is no mount. It combines two things:**

* **image** (read-only base files like `/bin`, `/etc/os-release`)
* **container changes** (new files or modifications we make after the container starts)

**For example, if we run a normal container:**

```bash
docker run -it ubuntu bash
```

**and inside we check:**

```bash
ls /
```

files like `/bin`, `/etc`, `/usr` come from the image.

**If we create a file:**

```bash
touch /tmp/testfile
```

this does not go into the image. It goes into a separate writable layer created for that container.

Overlay is simply the mechanism that combines these two and shows them as one filesystem.

<br>
<br>

**Now we map everything to simple meaning:**

* **image** → original files (like Ubuntu or GitLab base)
* **container layer** → changes we make after container starts
* **overlay** → combines image + container changes
* **mount** → external host folder that overrides everything

Now we revisit the confusion.

**We checked:**

```bash
/datadisk/docker/rootfs/overlayfs/<id>/etc/gitlab
```

- and expected to find `gitlab.rb`.

- But this directory belongs to overlay (image + container layer), while our `/etc/gitlab` is coming from a mount. So overlay never had that file at all.

- So the correct way to debug becomes very clear.

**Whenever a file is missing, we should ask:**

* is it coming from image?
* is it created inside container?
* or is it coming from a mount?

In this case, `/etc/gitlab` is coming from a mount, so we should completely ignore overlay for that path.

<br>
<br>

Now we can verify behavior with a small test.

**Inside the container:**

```bash
echo "test123" >> /etc/gitlab/gitlab.rb
```

**Then on the host:**

```bash
cat /datadisk/home/gitlabuser/docker-setup/gitlab/data/config/gitlab.rb
```

- We would see the change immediately, because both are pointing to the same file.

- This is the exact moment where the filesystem understanding becomes practical instead of theoretical.
