# Configure AzureRM provider
provider "azurerm" {
  version = "~>1.36"
  skip_provider_registration = true
}

# Configure the Microsoft Azure Active Directory Provider
provider "azuread" {
  version = "~>0.7.0"
}

provider "random" {
  version = "~>2.2"
}

terraform {
  backend "azurerm" {
    container_name       = "tfstate"
    key                  = "geobot.terraform.tfstate"
  }
}