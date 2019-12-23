// Current connection/authorization information for Terraform AzureRM provider
data "azurerm_client_config" "current" {}

data "azurerm_key_vault" "SSLVault" {
  name                = var.keyVault_name
  resource_group_name = var.keyVault_rg
}