#!/usr/bin/env bash
#
# install.sh — one-shot curl-pipe entry for a fresh Ubuntu 26.04 box.
# Designed to be run as:
#
#   bash -c "$(curl -sSfL https://raw.githubusercontent.com/mehermvr/dotnix-bootstrap/main/install.sh)"
#
# Idempotent: re-running on a partially-set-up box just no-ops past what's
# already done.
#
# Steps (everything before bootstrap.sh can take over):
#   1. apt prereqs (curl, git, xsel, openssh-client, xdg-utils, ca-certs)
#   2. ssh-keygen if absent
#   3. copy pubkey to clipboard, open github.com/settings/keys, wait for paste
#   4. probe ssh -T git@github.com until authenticated
#   5. clone dotnix to ~/dotnix (or git pull)
#   6. exec ~/dotnix/bootstrap.sh
#
set -euo pipefail

log()  { printf '\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

[ "$(id -u)" -ne 0 ] || { echo "Run as your normal user, not root."; exit 1; }
have apt-get || { echo "This script targets Ubuntu/Debian (apt not found)."; exit 1; }

DOTNIX_DIR="$HOME/dotnix"
DOTNIX_REPO="git@github.com:mehermvr/dotnix.git"

# ---------------------------------------------------------------------------
# 1. apt prereqs — bare minimum to clone the repo and prompt for SSH setup
# ---------------------------------------------------------------------------
log "Installing apt prereqs…"
sudo apt-get update -y
sudo apt-get install -y \
  curl git ca-certificates \
  openssh-client xsel xdg-utils

# ---------------------------------------------------------------------------
# 2. SSH key
# ---------------------------------------------------------------------------
SSH_KEY="$HOME/.ssh/id_ed25519"
if [ ! -f "$SSH_KEY" ]; then
  log "Generating SSH key ($SSH_KEY)…"
  read -r -p "Email to embed in the key (e.g. for GitHub): " EMAIL </dev/tty
  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
  ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -C "$EMAIL"
fi

# ---------------------------------------------------------------------------
# 3. Paste pubkey to GitHub
# ---------------------------------------------------------------------------
PUBKEY="$(cat "${SSH_KEY}.pub")"
# Copy to clipboard (best effort — DISPLAY may not be set in headless contexts).
if [ -n "${DISPLAY:-}" ] && have xsel; then
  printf '%s' "$PUBKEY" | xsel -b || true
fi
echo
echo "==== Public key (also on clipboard if X is available) ===="
echo "$PUBKEY"
echo "=========================================================="

# Probe SSH first — if the key is already on GitHub, skip the paste prompt.
ssh_authed() {
  ssh -T -o StrictHostKeyChecking=accept-new -o BatchMode=yes \
      -o ConnectTimeout=5 git@github.com 2>&1 \
    | grep -q "successfully authenticated"
}

if ssh_authed; then
  log "SSH key already authorized on GitHub — skipping paste step."
else
  if [ -n "${DISPLAY:-}" ] && have xdg-open; then
    xdg-open https://github.com/settings/keys >/dev/null 2>&1 || true
  fi
  echo
  echo "Add the key above to GitHub: https://github.com/settings/keys"
  read -r -p "Press Enter once the key has been added… " _ </dev/tty
  # Retry loop in case the user added the key but it hasn't propagated yet,
  # or in case they want to re-attempt after a wrong paste.
  attempts=0
  until ssh_authed; do
    attempts=$((attempts + 1))
    if [ "$attempts" -ge 5 ]; then
      echo "Still not authenticated after $attempts attempts. Aborting."
      exit 1
    fi
    warn "Still not authenticated. Did you add the right key? Retrying after Enter…"
    read -r -p "" _ </dev/tty
  done
fi
log "GitHub SSH OK."

# ---------------------------------------------------------------------------
# 4. Clone (or pull) dotnix to ~/dotnix
# ---------------------------------------------------------------------------
if [ ! -d "$DOTNIX_DIR" ]; then
  log "Cloning dotnix → $DOTNIX_DIR"
  git clone "$DOTNIX_REPO" "$DOTNIX_DIR"
else
  log "dotnix already at $DOTNIX_DIR — pulling latest."
  (cd "$DOTNIX_DIR" && git pull --ff-only) || warn "git pull failed; using local copy."
fi

# ---------------------------------------------------------------------------
# 5. Hand off to bootstrap.sh
# ---------------------------------------------------------------------------
log "Handing off to bootstrap.sh…"
exec "$DOTNIX_DIR/bootstrap.sh"
