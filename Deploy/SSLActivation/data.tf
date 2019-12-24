data "azurerm_app_service" "WebApps" {
  for_each = local.azure_webApps_data

  name                = each.value.name
  resource_group_name = each.value.resource_group
}

data "azurerm_key_vault" "SSLVault" {
  name                = var.keyVault_name
  resource_group_name = var.keyVault_rg
}

data "azurerm_key_vault_secret" "SSLcert" {
  name         = var.keyVault_cert_name
  key_vault_id = data.azurerm_key_vault.SSLVault.id
}