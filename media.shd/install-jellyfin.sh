#!/usr/bin/env bash
set -euo pipefail

# Detect codename (Debian/Ubuntu)
if command -v lsb_release >/dev/null 2>&1; then
  CODENAME="$(lsb_release -cs)"
else
  # fallback
  . /etc/os-release
  CODENAME="${VERSION_CODENAME:-bookworm}"
fi

# Prepare keyring path
sudo install -m 0755 -d /etc/apt/keyrings
KEYRING="/etc/apt/keyrings/jellyfin.gpg"

# Import repo key (modern signed-by)
if [[ ! -s "$KEYRING" ]]; then
  curl -fsSL https://repo.jellyfin.org/jellyfin_team.gpg.key | sudo gpg --dearmor -o "$KEYRING"
  sudo chmod 0644 "$KEYRING"
fi

# Add repo (idempotent)
LIST=/etc/apt/sources.list.d/jellyfin.list
LINE="deb [arch=$(dpkg --print-architecture) signed-by=$KEYRING] https://repo.jellyfin.org/debian $CODENAME main"
if [[ ! -f "$LIST" ]] || ! grep -qF "$LINE" "$LIST"; then
  echo "$LINE" | sudo tee "$LIST" >/dev/null
fi

# Remove old package if present (cleanly)
if dpkg -s jellyfin >/dev/null 2>&1; then
  sudo systemctl stop jellyfin || true
  sudo apt-get -y purge jellyfin || true
  sudo apt-get -y autoremove --purge || true
fi

# Install
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install jellyfin

# Enable HW accel (Intel VAAPI)
if getent group video >/dev/null; then
  sudo usermod -aG video jellyfin || true
fi
if getent group render >/dev/null; then
  sudo usermod -aG render jellyfin || true
fi

# Optional: systemd nice/ionice throttling (create override if not exists)
OVR=/etc/systemd/system/plexmediaserver.service.d/override.conf # typo-proofing: we'll actually set jellyfin below
OVR_J=/etc/systemd/system/jellyfin.service.d/override.conf
if [[ ! -f "$OVR_J" ]]; then
  sudo install -d -m 0755 "$(dirname "$OVR_J")"
  sudo tee "$OVR_J" >/dev/null <<'EOF'
[Service]
Nice=10
IOSchedulingClass=best-effort
IOSchedulingPriority=7
CPUWeight=50
IOWeight=50
EOF
fi

# Start/enable
sudo systemctl daemon-reload
sudo systemctl enable --now jellyfin
sudo systemctl restart jellyfin

# Quick status
systemctl --no-pager --full status jellyfin || true

echo "Jellyfin installed. Web UI: http://$(hostname -f 2>/dev/null || hostname):8096"
