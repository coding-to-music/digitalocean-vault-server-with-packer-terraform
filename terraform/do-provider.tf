variable "do_token" {
}

variable "ssh_fingerprint" {
}

variable "instance_count" {
default = "1"
}

variable "do_snapshot_id" {
}

variable "do_name" {
default = "vault"
}

variable "do_region" {
}

variable "do_size" {
}

variable "do_private_networking" {
default = true
}

provider "digitalocean" {
token = var.do_token
}

variable "do_monitoring" {
}

