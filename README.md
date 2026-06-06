# dotnix-bootstrap

Public entry script for my private [dotnix](https://github.com/mehermvr/dotnix)
dotfiles — keeps dotnix private while still allowing a one-liner bootstrap.

```sh
bash -c "$(curl -sSfL https://raw.githubusercontent.com/mehermvr/dotnix-bootstrap/main/install.sh)"
```

Fallback if `main` is stale (GitHub's raw CDN caches it ~5 min after a push) —
pinned to the latest `install.sh` commit, kept current by CI:

```sh
bash -c "$(curl -sSfL https://raw.githubusercontent.com/mehermvr/dotnix-bootstrap/49856ac0f31b73b51a0990a65d80e8e4994836a3/install.sh)"
```
