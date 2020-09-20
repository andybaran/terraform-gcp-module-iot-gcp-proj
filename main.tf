
terraform {
    required_version = ">= 0.12.0"
    required_providers {
        random = "~> 2.3"
        google = "~> 3.24.0"
    }
}

provider "google" {
    region = var.region
    credentials = var.creds
    project = "andybaran-seedproject"
}

resource "random_id" "id" {
    byte_length = 4
    prefix = var.project_name
}

# Generate a random project name
resource "google_project" "project" {
    name = var.project_name
    project_id = random_id.id.hex
    folder_id = var.folder_id
    billing_account = var.billing_account
    auto_create_network = true
    
}

# Enable the most common API's in our random project
resource "google_project_service" "common_services" {
    for_each = toset([
        "compute.googleapis.com",
        "logging.googleapis.com",
        "monitoring.googleapis.com",
        "storage-component.googleapis.com",
    ])
    
    service = each.key
    project =  google_project.project.project_id
    disable_dependent_services = true
  }

# Enable addtional services as requested by the invocation of this module
resource "google_project_service" "requested_services" {
    for_each = toset(var.requested_services)
    service = each.key
    project =  google_project.project.project_id
    disable_dependent_services = true
}

# We need compute engine api enabled before we can create networks
resource "google_compute_network" "provisioning-vpc" {

  depends_on = [google_project_service.common_services]
  
  name = "provisioning-vpc"
  project = google_project.project.project_id
  auto_create_subnetworks = true
}

# Lets create some networks
resource "google_compute_subnetwork" "provisioning-net" {
  name          = join("",[google_project.project.name,"-",var.network_name])
  ip_cidr_range = "10.10.0.0/16"
  project       = google_project.project.project_id
  region        = var.region
  network       = google_compute_network.provisioning-vpc.self_link
  secondary_ip_range {
    range_name    = join("",[google_project.project.name,"-",var.network_name,"-secondary-range"])
    ip_cidr_range = "192.168.10.0/24"
  }
}


# Create admin service account and make token available
resource "google_service_account" "admin_service_account" {
  account_id   = "admin-service-account"
  display_name = "Admin service account for GCP"
  project =  google_project.project.project_id
  depends_on = [google_project.project]
}

resource "google_service_account_key" "sa_token" {
  service_account_id = google_service_account.admin_service_account.name
}

resource "google_project_iam_member" "proj_owners_serviceAccount" {
    project = google_project.project.id
    role = "roles/owner"
    member = "serviceAccount:${google_service_account.admin_service_account.email}"
}

# Give a person admin access since we're not deploying this into production
resource "google_project_iam_member" "proj_owners_adminUser" {
    project = google_project.project.id
    role = "roles/owner"
    member = join("",["user:",var.additional_admin])
}
