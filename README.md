# cash-compose — Infrastructure as Code for cash-containers

GitOps-managed Docker Compose stack. Every push to `main` is live within 5 minutes.

## Structure

```
services/
  rxresume/       ← Resume builder (resume.aadd.rocks)
  _template/      ← Copy this to add a new service
systemd/          ← Auto-deploy timer (installed once)
deploy.sh         ← Called by systemd timer
```

## Adding a New Service

1. Copy `services/_template/` to `services/<appname>/`
2. Edit `compose.yml` and `.env.example`
3. SSH to cash, create `services/<appname>/.env` with real secrets
4. Commit + push — deployed within 5 min

> **Rule:** `.env` files are never committed (in .gitignore). All secrets live only on the host.

## One-Time Setup (already done)

```bash
# Install Docker Engine
sudo pacman -S docker docker-compose
sudo systemctl enable --now docker
sudo usermod -aG docker mjb

# Clone repo
git clone https://github.com/mjbeatty89/cash-compose ~/projects/cash-compose
cd ~/projects/cash-compose
chmod +x deploy.sh

# Install systemd timer
sudo cp systemd/cash-deploy.service /etc/systemd/system/
sudo cp systemd/cash-deploy.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now cash-deploy.timer
```

## Manual Deploy

```bash
cd ~/projects/cash-compose && ./deploy.sh
```
