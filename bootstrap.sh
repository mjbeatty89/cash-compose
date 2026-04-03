#!/bin/bash
# cash-containers one-time bootstrap
# Run this directly in a terminal on cash (needs sudo password)
# Usage: bash bootstrap.sh

set -e
REPO="https://github.com/mjbeatty89/cash-compose"
REPO_DIR="$HOME/projects/cash-compose"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   cash-containers bootstrap              ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ── 1. Fix seatd (dual-monitor DRM boot bug) ─────────────────────────────
echo "▶ Enabling seatd..."
sudo systemctl enable --now seatd
sudo usermod -aG seat "$USER"
echo "  ✓ seatd enabled, $USER added to seat group"

# ── 2. Enable Docker Engine ───────────────────────────────────────────────
echo "▶ Enabling Docker..."
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
echo "  ✓ docker enabled, $USER added to docker group"

# ── 3. Fix VirtualBox kernel modules ─────────────────────────────────────
echo "▶ Fixing VirtualBox modules..."
sudo pacman -S --noconfirm virtualbox-host-modules-arch && echo "  ✓ vbox modules rebuilt" || echo "  ⚠ vbox fix failed (non-critical)"

# ── 4. BTRFS scrub ───────────────────────────────────────────────────────
echo "▶ Starting BTRFS scrub (background)..."
sudo btrfs scrub start / && echo "  ✓ scrub started (check with: sudo btrfs scrub status /)"

# ── 5. sudoers: allow systemctl for specific services without password ────
echo "▶ Configuring passwordless sudo for service management..."
echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl reload caddy, /usr/bin/systemctl reload docker, /usr/bin/docker, /usr/bin/btrfs scrub status *" \
  | sudo tee /etc/sudoers.d/cash-gitops > /dev/null
echo "  ✓ NOPASSWD configured for gitops operations"

# ── 6. Clone cash-compose repo ───────────────────────────────────────────
echo "▶ Cloning cash-compose repo..."
mkdir -p "$HOME/projects"
if [ -d "$REPO_DIR" ]; then
  echo "  repo already exists, pulling..."
  cd "$REPO_DIR" && git pull
else
  git clone "$REPO" "$REPO_DIR"
fi
chmod +x "$REPO_DIR/deploy.sh"
echo "  ✓ repo at $REPO_DIR"

# ── 7. Generate rxresume .env if missing ─────────────────────────────────
ENV_FILE="$REPO_DIR/services/rxresume/.env"
if [ ! -f "$ENV_FILE" ]; then
  echo ""
  echo "▶ Generating rxresume secrets..."
  cat > "$ENV_FILE" << EOF
DB_PASSWORD=$(openssl rand -hex 32)
STORAGE_ACCESS_KEY=$(openssl rand -hex 32)
STORAGE_SECRET_KEY=$(openssl rand -hex 32)
ACCESS_TOKEN_SECRET=$(openssl rand -hex 32)
REFRESH_TOKEN_SECRET=$(openssl rand -hex 32)
CHROME_TOKEN=$(openssl rand -hex 32)
EOF
  echo "  ✓ .env generated at $ENV_FILE"
else
  echo "  ✓ .env already exists, skipping"
fi

# ── 8. Install systemd timer ──────────────────────────────────────────────
echo "▶ Installing GitOps systemd timer..."
sudo cp "$REPO_DIR/systemd/cash-deploy.service" /etc/systemd/system/
sudo cp "$REPO_DIR/systemd/cash-deploy.timer" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now cash-deploy.timer
echo "  ✓ cash-deploy.timer active"

# ── 9. First deploy ───────────────────────────────────────────────────────
echo ""
echo "▶ Running first deploy (Docker group takes effect after re-login)"
echo "  NOTE: if docker permission denied, log out/in then run: cd $REPO_DIR && ./deploy.sh"
echo ""

# Use sg to apply docker group without relogin
sg docker -c "cd $REPO_DIR && ./deploy.sh" || {
  echo "  ⚠ Deploy failed — log out, log back in, then run:"
  echo "    cd $REPO_DIR && ./deploy.sh"
}

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   Bootstrap complete!                    ║"
echo "║                                          ║"
echo "║   ⚠  Log out and back in so that         ║"
echo "║      seat + docker groups take effect    ║"
echo "║      (required for dual-monitor boot)    ║"
echo "╚══════════════════════════════════════════╝"
echo ""
