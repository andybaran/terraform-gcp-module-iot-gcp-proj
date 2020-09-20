variable "folder_id" {
    description = "GCP Organization ID"
    type = string
}

variable "region" {
    description = "GCP Region"
}

variable "creds" {
  description = "GCP account file contents"
}

variable "zone" {
    description = "GCP Zone"
}

variable "project_name" {
  description = "Project name."
  type        = string
}

variable "billing_account" {
  description = "Billing account id."
  type        = string
}

variable "requested_services" {
  description = "Additional APIs to enable for your project"
  type = list(string)
}

variable "additional_admin" {
  description = "Additional admin to be given access to this project. Typically an actual person."
  type = string
}

variable "network_name" {
  description = "A name for your network"
  type = string
}
