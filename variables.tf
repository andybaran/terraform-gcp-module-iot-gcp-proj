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

/*variable "vault-ip" {
    description = "IP address of vault server"
}

variable "bq_dataset" {
    description = "BigQuery Dataset"
}

variable "bq_table" {
    description = "BigQuery Table"
}

variable "pub_sub_sub" {
    description = "Pub/Sub Subscription"
}*/
