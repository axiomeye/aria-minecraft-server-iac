# Aria Minecraft Server IaC

A Minecraft server hosted on Google Cloud Platform, managed via Terraform and GitHub Actions. The server runs on a preemptible Spot VM that is created on demand and destroyed when idle, keeping costs minimal.

![Deploy](https://github.com/axiomeye/aria-minecraft-server-iac/actions/workflows/create_infrastructure.workflow.yml/badge.svg)
![Destroy](https://github.com/axiomeye/aria-minecraft-server-iac/actions/workflows/destroy_infrastructure.workflow.yml/badge.svg)
![Frontend](https://github.com/axiomeye/aria-minecraft-server-iac/actions/workflows/deploy_frontend.workflow.yml/badge.svg)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Google Cloud Platform                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   ┌──────────────────────────────────────────────────────┐  │
│   │              VPC: minecraft-aria-network              │  │
│   │                                                       │  │
│   │   ┌───────────────────────────────────────────────┐  │  │
│   │   │       Compute Instance (Spot/Preemptible)     │  │  │
│   │   │                                               │  │  │
│   │   │   ┌───────────────────────────────────────┐  │  │  │
│   │   │   │  Docker: itzg/minecraft-server        │  │  │  │
│   │   │   │  - Fabric 1.20.1                      │  │  │  │
│   │   │   │  - 28 GB RAM                          │  │  │  │
│   │   │   │  - Auto-stop on idle                  │  │  │  │
│   │   │   └───────────────────────────────────────┘  │  │  │
│   │   │                                               │  │  │
│   │   │   Boot Disk (10 GB)  +  Data Disk (persistent)│  │  │
│   │   └───────────────────────────────────────────────┘  │  │
│   └──────────────────────────────────────────────────────┘  │
│                                                              │
│   ┌──────────────────┐   ┌──────────────────────────────┐   │
│   │  Cloud Run       │   │  GCS Bucket                  │   │
│   │  (AriA Panel)    │   │  (Terraform state)           │   │
│   └──────────────────┘   └──────────────────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ Port 25565
                              ▼
                    ┌─────────────────┐
                    │  Minecraft      │
                    │  Players        │
                    └─────────────────┘
```

---

## Features

- **Cost-optimized** — Uses Spot/Preemptible VMs for significant cost savings
- **Auto-stop** — Server shuts down automatically when no players are online
- **Auto-destroy** — Infrastructure is torn down when CPU usage drops below threshold
- **Persistent world data** — World stored on a separate persistent disk, survives VM deletion
- **AriA Panel** — Private Cloud Run web app for starting the server and monitoring its IP
- **Telegram notifications** — Server status updates sent to the group chat
- **Fabric mod support** — Pre-configured for Fabric 1.20.1

---

## Project Structure

```
├── .github/
│   └── workflows/
│       ├── build_frontend.workflow.yml       # Build and push Docker image for the panel
│       ├── deploy_frontend.workflow.yml      # Deploy panel to Cloud Run
│       ├── create_infrastructure.workflow.yml
│       ├── destroy_infrastructure.workflow.yml
│       └── send_ip_address.workflow.yml
├── frontend/
│   ├── app.py                  # Flask web panel (OAuth login, server controls)
│   ├── templates/index.html    # Panel UI
│   ├── requirements.txt
│   └── Dockerfile
├── terraform/
│   ├── main.tf                 # Compute instance resource
│   ├── variables.tf
│   ├── outputs.tf
│   ├── backend.tf
│   ├── terraform.tfvars.example
│   └── scripts/
│       ├── config.sh           # Startup script (mounts disk, starts Docker)
│       └── shutdown.sh
├── wiki/                       # Source files mirrored to GitHub Wiki
└── readme.md
```

---

## Setup

### Prerequisites

1. A Google Cloud Platform project
2. A GCS bucket for Terraform remote state
3. A service account with Compute, Storage, and Cloud Run permissions
4. A Telegram bot and chat ID for notifications
5. A GitHub App for triggering repository dispatch events
6. A Google OAuth 2.0 Client ID for the AriA Panel

### GitHub Environment (`aria-production`) — Secrets

| Secret | Description |
|--------|-------------|
| `FRONTEND_OAUTH_CLIENT_ID` | Google OAuth 2.0 Client ID |
| `FRONTEND_OAUTH_CLIENT_SECRET` | Google OAuth 2.0 Client Secret |
| `FRONTEND_FLASK_SECRET` | Random secret key for Flask sessions |
| `GH_APP_ID` | GitHub App ID |
| `GH_APP_INSTALLATION_ID` | GitHub App Installation ID |
| `GH_APP_PRIVATE_KEY` | GitHub App RSA private key (PEM) |
| `DOCKERHUB_USERNAME` | Docker Hub username for image push |
| `DOCKERHUB_TOKEN` | Docker Hub access token |

### GitHub Environment (`aria-production`) — Variables

| Variable | Description |
|----------|-------------|
| `REGION` | GCP region (e.g. `europe-west8`) |
| `ZONE` | GCP zone (e.g. `europe-west8-a`) |
| `INSTANCE_NAME` | Compute instance name |
| `FRONTEND_ALLOWED_EMAILS` | Comma-separated list of emails allowed to log into the panel |
| `WORKLOAD_IDENTITY_PROVIDER` | Workload identity provider for keyless auth |
| `GCP_SERVICE_ACCOUNT` | Service account email for GitHub Actions |

---

## How It Works

### Starting the server

Log into the [AriA Panel](https://aria-mc-server-972697371927.europe-west8.run.app) and click **Start**. This triggers the `create-infr` repository dispatch event via the GitHub App, which runs the Terraform workflow to provision the VM.

### Server IP

The panel polls the GCE instance every 10 seconds and displays the IP address as soon as it is assigned.

### Stopping the server

The server shuts itself down automatically when no players are connected. The VM is then destroyed by the idle-detection workflow to avoid idle costs.

---

## Cost Estimate

| Resource | Approx. cost |
|----------|-------------|
| n2-highmem-4 (Spot) | ~$0.05 / hour |
| 10 GB boot disk | ~$0.80 / month |
| Persistent data disk | varies by size |
| Cloud Run panel (scale-to-zero) | near $0 |
| Network egress | pay per use |

---

## Troubleshooting

**Server won't start**
- Check the startup script logs in Cloud Logging
- Verify the data disk is attached to the instance
- Inspect Docker logs on the VM: `docker logs mc`

**Can't connect**
- Confirm firewall rules allow TCP port 25565
- Check that the IP shown in the panel is current — it changes on each VM creation
- Verify the Minecraft client is on version 1.20.1 with Fabric loaded

---

## License

Open source. Use and modify freely.