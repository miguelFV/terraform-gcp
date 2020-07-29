provider "google" {
  credentials = file("gcp-terraform-init.json")
  project     = "gcp-terraform-init"
  region      = "us-central1"
}


//creacion de bucket
resource "google_storage_bucket" "first_bucket" {
  name          = "fs-storage-cb-sh"
  location      = "US"
  force_destroy = true
}

//Source code para ejecucion de funcion
resource "google_storage_bucket_object" "sc_load_table_a" {
  name   = "sourceCode.zip"
  bucket = google_storage_bucket.first_bucket.name
  source = "./source-code/sourceCode.zip"
}

//creacion de cloud function con trigger de carga en bucket 
resource "google_cloudfunctions_function" "load_function_data" {
  name        = "function-test-load"
  description = "Function for load data into BigQuery after load file csv"
  runtime     = "java11"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.first_bucket.name
  source_archive_object = google_storage_bucket_object.sc_load_table_a.name
  event_trigger  {
    event_type  = "google.storage.object.finalize"
    resource     = google_storage_bucket.first_bucket.name
  }
  entry_point           = "functions.LoadData"
}

//creation dataset for bigQuery
resource "google_bigquery_dataset" "gcp_data_model_a" {
  dataset_id                  = "gcp_schema_bigquery"
  friendly_name               = "Dataset para carga de archivos"
  description                 = "Dataset para cargar la infomracion de los 18 archivos"
  location                    = "US"
}

//table for configure doc-table upload
resource "google_bigquery_table" "gcp_data_file_table" {
  dataset_id = google_bigquery_dataset.gcp_data_model_a.dataset_id
  table_id   = "rel_file_table"
   schema = <<EOF
[
  {
    "name": "table_name",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The name of the table"
  },
  {
    "name": "file_to_upload",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The name of the file for upload"
  }
]
EOF
}

//table for test upload data
resource "google_bigquery_table" "gcp_data_file_table_a" {
  dataset_id = google_bigquery_dataset.gcp_data_model_a.dataset_id
  table_id   = "gcp_table_a"
}

/********************************************
Compute engine Cluster
********************************************/



//template for create GCE other's
resource "google_compute_instance_template" "gcp_template_airflow" {
  name           = "gcp-template-airflow"
  machine_type   = "n1-standard-1"
  can_ip_forward = false

  tags = ["http-airflow-ingress"]

  disk {
    source_image = "debian-cloud/debian-10"
  }

  network_interface {
    network = "default"
     access_config {
      # Include this section to give the VM an external ip address
    }
  }
  service_account {
    scopes = ["userinfo-email", "compute-rw", "storage-ro"]
  }
  //it's very important the 
   metadata_startup_script = <<-EOF
   #! /bin/bash
    sudo su -
    apt-get -y update 
    apt install -y python
    python --version
    apt-get -y install software-properties-common
    apt -y install python-pip
    export AIRFLOW_HOME=~/airflow
    # install from pypi using pip
    pip install 'apache-airflow[gcp]'
    # initialize the database
    airflow initdb
    # start the web server, default port is 8080
    airflow webserver -p 8080
    EOF
}
resource "google_compute_firewall" "airflow-rule" {
  name          = "gcp-airflow-ingress"
  network       = "default"
  target_tags   = ["http-airflow-ingress"]

  source_ranges = [
    "0.0.0.0/0"
  ]

  allow {
    protocol    = "tcp"
    ports       = ["8080"]
  }
}
resource "google_compute_target_pool" "gcp_target_airflow" {
  name = "gcp-target-pool-airflow"
}
resource "google_compute_instance_group_manager" "gcp_group_manager_airflow" {
  name = "gcp-group-manager-airflow"
  zone = "us-central1-f"

  version {
    instance_template  = google_compute_instance_template.gcp_template_airflow.id
    name               = "primary"
  }

  target_pools       = [google_compute_target_pool.gcp_target_airflow.id]
  base_instance_name = "ins-airflow"
}

resource "google_compute_autoscaler" "gcp_auto_scaler_airflow" {
  name   = "gcp-auto-scaler-airflow"
  zone   = "us-central1-f"
  target = google_compute_instance_group_manager.gcp_group_manager_airflow.id

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = 1
    cooldown_period = 60

    cpu_utilization {
      target = 0.5
    }
  }
}







