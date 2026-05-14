#!/bin/bash
# GitOps deploy — cash-containers
# Pulls latest from GitHub, brings up all services in services/*/
# Runs every 5 min via systemd timer (cash-deploy.timer)

set -e
REPO_DIR="/home/mjb/projects/cash-compose"
LOG="$REPO_DIR/deploy.log"

cd "$REPO_DIR"
git pull origin main 2>&1 | tee -a "$LOG"

# Bring up each service that has a compose.yml and a .env
for dir in services/*/; do
    name=$(basename "$dir")
    compose="$dir/compose.yml"
    env_file="$dir/.env"

    # Skip template and dirs without compose
    [[ "$name" == "_template" ]] && continue
    [[ ! -f "$compose" ]] && continue

    if [[ ! -f "$env_file" ]]; then
        echo "[$(date)] SKIP $name — no .env file (copy from .env.example)" | tee -a "$LOG"
        continue
    fi

    echo "[$(date)] deploying $name..." | tee -a "$LOG"
    # ⚡ Bolt Optimization: Run independent container deployments concurrently.
    # Expected Impact: Reduces total deployment time from O(N) to O(1) bound by the slowest service.
    docker compose -f "$compose" --env-file "$env_file" up -d --remove-orphans 2>&1 | tee -a "$LOG" &
done

wait

echo "[$(date)] deploy complete" | tee -a "$LOG"
