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
      // 28G is retained deliberately. The itzg image applies Aikar's
      // large-heap profile automatically at MEMORY >= 12G, which is the
      // tuning this server was missing; the heap size was never the issue.
      memory     = "28G"
      mc_version = "1.20.1"
      image_tag  = "java17"
      // Aikar rather than MeowIce here: this is the live world, and the
      // itzg image switches Aikar to its large-heap profile at >= 12G.
      jvm_flags = "aikar"
      // Mods live on the disk and are the frozen 1.20.1 set; see
      // mods/manifest-1.20.1.json. Deliberately NOT packwiz-managed: the
      // installer prunes mods/ and this disk holds the only copy.
      packwiz_url = ""
    }

    cobblemon = {
      instance_name = "aria-minecraft-cobblemon-instance"
      disk_name     = "aria-minecraft-cobblemon-data"
      // 4 vCPU, 8G. No stock n2 shape has 4 vCPU under 16G, hence custom.
      // Cores matter (single-threaded tick loop, chunk gen); the extra 8G
      // of a standard-4 would have sat unused. Raise both lines together
      // if these worlds turn out to need more headroom.
      machine_type = "n2-custom-4-8192"
      memory       = "6G"
      // Cobblemon's ceiling: 1.8.0 (Sept 2026) still targets 1.21.1.
      mc_version = "1.21.1"
      image_tag  = "java21"
      // MeowIce: Aikar-derived but with Java 17+ optimisations, and these
      // worlds are on Java 21 with nothing at stake yet.
      jvm_flags = "meowice"
      // Served by GitHub Pages from packs/ in this repo. The GCS bucket cannot
      // host these: it has uniform access with public access prevention enforced,
      // and weakening that would expose the Terraform state and mod mirror too.
      packwiz_url = "https://axiomeye.github.io/aria-minecraft-server-iac/packs/cobblemon/pack.toml"
    }

    latest = {
      instance_name = "aria-minecraft-latest-instance"
      disk_name     = "aria-minecraft-latest-data"
      // 4 vCPU, 8G. No stock n2 shape has 4 vCPU under 16G, hence custom.
      // Cores matter (single-threaded tick loop, chunk gen); the extra 8G
      // of a standard-4 would have sat unused. Raise both lines together
      // if these worlds turn out to need more headroom.
      machine_type = "n2-custom-4-8192"
      memory       = "6G"
      mc_version   = "26.2"
      image_tag    = "java21"
      jvm_flags    = "meowice"
      packwiz_url  = "https://axiomeye.github.io/aria-minecraft-server-iac/packs/latest/pack.toml"
    }
  }

  // The world being applied, selected by var.world.
  w = local.worlds[var.world]

  // Stable device name; the disk appears as /dev/disk/by-id/google-<device_name>.
  disk_device_name = "aria-data-disk"
}
