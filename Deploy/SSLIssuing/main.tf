# Configure AzureRM provider
provider "azurerm" {
  version = "~>1.36"
  skip_provider_registration = true
}

# Configure the Microsoft Azure Active Directory Provider
provider "azuread" {
  version = "~>0.3.0"
}

provider "random" {
  version = "~>0"
}

terraform {
  //backend "azurerm" {
  //}
}