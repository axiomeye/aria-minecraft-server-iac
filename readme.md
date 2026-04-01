# Aria Minecraft Server IaC

A Minecraft Server hosted on Google Cloud Platform using Terraform and GitHub Actions.

![Deploy](https://github.com/axiomeye/aria-minecraft-server-iac/actions/workflows/create_infrastructure.workflow.yml/badge.svg)
![Destroy](https://github.com/axiomeye/aria-minecraft-server-iac/actions/workflows/destroy_infrastructure.workflow.yml/badge.svg)

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Google Cloud Platform                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   ┌─────────────────────────────────────────────────────┐   │
│   │              VPC: minecraft-aria-network             │   │
│   │                                                      │   │
│   │   ┌──────────────────────────────────────────────┐  │   │
│   │   │     Compute Instance (Spot/Preemptible)      │  │   │
│   │   │                                              │  │   │
│   │   │   ┌──────────────────────────────────────┐   │  │   │
│   │   │   │  Docker: itzg/minecraft-server       │   │  │   │
│   │   │   │  - Fabric 1.20.1                     │   │  │   │
│   │   │   │  - 28GB RAM                          │   │  │   │
│   │   │   │  - Auto-stop on idle                 │   │  │   │
│   │   │   └──────────────────────────────────────┘   │  │   │
│   │   │                                              │  │   │
│   │   │   Boot Disk (10GB)    Data Disk (Persistent) │  │   │
│   │   └──────────────────────────────────────────────┘  │   │
│   │                                                      │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                              │
│   ┌─────────────────┐    ┌─────────────────────────────┐    │
│   │  GCS Bucket     │    │  Cloud Ops Agent            │    │
│   │  (Terraform     │    │  (Monitoring & Logging)     │    │
│   │   State)        │    │                             │    │
│   └─────────────────┘    └─────────────────────────────┘    │
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

## 📋 Features

- **Cost-Optimized**: Uses Spot/Preemptible VMs for significant cost savings
- **Auto-Stop**: Server automatically stops when idle to save costs
- **Auto-Destroy**: Infrastructure is destroyed when CPU usage is low
- **Persistent Data**: World data is stored on a separate persistent disk
- **Telegram Notifications**: Server status updates sent to Telegram
- **Fabric Mod Support**: Ready for Fabric mods (1.20.1)

## 🚀 Quick Start

### Prerequisites

1. A Google Cloud Platform project
2. A GCS bucket for Terraform state
3. A service account with appropriate permissions
4. Telegram bot and chat for notifications
5. GitHub repository with Actions enabled

### Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `PROJECT_NAME` | GCP project ID |
| `GCP_BUCKET` | GCS bucket name for Terraform state |
| `GCP_SA_EMAIL` | Service account email |
| `GCP_SA_KEY` | Service account JSON key (base64 encoded) |
| `TELEGRAM_TO` | Telegram chat ID |
| `TELEGRAM_TOKEN` | Telegram bot token |

### Required GitHub Variables

| Variable | Description |
|----------|-------------|
| `REGION` | GCP region (e.g., `europe-west8`) |
| `ZONE` | GCP zone (e.g., `europe-west8-a`) |
| `INSTANCE_NAME` | Name for the compute instance |
| `CREATE_MESSAGE` | Message sent when creating infrastructure |
| `BEGIN_DESTROY_MESSAGE` | Message sent when starting destroy |
| `DESTROY_MESSAGE` | Message sent when destroy completes |

## 🎮 How to Use

### Start the Server

Trigger the `create-infr` repository dispatch event:

```bash
curl -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer YOUR_GITHUB_TOKEN" \
  https://api.github.com/repos/OWNER/REPO/dispatches \
  -d '{"event_type":"create-infr"}'
```

### Get Server IP

Trigger the `send-ip-address` repository dispatch event:

```bash
curl -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer YOUR_GITHUB_TOKEN" \
  https://api.github.com/repos/OWNER/REPO/dispatches \
  -d '{"event_type":"send-ip-address"}'
```

### Stop the Server

Trigger the `destroy-infr` repository dispatch event:

```bash
curl -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer YOUR_GITHUB_TOKEN" \
  https://api.github.com/repos/OWNER/REPO/dispatches \
  -d '{"event_type":"destroy-infr"}'
```

## 📁 Project Structure

```
├── .github/
│   └── workflows/
│       ├── create_infrastructure.workflow.yml   # Create server
│       ├── destroy_infrastructure.workflow.yml  # Destroy server
│       └── send_ip_address.workflow.yml         # Get server IP
├── terraform/
│   ├── backend.tf          # Provider and backend configuration
│   ├── main.tf             # Compute instance resource
│   ├── variables.tf        # Input variables
│   ├── outputs.tf          # Output values
│   ├── terraform.tfvars.example  # Example variable values
│   └── scripts/
│       ├── config.sh       # Startup script
│       └── shutdown.sh     # Shutdown script
└── readme.md
```

## 💰 Cost Estimation

This setup is designed to minimize costs:

| Resource | Cost |
|----------|------|
| n2-highmem-4 (Spot) | ~$0.05/hour |
| 10GB Boot Disk | ~$0.80/month |
| Data Disk | Varies by size |
| Network Egress | Pay per use |

**Tip**: The auto-destroy feature helps minimize costs by shutting down when not in use.

## 🔧 Configuration

See `terraform/terraform.tfvars.example` for all available configuration options.

### Customizing the Server

Edit `terraform/scripts/config.sh` to customize:
- Minecraft version
- Memory allocation
- Mod loading
- Server properties

## 🛠️ Troubleshooting

### Server Won't Start
1. Check the startup script logs in Cloud Console
2. Verify the data disk is properly attached
3. Check Docker container logs: `docker logs mc`

### Can't Connect
1. Verify firewall rules allow port 25565
2. Check if the server is healthy: `docker inspect mc`
3. Ensure the IP address is correct (may change on recreate)

## 📄 License

This project is open source. Feel free to use and modify as needed.