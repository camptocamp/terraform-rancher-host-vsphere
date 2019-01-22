data "vsphere_datacenter" "dc" {
  name = "${var.datacenter}"
}

data "vsphere_datastore" "datastore" {
  name          = "${var.datastore}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_resource_pool" "pool" {
  name          = "${var.resource_pool}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name          = "${var.primary_network}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "template" {
  name          = "${var.instance_image}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "rancher_registration_token" "registration-token" {
  count          = "${var.instance_count}"
  name           = ""
  environment_id = "${var.rancher_environment_id}"
  host_labels    = "${var.host_labels}"
  agent_ip       = "${cidrhost(var.iprange, var.hostnum + count.index)}"
}

data "template_file" "network" {
  count    = "${var.instance_count}"
  template = "${file("${path.module}/cloud-init/network.tpl")}"

  vars {
    iface       = "ens192"
    address     = "${cidrhost(var.iprange, var.hostnum + count.index)}"
    netmask     = "${element(split("/", var.iprange), 1)}"
    gateway     = "${cidrhost(var.iprange, -2)}"
    nameservers = "213.186.33.99"
  }
}

data "template_file" "fqdn" {
  count    = "${var.instance_count}"
  template = "${file("${path.module}/cloud-init/fqdn.tpl")}"

  vars {
    hostname = "${format("ip-%s", join("-", split(".", cidrhost(var.iprange, var.hostnum + count.index))))}"
    domain   = "${var.domain}"
  }
}

data "template_file" "rancher-agent" {
  count    = "${var.instance_count}"
  template = "${file("${path.module}/cloud-init/rancher-agent.tpl")}"

  vars {
    command = "${element(rancher_registration_token.registration-token.*.command, count.index)}"
  }
}

data "template_file" "puppet" {
  template = "${file("${path.module}/cloud-init/puppet.tpl")}"

  vars {
    puppet_autosign_challenge = "${format("psk;%s", var.puppet_autosign_psk)}"
    puppet_environment        = "${var.puppet_environment}"
    puppet_role               = "${var.puppet_role}"
    puppet_server             = "${var.puppet_server}"
    puppet_caserver           = "${var.puppet_caserver}"
  }
}

data "template_cloudinit_config" "config" {
  count = "${var.instance_count}"

  gzip          = false
  base64_encode = false

  part {
    filename     = "network.cfg"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = "${element(data.template_file.network.*.rendered, count.index)}"
  }

  part {
    filename     = "fqdn.cfg"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = "${element(data.template_file.fqdn.*.rendered, count.index)}"
  }

  part {
    filename     = "install.cfg"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = "${file("${path.module}/cloud-init/install.tpl")}"
  }

  part {
    filename     = "docker.cfg"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = "${file("${path.module}/cloud-init/docker.tpl")}"
  }

  part {
    filename     = "rancher-agent.cfg"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = "${element(data.template_file.rancher-agent.*.rendered, count.index)}"
  }

  part {
    filename     = "puppet.cfg"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = "${data.template_file.puppet.rendered}"
  }

  part {
    filename     = "additional.cfg"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = "${var.additional_user_data}"
  }
}

resource "random_string" "default_user_password" {
  count   = "${var.instance_count}"
  length  = 16
  upper   = false
  number  = false
  special = false
}

resource "vsphere_virtual_machine" "rancher-node" {
  count            = "${var.instance_count}"
  name             = "${format("ip-%s.%s", join("-", split(".", cidrhost(var.iprange, var.hostnum + count.index))), var.domain)}"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"

  num_cpus = "${var.num_cpus}"
  memory   = "${var.memory}"
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"

  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

  network_interface {
    network_id = "${data.vsphere_network.network.id}"
  }

  disk {
    label            = "disk0"
    size             = "${var.root_disk_size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }

  cdrom {
    client_device = true
  }

  vapp {
    properties {
      instance-id = "${format("ip-%s.%s", join("-", split(".", cidrhost(var.iprange, var.hostnum + count.index))), var.domain)}"
      password    = "${element(random_string.default_user_password.*.result, count.index)}"
      user-data   = "${element(data.template_cloudinit_config.config.*.rendered, count.index)}"
      hostname    = "${format("ip-%s.%s", join("-", split(".", cidrhost(var.iprange, var.hostnum + count.index))), var.domain)}"
      public-keys = "${var.public_keys}"
    }
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"
  }

  lifecycle {
    ignore_changes = ["cdrom", "vapp"]
  }
}

resource "puppetdb_node" "rancher-node" {
  count    = "${var.instance_count}"
  certname = "${element(vsphere_virtual_machine.rancher-node.*.name, count.index)}"
}

resource "puppetca_certificate" "rancher-node" {
  count = "${var.instance_count}"
  name  = "${element(vsphere_virtual_machine.rancher-node.*.name, count.index)}"
}

resource "rancher_host" "rancher-node" {
  count          = "${var.instance_count}"
  name           = ""
  environment_id = "${var.rancher_environment_id}"
  hostname       = "${element(vsphere_virtual_machine.rancher-node.*.name, count.index)}"
  labels         = "${merge(var.host_labels, map("io.rancher.host.os", "linux"))}"
}
