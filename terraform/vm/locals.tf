// World definitions.
//
// Each world is a fully independent server: its own VM, its own persistent data
// disk, and its own Terraform state (the backend prefix is set per-world at init
// time, see .github/workflows/create_infrastructure.workflow.yml). Applying one
// world never touches another.
//
// Data disks are deliberately created OUTSIDE Terraform (gcloud compute disks
// create) so that no terraform destroy can ever take a world with it. Terraform
// only attaches them.

locals {
  worlds = {
    classic = {
      instance_name = "aria-minecraft-server-instance"
      disk_name     = "aria-minecraft-server-data"
      machine_type  = "n2-highmem-4"
      memory        = "28G"
      mc_version    = "1.20.1"
      image_tag     = "java17"
      // Mods live on the disk and are the frozen 1.20.1 set; see
      // mods/manifest-1.20.1.json. Deliberately NOT packwiz-managed: the
      // installer prunes mods/ and this disk holds the only copy.
      packwiz_url = ""
    }

    cobblemon = {
      instance_name = "aria-minecraft-cobblemon-instance"
      disk_name     = "aria-minecraft-cobblemon-data"
      machine_type  = "n2-highmem-2"
      memory        = "12G"
      // Cobblemon's ceiling: 1.8.0 (Sept 2026) still targets 1.21.1.
      mc_version  = "1.21.1"
      image_tag   = "java21"
      packwiz_url = "https://storage.googleapis.com/aria-minecraft-server/packs/cobblemon/pack.toml"
    }

    latest = {
      instance_name = "aria-minecraft-latest-instance"
      disk_name     = "aria-minecraft-latest-data"
      machine_type  = "n2-highmem-2"
      memory        = "12G"
      mc_version    = "26.2"
      image_tag     = "java21"
      packwiz_url   = "https://storage.googleapis.com/aria-minecraft-server/packs/latest/pack.toml"
    }
  }

  // The world being applied, selected by var.world.
  w = local.worlds[var.world]

  // Stable device name; the disk appears as /dev/disk/by-id/google-<device_name>.
  disk_device_name = "aria-data-disk"
}
