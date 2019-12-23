# // Creating a hash map for for_each statement including the bot region names as key and value
# locals{
#     azure_bot_regions = { for v in var.azure_bot_regions : v => v }
# }

# // Load/Map the Azure KeyVault SSL Certificate with every WebApp
# resource "azurerm_app_service_certificate" "TrafficManager" {
#   for_each = local.azure_bot_regions

#   name                = "SSL"
#   location            = azurerm_resource_group.Region[each.key].location
#   resource_group_name = azurerm_resource_group.Region[each.key].name
#   key_vault_secret_id = azurerm_key_vault_certificate.TrafficManager.secret_id

# }

# // Map the SSL certificate with the TrafficManager hostname in every WebApp
# resource "azurerm_app_service_custom_hostname_binding" "TrafficManager" {
#   for_each = local.azure_bot_regions

#   hostname            = var.dns_name
#   app_service_name    = azurerm_app_service.Region[each.key].name
#   resource_group_name = azurerm_resource_group.Region[each.key].name
#   ssl_state           = "SniEnabled"
#   thumbprint          = azurerm_app_service_certificate.TrafficManager[each.key].thumbprint
# }


// Upload and Register the SSL Certificate into KeyVault
# resource "azurerm_key_vault_certificate" "TrafficManager" {
#   name         = "TrafficManagerSSL"
#   key_vault_id = azurerm_key_vault.GeoBot.id

#   certificate {
#     contents = filebase64(var.pfx_certificate_file_location)
#     password = var.pfx_certificate_password
#   }

#   certificate_policy {
#     issuer_parameters {
#       name = "Unknown" // see https://github.com/terraform-providers/terraform-provider-azurerm/blob/master/examples/app-service-certificate/stored-in-keyvault/main.tf
#     }

#     key_properties {
#       exportable = true
#       key_size   = 2048
#       key_type   = "RSA"
#       reuse_key  = false
#     }

#     secret_properties {
#       content_type = "application/x-pkcs12"
#     }
#   }
# }