## 2024-05-24 - Parallel Docker Compose Deployment
**Learning:** Sequential docker compose commands in a cron-style script become a significant bottleneck as the number of services scales, risking overlapping runs if total deployment time exceeds the timer interval.
**Action:** Background independent `docker compose` calls within shell scripts and wait for completion to reduce total execution time.
