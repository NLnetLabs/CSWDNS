# tl;dr

1. Create a Digital Ocean account
2. Create an API token at https://cloud.digitalocean.com/account/api/tokens
3. Download terraform from https://www.terraform.io/downloads.html
4. Git clone this repo
5. Copy `terraform.tfvars.example` to `terraform.tfvars` and edit to match your needs.
6. Deploy:
```
$ export DIGITALOCEAN_TOKEN=xxxx
$ terraform init   # only needs to be done once
$ terraform apply
```
7. Wait for deployment to complete...
```
...
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

fqdns = [
    lab-0.do.dns-school.org,
    lab-1.do.dns-school.org
]
ip_addresses = [
    159.65.200.194,
    167.99.223.12
]
```