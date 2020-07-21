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


resource "google_storage_bucket_object" "sc_load_table_a" {
  name   = "source-code-function-upload-tables"
  bucket = google_storage_bucket.first_bucket.name
  source = "./source-code/sourceCode.zip"
}

//creacion de cloud function con trigger de carga en bucket 




resource "google_bigquery_dataset" "gcp_data_model_a" {
  dataset_id                  = "gcp_schema_bigquery"
  friendly_name               = "Dataset para carga de archivos"
  description                 = "Dataset para cargar la infomracion de los 18 archivos"
  location                    = "US"
}


resource "google_bigquery_table" "gcp_tabla_a" {
  dataset_id = google_bigquery_dataset.gcp_data_model_a.dataset_id
  table_id   = "gcp_table_a"
}

