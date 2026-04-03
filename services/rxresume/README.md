# Rx Resume

Self-hosted resume builder. UI at https://resume.aadd.rocks

## Setup

```bash
# Generate .env from example
cp .env.example .env

# Fill in secrets (run this 6 times, use each output for one variable)
openssl rand -hex 32

# Start the stack
docker compose up -d

# First run: create your account at https://resume.aadd.rocks
# Then disable signups:
# Set DISABLE_SIGNUPS=true in .env, then: docker compose up -d
```

## Subdomains needed
- `resume.aadd.rocks` → this host port 3500 (via VPS Caddy + Tailscale)
- `storage-resume.aadd.rocks` → this host port 9000 (MinIO, for image uploads)

## Data
- DB: Docker volume `rxresume_db`
- Files: Docker volume `rxresume_storage`
- Import existing JSON resume: Settings → Import → JSON Resume / Rx Resume format
