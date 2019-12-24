// Creating a hash map for for_each statement including the app service names, resource groups and location
locals{
    azure_webApps_data = { 
      for v in var.azure_webApps : 
        v.name => v
    }
}

// Load/Map the Azure KeyVault SSL Certificate with every WebApp
resource "azurerm_app_service_certificate" "SSLCert" {
  for_each = local.azure_webApps_data

  name                = var.your_domain  
  location            = each.value.location
  resource_group_name = each.value.resource_group
  key_vault_secret_id = data.azurerm_key_vault_secret.SSLcert.id

}

// Map the SSL certificate with the DNS hostname in every WebApp
resource "azurerm_app_service_custom_hostname_binding" "customDomain" {
  for_each = local.azure_webApps_data

  hostname            = var.your_domain 
  app_service_name    = each.value.name
  resource_group_name = each.value.resource_group
  ssl_state           = "SniEnabled"
  thumbprint          = azurerm_app_service_certificate.SSLCert[each.key].thumbprint

  depends_on = [
    azurerm_traffic_manager_endpoint.webAppTMEndpoint
  ]
}

// Add an Endpoint to TrafficManager for every WebApp the bot will be deployed to
resource "azurerm_traffic_manager_endpoint" "webAppTMEndpoint" {
  for_each = local.azure_webApps_data

  name                = each.value.name
  endpoint_status     = "Enabled" // In the first deployment step it will be created but deactivated
  resource_group_name = var.trafficmanager_rg
  profile_name        = var.trafficmanager_name
  type                = "azureEndpoints"
  target_resource_id  = data.azurerm_app_service.WebApps[each.key].id
}