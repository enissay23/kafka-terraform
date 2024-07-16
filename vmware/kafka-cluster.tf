# Define the provider (vSphere)
provider "vsphere" {
  user           = "username"
  password       = "password"
  vsphere_server = "vcenter_server_address"

  allow_unverified_ssl = true
}
