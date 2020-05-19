terraform {
    required_version = ">= 0.12.0"
    required_providers {
        google = "3.5.0"
        random = "~> 2.2"
  }
}

/*module "kms" {
    source = "./kms"
    account_file_path = var.account_file_path
    gcloud-zone = "us-central1-c"
    gcloud-project = google_project.project.project_id
    main_service_account = "terraform@factory-263411.iam.gserviceaccount.com"
    vault_url = "https://releases.hashicorp.com/vault/1.3.2/vault_1.3.2_linux_amd64.zip"
    vault_kms_service_account = "${google_service_account.vault_kms_service_account.email}"
    kms_admin_service_account = trimprefix("${google_service_account_iam_binding.token-creator-iam.service_account_id}", "projects/${google_project.project.project_id}/serviceAccounts/")
    vault-ip = "10.10.10.10"
}

module "bq" {
    source ="./bq"
    account_file_path = var.account_file_path
    gcloud-project = google_project.project.project_id
    bq_dataset = var.bq_dataset
    bq_table = var.bq_table
}

module "iot-core_and_pub-sub" {
    source ="./iot-core_and_pub-sub"
    account_file_path = var.account_file_path
    zone = "us-central1-c"
    gcloud-project = google_project.project.project_id
    pub_sub_sub = var.pub_sub_sub
}

module "dataflow" {
    source ="./dataflow"
    account_file_path = var.account_file_path
    gcloud-project = google_project.project.project_id
    random_id = random_id.id.hex
    bq_table = join(".",[var.bq_dataset, var.bq_table])
    pub_sub_sub = var.pub_sub_sub
    zone = var.zone
}*/

provider "google" {
    region = var.region
    credentials = var.creds
}

resource "random_id" "id" {
    byte_length = 4
    prefix = var.project_name
}

# Create our obd2<random #> project where resources will exist

   
resource "google_project" "project" {
    name = var.project_name
    project_id = random_id.id.hex
    //billing_account = var.billing_account
    folder_id = var.folder_id
    lifecycle {
            prevent_destroy = true   // If we destory and create projects each run we're going to quickly hit the quota limit
    }
}

# Enable common API's for the project
resource "google_project_service" "common_services" {
    for_each = toset([
        "compute.googleapis.com",
        "dataflow.googleapis.com",
        "logging.googleapis.com",
        "monitoring.googleapis.com",
        "storage-component.googleapis.com",
    ])
    
    service = each.key
    project =  google_project.project.project_id
    disable_dependent_services = true
}


# We need compute engine api enabled before we can create networks
resource "google_compute_network" "provisioning-vpc" {

  depends_on = [google_project_service.common_services]
  
  name = "provisioning-vpc"
  project = google_project.project.project_id
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "provisioning-subnet" {
  name          = "provisioning-subnet"
  ip_cidr_range = "10.10.0.0/16"
  project       = google_project.project.project_id
  region        = var.region
  network       = google_compute_network.provisioning-vpc.self_link
  secondary_ip_range {
    range_name    = "tf-test-secondary-range-update1"
    ip_cidr_range = "192.168.10.0/24"
  }
}





# Set metadata on the obd2 project
# os-login is enabled for faster SSH access via cloud console
/*resource "google_compute_project_metadata" "default" {
    project =  google_project.project.project_id 
    
}*/

resource "google_service_account" "kms_admin_service_account" {
  account_id   = "admin-gcpkms"
  display_name = "Admin service account for GCP KMS"
  project =  google_project.project.project_id
  #depends_on = [google_project.project]
}

resource "google_service_account" "vault_kms_service_account" {
  account_id   = "vault-gcpkms"
  display_name = "Vault KMS for auto-unseal"
  project =  google_project.project.project_id
  #depends_on = [google_project.project]
}

resource "google_service_account_iam_binding" "token-creator-iam" {
    service_account_id = "projects/${google_project.project.project_id}/serviceAccounts/${google_service_account.kms_admin_service_account.email}"
    role = "roles/iam.serviceAccountTokenCreator"
    members = [
        "serviceAccount:${var.main_service_account}",
    ]

    # Ths seems wrong? --> depends_on = [google_service_account_iam_binding.token-creator-iam]
    depends_on = [google_service_account.kms_admin_service_account, google_service_account.vault_kms_service_account]
}

output "project_id" {
    value =  google_project.project.project_id
}