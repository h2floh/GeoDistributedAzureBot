
output "luisAccounts" {
  value = [
    for instance in azurerm_cognitive_account.LUISRegion:
    { "name" = instance.name, "resource_group" = instance.resource_group_name }
  ]
}