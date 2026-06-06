# dotnix-bootstrap

Public entry point for setting up [dotnix](https://github.com/mehermvr/dotnix)
(my private Ubuntu + i3 + Nix/home-manager dotfiles) on a fresh machine.

`install.sh` lives here — and only here — so the private `dotnix` repo can be
bootstrapped via a public one-liner without itself being public. It installs the
apt prereqs, generates an SSH key, waits for you to add it to GitHub, then clones
the private `dotnix` repo over SSH and hands off to its `bootstrap.sh`.

## Usage (fresh Ubuntu box)

```sh
sudo apt install -y curl
bash -c "$(curl -sSfL https://raw.githubusercontent.com/mehermvr/dotnix-bootstrap/main/install.sh)"
```

Idempotent — safe to re-run.
