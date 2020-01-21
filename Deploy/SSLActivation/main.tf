# Configure AzureRM provider
provider "azurerm" {
  version = "~>1.36"
  skip_provider_registration = true
}

terraform {
  backend "azurerm" {
    container_name       = "tfstate"
    key                  = "sslactivation.terraform.tfstate"
  }
}