
provider "google" {
  credentials = file("")
  project     = "project-id"
  region      = "us-central1"
}
