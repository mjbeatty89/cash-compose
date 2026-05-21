#!/bin/bash
# GitOps deploy — cash-containers
# Pulls latest from GitHub, brings up all services in services/*/
# Runs every 5 min via systemd timer (cash-deploy.timer)

set -euo pipefail
REPO_DIR="/home/mjb/projects/cash-compose"
LOG="$REPO_DIR/deploy.log"
STATE_FILE="$REPO_DIR/.last_deploy_commit"

cd "$REPO_DIR"
OLD_HASH=$(git rev-parse HEAD 2>/dev/null || echo "")
git pull origin main 2>&1 | tee -a "$LOG"
NEW_HASH=$(git rev-parse HEAD 2>/dev/null || echo "")

if [ "$OLD_HASH" == "$NEW_HASH" ] && [ -f ".last_deploy" ]; then
    if [ -z "$(find services -type f -name ".env" -newer .last_deploy -print -quit 2>/dev/null)" ]; then
        exit 0
    fi
fi

current_head=$(git rev-parse HEAD 2>/dev/null || echo "")
last_deployed_head=""

if [[ -f "$STATE_FILE" ]]; then
    last_deployed_head=$(<"$STATE_FILE")
    newer_env_file=$(find services/ -type f -name ".env" -newer "$STATE_FILE" -print -quit 2>/dev/null || true)
else
    newer_env_file=""
fi

if [[ -n "$last_deployed_head" && "$current_head" == "$last_deployed_head" && -z "$newer_env_file" ]]; then
    echo "[$(date)] no changes detected; skipping deployment" | tee -a "$LOG"
    exit 0
fi

# Bring up each service that has a compose.yml and a .env
pids=()
names=()
tmp_logs=()

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

    safe_name=$(printf '%s' "$name" | tr -c 'A-Za-z0-9_.-' '_')
    tmp_log=$(mktemp "$REPO_DIR/deploy_${safe_name}.XXXXXX.log")
    (
        echo "[$(date)] deploying $name..."
        docker compose -f "$compose" --env-file "$env_file" up -d --remove-orphans
    ) >"$tmp_log" 2>&1 &

    pids+=("$!")
    names+=("$name")
    tmp_logs+=("$tmp_log")
done

deploy_status=0
for i in "${!pids[@]}"; do
    if ! wait "${pids[$i]}"; then
        echo "[$(date)] ERROR ${names[$i]} deployment failed" | tee -a "$LOG"
        deploy_status=1
    fi
done

for tmp_log in "${tmp_logs[@]}"; do
    if [[ -f "$tmp_log" ]]; then
        tee -a "$LOG" < "$tmp_log"
        rm -f "$tmp_log"
    fi
done

if [[ "$deploy_status" -ne 0 ]]; then
    echo "[$(date)] deploy failed" | tee -a "$LOG"
    exit 1
fi

echo "$current_head" > "$STATE_FILE"
echo "[$(date)] deploy complete" | tee -a "$LOG"
touch .last_deploy
