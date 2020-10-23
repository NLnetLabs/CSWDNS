terraform {
  required_version = "~> 0.11.13"
}

data "digitalocean_image" "slug" {
  slug = "${var.do_slug_name}"
}

resource "digitalocean_ssh_key" "rootkey" {
  name       = "VM SHS public key to be used for 'root' user access."
  public_key = "${file("${var.public_ssh_key_path}")}"
}

resource "digitalocean_record" "res_a" {
  count  = "${var.num_vms}"
  name   = "res-${count.index}"
  domain = "${var.parent_fqdn}"
  type   = "A"
  ttl    = 300
  value  = "${digitalocean_droplet.res_vm.*.ipv4_address[count.index]}"
}

resource "digitalocean_record" "res_aaaa" {
  count  = "${var.num_vms}"
  name   = "res-${count.index}"
  domain = "${var.parent_fqdn}"
  type   = "AAAA"
  ttl    = 300
  value  = "${digitalocean_droplet.res_vm.*.ipv6_address[count.index]}"
}

data "template_file" "res_install_script" {
  count    = "${var.num_vms}"
  template = "${file("${var.install_script_local_path}")}"

  vars = {
    MY_FQDN = "res-${count.index}"
  }
}

resource "digitalocean_record" "auth_a" {
  count  = "${var.num_vms}"
  name   = "auth-${count.index}"
  domain = "${var.parent_fqdn}"
  type   = "A"
  ttl    = 300
  value  = "${digitalocean_droplet.auth_vm.*.ipv4_address[count.index]}"
}

resource "digitalocean_record" "auth_aaaa" {
  count  = "${var.num_vms}"
  name   = "auth-${count.index}"
  domain = "${var.parent_fqdn}"
  type   = "AAAA"
  ttl    = 300
  value  = "${digitalocean_droplet.auth_vm.*.ipv6_address[count.index]}"
}

data "template_file" "auth_install_script" {
  count    = "${var.num_vms}"
  template = "${file("${var.install_script_local_path}")}"

  vars = {
    MY_FQDN = "auth-${count.index}"
  }
}

resource "digitalocean_droplet" "res_vm" {
  count    = "${var.num_vms}"
  name     = "res-${count.index}.${var.parent_fqdn}"
  image    = "${data.digitalocean_image.slug.image}"
  region   = "${var.region}"
  size     = "${var.size}"
  ssh_keys = ["${digitalocean_ssh_key.rootkey.fingerprint}", 23929669, 24050615]
  ipv6     = true
  private_networking = false

  # execute `cat /var/log/cloud-init-output.log` on the droplet to diagnose problems with execution of user_data commands
  # execute `cat /var/lib/cloud/instance/scripts/part-001` on the droplet to see the script after interpolation
  # execute 'docker logs registry' to see the error log of the Docker registry application.
  user_data = "${data.template_file.res_install_script.*.rendered[count.index]}"
}

resource "digitalocean_droplet" "auth_vm" {
  count    = "${var.num_vms}"
  name     = "auth-${count.index}.${var.parent_fqdn}"
  image    = "${data.digitalocean_image.slug.image}"
  region   = "${var.region}"
  size     = "${var.size}"
  ssh_keys = ["${digitalocean_ssh_key.rootkey.fingerprint}", 23929669, 24050615]
  ipv6     = true
  private_networking = false

  # execute `cat /var/log/cloud-init-output.log` on the droplet to diagnose problems with execution of user_data commands
  # execute `cat /var/lib/cloud/instance/scripts/part-001` on the droplet to see the script after interpolation
  # execute 'docker logs registry' to see the error log of the Docker registry application.
  user_data = "${data.template_file.auth_install_script.*.rendered[count.index]}"
}

