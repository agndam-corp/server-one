# Terraform backend configuration for local state storage
terraform {
  backend "local" {
    # State file will be stored locally in terraform.tfstate
    # in the same directory as this configuration.
  }
}