#!/bin/bash
# GitOps deploy — cash-containers
# Pulls latest from GitHub, brings up all services in services/*/
# Runs every 5 min via systemd timer (cash-deploy.timer)

set -e
REPO_DIR="/home/mjb/projects/cash-compose"
LOG="$REPO_DIR/deploy.log"

cd "$REPO_DIR"

# ⚡ Bolt Optimization: Only run docker-compose if there are new commits or updated .env files
# Impact: Saves CPU and disk I/O every 5 mins by skipping unnecessary docker-compose runs
LOCAL_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "")
git pull origin main 2>&1 | tee -a "$LOG"
NEW_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "")

DO_DEPLOY=0

# Trigger if there are new commits
if [[ "$LOCAL_COMMIT" != "$NEW_COMMIT" ]] || [[ -z "$LOCAL_COMMIT" ]]; then
    DO_DEPLOY=1
fi

# Trigger if any .env file was modified since the last deploy
if [[ -f .last_deploy ]]; then
    # find outputs paths if newer files exist; read the first line
    NEWER_ENV=$(find services/ -type f -name ".env" -newer .last_deploy 2>/dev/null | head -n 1)
    if [[ -n "$NEWER_ENV" ]]; then
        DO_DEPLOY=1
    fi
else
    DO_DEPLOY=1
fi

# Skip expensive operations if nothing changed
if [[ "$DO_DEPLOY" -eq 0 ]]; then
    exit 0
fi

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
    docker compose -f "$compose" --env-file "$env_file" up -d --remove-orphans 2>&1 | tee -a "$LOG"
done

touch .last_deploy
echo "[$(date)] deploy complete" | tee -a "$LOG"
