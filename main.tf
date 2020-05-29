
terraform {
    required_version = ">= 0.12.0"
    required_providers {
        google = "3.5.0"
        random = "~> 2.2"
  }
}

provider "google" {
    region = var.region
    credentials = creds
    project = "andybaran-seedproject"
}

resource "random_id" "id" {
    byte_length = 4
    prefix = var.project_name
}

resource "google_project" "project" {
    name = var.project_name
    project_id = random_id.id.hex
    org_id = var.org_id
    folder_id = var.folder_id
    billing_account = var.billing_account
    auto_create_network = false
    
    lifecycle {
            prevent_destroy = true
    }
}

resource "google_project_service" "common_services" {
    for_each = toset([
        "compute.googleapis.com",
        "logging.googleapis.com",
        "monitoring.googleapis.com",
        "storage-component.googleapis.com",
    ])
    
    service = each.key
    project =  data.google_project.project.project_id
    disable_dependent_services = true
}

resource "google_project_service" "requested_services" {
    for_each = toset([${requested_services}])
    
    service = each.key
    project =  data.google_project.project.project_id
    disable_dependent_services = true
}


# We need compute engine api enabled before we can create networks
resource "google_compute_network" "provisioning-vpc" {

  depends_on = [google_project_service.common_services]
  
  name = "provisioning-vpc"
  project = data.google_project.project.project_id
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "provisioning-subnet" {
  name          = join(google_project.project,"-primary-subnet")
  ip_cidr_range = "10.10.0.0/16"
  project       = data.google_project.project.project_id
  region        = var.region
  network       = google_compute_network.provisioning-vpc.self_link
  secondary_ip_range {
    range_name    = join(google_project.project,"-secondary-range")
    ip_cidr_range = "192.168.10.0/24"
  }
}

resource "google_service_account" "admin_service_account" {
  account_id   = "admin-gcpkms"
  display_name = "Admin service account for GCP"
  project =  google_project.project.project_id
  depends_on = [google_project.project]
}

resource "google_project_iam_binding" {
    project = "google_project.project.project_id"
    role = "roles/owner"

    members = [
      "user: andy.baran@hashicorp.com",
      "user: google_service_account.admin_service_account.account_id"
    ]
}