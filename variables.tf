variable "folder_id" {
    description = "GCP Organization ID"
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

variable "folder_id" {
  description = "Must be of the form google_folder.folder_id"
  type = string
}

variable "project_name" {
  description = "Project name."
  type        = string
}

variable "billing_account" {
  description = "Billing account id."
  type        = string
  default     = ""
}

variable "activate_apis" {
  description = "Service APIs to enable."
  type        = list(string)
variable "org_id" {
  description = "GCP Organization id."
  type = string 
  default = ""
}

variable requested_services {
  description = "Additional APIs to enable for your project"
  type = list(string)
}