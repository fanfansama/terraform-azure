# terraform-azure

## Dependencies 
- terraform >= 0.12
- azure CLI (dans le PATH)

## Before Applying terraform
- login to azure : `az login`

## Terraform
- `cd ./envs/poc`
- `terraform init` in order to get potential dependencies
- `terraform apply`, then type `yes`
- if something fails, `terraform apply` is idempotent so you can re-run it safely

