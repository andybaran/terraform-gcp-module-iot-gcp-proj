variable "folder_id" {
    description = "GCP Organization ID"
}

variable "project_name" {
    description = "Google Project Name Descriptor (not project ID)"
}

variable "region" {
    description = "GCP Region"
}

variable "creds" {
  description = "GCP account file contents"
}

variable "main_service_account" {
    description = "Service account used to stand run TF"
}

variable "zone" {
    description = "GCP Zone"
}

variable "parent" {
  description = "The resource name of the parent Folder or Organization. Must be of the form folders/folder_id or organizations/org_id."
  type        = string
}

variable "prefix" {
  description = "Prefix used to generate project id and name."
  type        = string
}

variable "name" {
  description = "Project name and id suffix."
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
  default     = []
}

variable "owners" {
  description = "Optional list of IAM-format members to set as project owners."
  type        = list(string)
  default     = []
}

variable "editors" {
  description = "Optional list of IAM-format members to set as project editor."
  type        = list(string)
  default     = []
}

variable "viewers" {
  description = "Optional list of IAM-format members to set as project viewers."
  type        = list(string)
  default     = []
}

variable "lien_reason" {
  description = "If non-empty, creates a project lien with this description."
  type        = string
  default     = ""
}

variable "oslogin" {
  description = "Enable oslogin."
  type        = bool
  default     = false
}

variable "oslogin_admins" {
  description = "List of IAM-format members that will get OS Login admin role."
  type        = list(string)
  default     = []
}

variable "oslogin_users" {
  description = "List of IAM-format members that will get OS Login user role."
  type        = list(string)
  default     = []
}

# TODO: revert to a single map once the following issue is fixed
# https://github.com/hashicorp/terraform/issues/12570

variable "extra_bindings_roles" {
  description = "List of roles for additional IAM bindings, pair with members list below."
  type        = list(string)
  default     = []
}

variable "extra_bindings_members" {
  description = "List of comma-delimited IAM-format members for additional IAM bindings, one item per role."
  type        = list(string)
  default     = []
}

variable "auto_create_network" {
  description = "Whether to create the default network for the project"
  type        = bool
  default     = false
}

variable "custom_roles" {
  description = "Map of role name => comma-delimited list of permissions to create in this project."
  type        = map(string)
  default     = {}
}

variable "gce_service_account_roles" {
  description = "List of project id=>role to assign to the default GCE service account."
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Resource labels."
  type        = map(string)
  default     = {}
}