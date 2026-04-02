# aria-minecraft-server-iac

![Create](https://github.com/axiomeye/aria-minecraft-server-iac/actions/workflows/create_infrastructure.workflow.yml/badge.svg)
![Destroy](https://github.com/axiomeye/aria-minecraft-server-iac/actions/workflows/destroy_infrastructure.workflow.yml/badge.svg)
![Send IP](https://github.com/axiomeye/aria-minecraft-server-iac/actions/workflows/send_ip_address.workflow.yml/badge.svg)

## Architecture

```mermaid
graph TD
    subgraph GCP[Google Cloud Platform]
        subgraph VPC["VPC: minecraft-aria-network"]
            subgraph VM["Compute Instance (Spot/Preemptible)"]
                Docker["Docker: itzg/minecraft-server<br/>- Fabric 1.20.1<br/>- 28 GB RAM<br/>- Auto-stop on idle"]
                Disks["Boot Disk (10 GB) + Data Disk (persistent)"]
            end
        end

        Panel["Cloud Run (AriA Panel)"]
        Bucket["GCS Bucket (Terraform state)"]
    end

    Players["Minecraft Players"]

    Players -- "Port 25565" --> VM
```
