### Understanding Overlay and Why Files “Disappear”

- We should build this from what we actually observed instead of memorizing definitions. The moment we saw that a file exists inside the container but is missing from the overlay directory on the host, it means Docker is not just storing files in one place. It is combining multiple sources into one view.

- To understand this, we should first understand what “overlay” really means in behavior.

- Instead of copying files again and again, Linux uses a smarter approach. It places one filesystem on top of another and presents them as a single view. So when we access a file, the system decides from which layer it should come.

- If the file exists in the top layer (called the upper layer, which is writable), it will be used. If not, it falls back to the lower layers (which are read-only image layers). This stacking is what we call an overlay.

<br>
<br>

**So internally, we can think like this:**

* **Lower layers** → image (base OS, installed packages)
* **Upper layer** → container changes (new files, edits)
* **Merged view** → what we actually see inside the container

<br>
<br>

Now an important behavior comes here. If the same file exists in the upper layer, it hides the one from the lower layer. If a file is deleted, it is not actually removed from the lower layer, but marked as hidden using something called a whiteout, which simply tells the system not to show it.

Now we connect this to what we saw in the GitLab container.

**Inside the container, we saw:**

```bash
/etc/gitlab/gitlab.rb
```

But when we checked the overlay path on the host, it was missing. This means the file is not coming from overlay at all.

<br>
<br>

Here comes the real concept.

- Docker does not always rely only on **`overlay`**. There is another source called a **`volume`**. A volume is simply a directory from the host that is mounted directly into the container. When this happens, it overrides everything below it.

**So the priority becomes:**

* **Volume** (highest priority)
* **Overlay** (container layer + image layers)
* **Image layers** (lowest)

This means if `/etc/gitlab` is mounted as a volume, whatever exists in that host directory will completely replace what overlay provides. That is why we could see the folder in overlay but not the actual files.

<br>
<br>

To verify this in a real system, we should not guess. We should inspect the container:

```bash
docker inspect gitlab | jq '.[0].Mounts'

# jq is a tool to parse JSON output, we are looking for the Mounts section which shows all mounted paths
# . [0] means we are looking at the first container in the output, and .Mounts gives us the list of mounts
```

<br>
<br>

**This shows all mounted paths. If we find something like:**

```json
"Destination": "/etc/gitlab",
"Source": "/srv/gitlab/config"
```

then it means `/etc/gitlab` inside the container is actually coming from `/srv/gitlab/config` on the host.

<br>
<br>

**So instead of checking overlay, we should go directly to:**

```bash
cd /srv/gitlab/config
ls
```

and we would find `gitlab.rb` there.

Now one more important correction we should make in our understanding.

<br>
<br>

**Earlier, we were checking:**

```bash
/datadisk/docker/rootfs/overlayfs/<container-id>/
```

- But this is not always the final merged filesystem. It may represent only a layer or partial structure.

<br>
<br>

**The actual place that represents what the container sees is called the merged directory. We can find it using:**

```bash
docker inspect gitlab | grep -i merged
```

This gives a path like:

```bash
.../merged
```

This merged directory is the real root filesystem of the container from the host side.

<br>
<br>

**So a proper debugging flow would be:**

* First check `MergedDir` → what container actually sees
* Then check `UpperDir` → what changes container made
* Then check `Mounts` → what volumes override everything

This way, instead of guessing, we directly trace where a file is coming from.

So the key understanding we should keep is that a container filesystem is not a single directory. It is a layered system where multiple sources are combined, and the topmost layer (especially volumes) decides what is finally visible.
