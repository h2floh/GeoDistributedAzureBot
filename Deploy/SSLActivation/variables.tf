// KeyVault Name
variable "keyVault_name" {
}

// KeyVault Resource Group
variable "keyVault_rg" {
}

// Traffic Manager Profile Name
variable "trafficmanager_name" {
}

// Traffic Manager Profile Resource Group
variable "trafficmanager_rg" {
}

// DNS Name to create SSL Certificate
variable "your_domain" {
}

// KeyVault SSL Cert Name
variable "keyVault_cert_name" {
  default = "SSLcert"
}

// WebApp data list (required for SSL mapping)
variable "azure_webApps" {
  type = list(object({
    name = string
    resource_group = string
    location = string
  }))
  # default = [ 
  #  "koreacentralmygeodistributedbot|rg-geobot-region-koreacentral|koreacentral",
  #  "southeastasiamygeodistributedbot|rg-geobot-region-southeastasia|southeastasia"
  #  ]
}