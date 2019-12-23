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
    { "name" = instance.name, "resource_group" = instance.resource_group_name }
  ]
}

// This output will be used for subsequent destroy scripts
output "trafficManager" {
  value = {
       "name" = azurerm_traffic_manager_profile.Bot.name, 
       "resource_group" = azurerm_traffic_manager_profile.Bot.resource_group_name,
       "id" = azurerm_traffic_manager_profile.Bot.id
  }
}

// This output will be used for subsequent destroy scripts
output "keyVault" {
  value = {
       "name" = azurerm_key_vault.GeoBot.name, 
       "resource_group" = azurerm_key_vault.GeoBot.resource_group_name 
  }
}