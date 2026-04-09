## Simplifying SSH for Common IP Prefix

We often connect to servers inside the same network where the first part of the IP (`192.168`) stays constant. Instead of typing the full IP every time, we can redefine `ssh` in Zsh to automatically complete it.

### What we do

We override the `ssh` command so that:

* If we pass a partial IP like `110.139`, it becomes `192.168.110.139`
* If we pass a full address or hostname, it works normally

The use of `command ssh` ensures we still call the real SSH binary, avoiding recursion.

### Add to `~/.zshrc` or `.bashrc`

```bash
hey() {
  if [[ "$1" == *.* && "$1" != 192.168.* ]]; then
    command ssh 192.168.$1 "${@:2}"
  else
    command ssh "$@"
  fi
}
```

### How we use it

```bash
ssh 110.139
```

This internally runs:

```bash
ssh 192.168.110.139
```

### Apply changes

```bash
source ~/.zshrc

# OR

source ~/.bashrc
```
