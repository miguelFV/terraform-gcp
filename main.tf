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

//creation schema for bigQuery the tables
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
    "description": "The name fo the table"
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

//table for configure doc-table upload
resource "google_bigquery_table" "gcp_data_file_table_a" {
  dataset_id = google_bigquery_dataset.gcp_data_model_a.dataset_id
  table_id   = "gcp_table_a"
}

