// KeyVault Name
variable "keyVault_name" {
}

// KeyVault Resource Group
variable "keyVault_rg" {
}

// eMail to be registered at Let's Encrypt
variable "your_certificate_email" {

}

// DNS Name to create SSL Certificate
variable "your_domain" {

}

// Traffic Manager Profile Name
variable "trafficmanager_name" {
}

// Traffic Manager Profile Resource Group
variable "trafficmanager_rg" {
}

// Resource Group for ACI
variable "aci_rg" {
}

// Location for ACI
variable "aci_location" {
}

// DNS Label for ACI
resource "random_string" "dnslabel" {
  length = 10
  special = false
  upper = false
}

// KeyVault SSL Cert Name
variable "keyVault_cert_name" {
  default = "SSLcert"
}

// ACI Container image
variable "aci_image" {
  default = "h2floh/letsencrypt:keyvault"
}

// Use Staging or Production of Let's Encrypt (0 = Staging, 1 = Production)
variable "production" {
  default = "1"
}

