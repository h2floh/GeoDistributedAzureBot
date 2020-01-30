// This output will be used for subsequent deployment scripts (LUIS part)
output "luisAccounts" {
  value = [
    for instance in azurerm_cognitive_account.LUISRegion:
    { "name" = instance.name, "resource_group" = instance.resource_group_name }
  ]
}

// This output will be used for subsequent deployment scripts (Bot WebApp part)
output "webAppAccounts" {
  value = [
    for instance in azurerm_app_service.Region:
    { name = instance.name, resource_group = instance.resource_group_name, location = instance.location }
  ]
}

// This output will be used for subsequent destroy scripts
output "keyVault" {
  value = {
       "name" = azurerm_key_vault.GeoBot.name, 
       "resource_group" = azurerm_key_vault.GeoBot.resource_group_name,
       "location" = azurerm_key_vault.GeoBot.location
  }
}

// This output will be used for subsequent destroy scripts
output "bot" {
  value = {
       "name" = azurerm_bot_channels_registration.GeoBot.name, 
       "resource_group" = azurerm_bot_channels_registration.GeoBot.resource_group_name
  }
}