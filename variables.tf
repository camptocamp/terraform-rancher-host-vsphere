variable "instance_count" {
  default = 1
}

variable "datacenter" {}

variable "datastore" {}

variable "resource_pool" {
  default = "Cluster1/Resources"
}

variable "primary_network" {
  default = "VM Network"
}

variable "iprange" {}

variable "hostnum" {
  default = 1
}

variable "num_cpus" {}

variable "memory" {}

variable "root_disk_size" {}

variable "public_keys" {}

variable "instance_image" {}

variable "puppet_autosign_psk" {}

variable "puppet_environment" {}

variable "puppet_role" {}

variable "puppet_server" {}

variable "puppet_caserver" {}

variable "additional_user_data" {
  default = "#cloud-config\n"
}

variable "domain" {}

variable "tags" {
  default = {}
}
