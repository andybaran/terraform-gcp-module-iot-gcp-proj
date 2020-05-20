terraform {
    required_version = ">= 0.12.0"
    required_providers {
        google = "3.22.0"
        random = "~> 2.2"
  }
}

locals {
  prefix = var.prefix == "" ? random_string.prefix.result : var.prefix
}

resource "random_string" "prefix" {
  length  = 30 - length(var.name) - 1
  upper   = false
  number  = false
  special = false
}

module "fabric-project" {
  source          = "../../modules/fabric-project"
  activate_apis   = var.activate_apis
  billing_account = var.billing_account
  name            = var.name
  owners          = var.owners
  parent          = var.parent
  prefix          = local.prefix
}