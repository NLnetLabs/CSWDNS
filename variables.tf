variable "num_vms" {
  type        = "string"
  description = "The number of Digital Ocean VMs to launch."
  default     = 1
}

variable "region" {
  type        = "string"
  description = "The Digital Ocean region name in which to deploy the VMs"
  default     = "ams3"
}

variable "size" {
  type        = "string"
  description = "(optional) The Digital Ocean Droplet size to use to host the Docker registry. Defaults to a small Droplet with 1 vCPU and 1 GiB RAM."
  default     = "s-1vcpu-1gb"
}

variable "public_ssh_key_path" {
  type        = "string"
  description = "The path to a local SSH public key file which will be granted access as user 'root' to the deployed VMs."
  default     = "~/.ssh/id_rsa.pub"
}

variable "parent_fqdn" {
  type        = "string"
  description = "A fully qualified domain name of a domain that you manage through Digital Ocean. DNS A records will be created under this domain in Digital Ocean for each launched VM."
}

variable "vm_base_name" {
  type        = "string"
  description = "A base name used to identify the Droplets to Digital Ocean and to use as a base host name for VMs. The name will be suffixed with a VM index"
  default     = "lab-"
}

variable "do_slug_name" {
  type        = "string"
  description = "The Digital Ocean slug (operating system image) to run on the VMs. See 'doctl compute image list-distribution' for possible values."
  default     = "ubuntu-18-10-x64"
}

variable "install_script_local_path" {
  type        = "string"
  description = "Path on your local machine to a shell script to execute on each VM when it is deployed."
}
