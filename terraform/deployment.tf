resource "digitalocean_droplet" "vault-01" {
  name                = "vault-01"
  # count               = var.instance_count
  image               = var.do_snapshot_id
  region              = var.do_region
  size                = var.do_size
  monitoring          = var.do_monitoring
  private_networking  = var.do_private_networking
  ssh_keys = [
    var.ssh_fingerprint
  ]
}

# create various droplets
resource "digitalocean_droplet" "multi-01" {
  name                = "multi-01"
  count               = var.instance_count
  image               = var.do_snapshot_id
  region              = var.do_region
  size                = var.do_size
  monitoring          = var.do_monitoring
  private_networking  = var.do_private_networking
  ssh_keys = [
    var.ssh_fingerprint
  ]
}

resource "digitalocean_droplet" "grafana-01" {
  name                = "grafana-01"
  count               = var.instance_count
  image               = var.do_snapshot_id
  region              = var.do_region
  size                = var.do_size
  monitoring          = var.do_monitoring
  private_networking  = var.do_private_networking
  ssh_keys = [
    var.ssh_fingerprint
  ]
}

resource "digitalocean_droplet" "redis-01" {
  name                = "redis-01"
  count               = var.instance_count
  image               = var.do_snapshot_id
  region              = var.do_region
  size                = var.do_size
  monitoring          = var.do_monitoring
  private_networking  = var.do_private_networking
  ssh_keys = [
    var.ssh_fingerprint
  ]
}

resource "digitalocean_droplet" "influxdb-01" {
  name                = "influxdb-01"
  count               = var.instance_count
  image               = var.do_snapshot_id
  region              = var.do_region
  size                = var.do_size
  monitoring          = var.do_monitoring
  private_networking  = var.do_private_networking
  ssh_keys = [
    var.ssh_fingerprint
  ]
}

resource "digitalocean_droplet" "postgres-01" {
  name                = "postgres-01"
  count               = var.instance_count
  image               = var.do_snapshot_id
  region              = var.do_region
  size                = var.do_size
  monitoring          = var.do_monitoring
  private_networking  = var.do_private_networking
  ssh_keys = [
    var.ssh_fingerprint
  ]
}

resource "digitalocean_droplet" "mongodb-01" {
  name                = "mongodb-01"
  count               = var.instance_count
  image               = var.do_snapshot_id
  region              = var.do_region
  size                = var.do_size
  monitoring          = var.do_monitoring
  private_networking  = var.do_private_networking
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

# create an ansible inventory file
resource "null_resource" "ansible-provision" {
  depends_on = [
    digitalocean_droplet.vault-01,
    digitalocean_droplet.grafana-01,
    digitalocean_droplet.mongodb-01,
    digitalocean_droplet.postgres-01,
    digitalocean_droplet.multi-01,
    digitalocean_droplet.redis-01,
    digitalocean_droplet.influxdb-01,
  ]

  provisioner "local-exec" {
    command = "echo '${digitalocean_droplet.vault-01.name} ansible_host=${digitalocean_droplet.vault-01.ipv4_address} ansible_ssh_user=root ansible_python_interpreter=/usr/bin/python3' > inventory"
  }

  provisioner "local-exec" {
    command = "echo '${digitalocean_droplet.grafana-01.name} ansible_host=${digitalocean_droplet.grafana-01.ipv4_address} ansible_ssh_user=root ansible_python_interpreter=/usr/bin/python3' > inventory"
  }

  provisioner "local-exec" {
    command = "echo '${digitalocean_droplet.mongodb-01.name} ansible_host=${digitalocean_droplet.mongodb-01.ipv4_address} ansible_ssh_user=root ansible_python_interpreter=/usr/bin/python3' > inventory"
  }

  provisioner "local-exec" {
    command = "echo '${digitalocean_droplet.postgres-01.name} ansible_host=${digitalocean_droplet.postgres-01.ipv4_address} ansible_ssh_user=root ansible_python_interpreter=/usr/bin/python3' > inventory"
  }

  provisioner "local-exec" {
    command = "echo '${digitalocean_droplet.redis-01.name} ansible_host=${digitalocean_droplet.redis-01.ipv4_address} ansible_ssh_user=root ansible_python_interpreter=/usr/bin/python3' > inventory"
  }

  provisioner "local-exec" {
    command = "echo '${digitalocean_droplet.multi-01.name} ansible_host=${digitalocean_droplet.multi-01.ipv4_address} ansible_ssh_user=root ansible_python_interpreter=/usr/bin/python3' > inventory"
  }

  provisioner "local-exec" {
    command = "echo '${digitalocean_droplet.influxdb-02.name} ansible_host=${digitalocean_droplet.influxdb-02.ipv4_address} ansible_ssh_user=root ansible_python_interpreter=/usr/bin/python3' >> inventory"
  }
}


output "instance_ip_addr" {
value = {
  for instance in digitalocean_droplet.vault:
  instance.id => instance.ipv4_address
}
description = "The IP addresses of the deployed instances, paired with their IDs."
}

