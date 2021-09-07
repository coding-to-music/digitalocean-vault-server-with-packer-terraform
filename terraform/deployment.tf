resource "digitalocean_droplet" "vault" {
count              = var.instance_count
image              = var.do_snapshot_id
name               = var.do_name
region             = var.do_region
size               = var.do_size
monitoring         = var.do_monitoring
private_networking = var.do_private_networking
ssh_keys = [
  var.ssh_fingerprint
]
}

terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
    }
  }
  required_version = ">= 0.13"
}

output "instance_ip_addr" {
value = {
  for instance in digitalocean_droplet.vault:
  instance.id => instance.ipv4_address
}
description = "The IP addresses of the deployed instances, paired with their IDs."
}