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

module "project-iam-bindings" {
  source          = "terraform-google-modules/iam/google//modules/projects_iam"
  projects = ["module.project-factory_example_fabric_project.project_id"]

  bindings = {
    "roles/owner" = [
      "user:andy.baran@hashicorp.com",
    ]
  }
}


resource "random_string" "prefix" {
  length  = 30 - length(var.name) - 1
  upper   = false
  number  = false
  special = false
}

// ************************************************************   
// IoT Core
// ************************************************************  

resource "google_cloudiot_registry" "iot_registry" { 
    depends_on = [google_pubsub_topic.pst_diagnostic_data]
    
    name = "obd2_devices"
    project = module.project-factory_example_fabric_project.project_id
    event_notification_configs {
        pubsub_topic_name = "projects/${module.project-factory_example_fabric_project.project_id}/topics/diagnostic_data"
    }
    mqtt_config = {
        mqtt_enabled_state = "MQTT_ENABLED"
    }
    http_config = {
        http_enabled_state = "HTTP_ENABLED"
    }
}

// ************************************************************   
// Cloud Pub Sub
// ************************************************************  

resource "google_pubsub_topic" "pst_diagnostic_data" {
    name = "diagnostic_data"
    project = module.project-factory_example_fabric_project.project_id
}

resource "google_pubsub_subscription" "pst_diagnostic_data_sub" {
    depends_on = [google_pubsub_topic.pst_diagnostic_data]
    name = var.pub_sub_sub
    project = module.project-factory_example_fabric_project.project_id
    topic = google_pubsub_topic.pst_diagnostic_data.name
    
    message_retention_duration = "86400s"
    retain_acked_messages = true
}

// ************************************************************   
// BigQuery Dataset & Table
// ************************************************************   

resource "google_bigquery_dataset" "obd2info" {
    project = module.project-factory_example_fabric_project.project_id
    dataset_id = var.bq_dataset
    friendly_name = var.bq_dataset
    description = "Dataset containing tables related to OBD2 diagnostic logs"
    location = "US"

   /* access {
        role = "projects/${module.project-factory_example_fabric_project.project_id}/roles/bigquery.admin"
        special_group = "projectOwners"
    }
    access {
        role = "projects/${module.project-factory_example_fabric_project.project_id}/roles/bigquery.dataEditor"
        special_group = "projectWriters"
    }
    access {
        role = "projects/${module.project-factory_example_fabric_project.project_id}/roles/bigquery.dataViewer"
        special_group = "projectReaders"
    }
    access {
        role = "projects/${module.project-factory_example_fabric_project.project_id}/roles/bigquery.jobUser"
        special_group = "projectWriters"
    }
    access {
        role = "projects/${module.project-factory_example_fabric_project.project_id}/bigquery.jobUser"
        special_group = "projectReaders"
    }*/
}

resource "google_bigquery_table" "obd2logging" {
    project = module.project-factory_example_fabric_project.project_id
    dataset_id = google_bigquery_dataset.obd2info.dataset_id
    table_id = var.bq_table

    schema = <<EOF
    [
    {
        "mode": "NULLABLE", 
        "name": "VIN", 
        "type": "STRING"
      }, 
      {
        "mode": "NULLABLE", 
        "name": "collectedAt", 
        "type": "STRING"
      }, 
      {
        "mode": "NULLABLE", 
        "name": "PID_RPM", 
        "type": "FLOAT"
      }, 
      {
        "mode": "NULLABLE", 
        "name": "PID_ENGINE_LOAD", 
        "type": "FLOAT"
      }, 
      {
        "mode": "NULLABLE", 
        "name": "PID_COOLANT_TEMP", 
        "type": "FLOAT"
      }, 
      {
        "mode": "NULLABLE", 
        "name": "PID_ABSOLUTE_ENGINE_LOAD", 
        "type": "FLOAT"
      }, 
      {
        "mode": "NULLABLE", 
        "name": "PID_TIMING_ADVANCE", 
        "type": "FLOAT"
      }, 
      {
        "mode": "NULLABLE", 
        "name": "PID_ENGINE_OIL_TEMP", 
        "type": "FLOAT"
      }, 
      {
        "mode": "NULLABLE", 
        "name": "PID_ENGINE_TORQUE_PERCENTAGE", 
        "type": "FLOAT"
      }, 
      {
        "mode": "NULLABLE",
        "name": "PID_ENGINE_REF_TORQUE", 
        "type": "FLOAT"
      }, 
      {
        "mode": "NULLABLE",   
        "name": "PID_INTAKE_TEMP", 
        "type": "FLOAT"
      },
      {
        "mode": "NULLABLE",   
        "name": "PID_MAF_FLOW", 
        "type": "FLOAT"
      },
      {
        "mode": "NULLABLE", 
        "name": "PID_BAROMETRIC", 
        "type": "FLOAT"
      }, 
      {
        "mode": "NULLABLE",  
        "name": "PID_SPEED", 
        "type": "FLOAT"
      }, 
      {
        "mode": "NULLABLE",   
        "name": "PID_RUNTIME", 
        "type": "FLOAT"
      },
      {
        "mode": "NULLABLE",   
        "name": "PID_DISTANCE", 
        "type": "FLOAT"
      }
    ]
    EOF


}

// ************************************************************   
// Dataflow Job (PubSub --> BigQuery Table)
// ************************************************************   

resource "google_storage_bucket" "dataflow_bucket" {
  project = module.project-factory_example_fabric_project.project_id
  name = join("",["dataflow-", module.project-factory_example_fabric_project.project_id])
  location = "US"
}

resource "google_dataflow_job" "collect_OBD2_data" {
  project = module.project-factory_example_fabric_project.project_id
  name              = "OBD2-Data-Collection"
  zone = var.zone
  template_gcs_path = "gs://dataflow-templates/latest/PubSub_Subscription_to_BigQuery"
  temp_gcs_location = "${google_storage_bucket.dataflow_bucket.url}/tmp_dir"
  parameters = {
    inputSubscription = "projects/${module.project-factory_example_fabric_project.project_id}/subscriptions/${var.pub_sub_sub}"
    outputTableSpec = "${module.project-factory_example_fabric_project.project_id}:${var.bq_table}"
    #flexRSGoal = "COST_OPTIMIZED"
  }
}