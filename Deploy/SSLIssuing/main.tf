# Configure AzureRM provider
provider "azurerm" {
  version = "~>1.36"
  skip_provider_registration = true
}

provider "random" {
  version = "~>2.2"
}

terraform {
  //backend "azurerm" {
  //}
}