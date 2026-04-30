## 2024-04-23 - Skipping Unnecessary Deployments
**Learning:** The GitOps deployment script (`deploy.sh`) runs `docker compose up -d` sequentially for every service every 5 minutes. Since this executes regardless of changes, it causes unnecessary CPU/IO load and log spam 288 times a day.
**Action:** Implemented a short-circuit check using git commit hashes and file modification timestamps (for `.env` files) to skip Docker Compose commands when no configuration or environment files have changed.
