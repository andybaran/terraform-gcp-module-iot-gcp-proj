terraform {
    required_version = ">= 0.12.0"
}

provider "google" {
  credentials = var.creds
}

module "project-factory_example_fabric_project" {
  source          = "terraform-google-modules/project-factory/google//modules/fabric-project"
  version = "8.0.1"
  activate_apis   = var.activate_apis
  billing_account = var.billing_account
  name            = var.name
  owners          = var.owners
  parent          = var.parent
  prefix          = var.prefix
  oslogin         = true
}

resource "random_string" "prefix" {
  length  = 30 - length(var.name) - 1
  upper   = false
  number  = false
  special = false
}