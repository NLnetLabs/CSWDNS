output "ip_addresses" {
    value = ["${digitalocean_droplet.res_vm.*.ipv4_address}"]
}

output "ipv6_addresses" {
    value = ["${digitalocean_droplet.res_vm.*.ipv6_address}"]
}

output "fqdns" {
    value = ["${digitalocean_record.res_a.*.fqdn}", "${digitalocean_record.auth_a.*.fqdn}"]
}


