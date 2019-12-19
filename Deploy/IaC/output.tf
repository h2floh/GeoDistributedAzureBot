
output "luisAccounts" {
  value = [
    for instance in azurerm_cognitive_account.LUISRegion:
    { "name" = instance.name, "resource_group" = instance.resource_group_name }
  ]
}

output "webAppAccounts" {
  value = [
    for instance in azurerm_app_service.Region:
    { "name" = instance.name, "resource_group" = instance.resource_group_name }
  ]
}

output "trafficManager" {
  value = {
       "name" = azurerm_traffic_manager_profile.Bot.name, 
       "resource_group" = azurerm_traffic_manager_profile.Bot.resource_group_name 
  }
}