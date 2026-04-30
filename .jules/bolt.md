## 2024-06-25 - Avoid unnecessary workloads in polling GitOps scripts
**Learning:** In a polling GitOps architecture running via a systemd timer every 5 minutes, naive deployment scripts that repeatedly run `docker compose up` incur significant unnecessary CPU, disk I/O, and log spam.
**Action:** Always implement a short-circuit condition. By checking if the local git commit hash has changed after a pull or if local secret files (e.g. `.env`) have been modified since the last deployment, we can exit early and save resources without sacrificing deployment frequency.
