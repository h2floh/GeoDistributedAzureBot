
locals{
    azure_bot_regions = { for v in var.azure_bot_regions : v.name => v.name }
}

resource "azurerm_resource_group" "Region" {
  for_each = local.azure_bot_regions

  name     = "rg-geobot-region-${each.key}"
  location = each.key

  tags = {
    environment = var.environment,
    region = each.key
  }
}

resource "azurerm_traffic_manager_endpoint" "Region" {
  for_each = local.azure_bot_regions

  name                = each.key
  resource_group_name = azurerm_traffic_manager_profile.Bot.resource_group_name
  profile_name        = azurerm_traffic_manager_profile.Bot.name
  target              = azurerm_app_service.Region[each.key].default_site_hostname
  type                = "externalEndpoints"
  endpoint_location   = azurerm_resource_group.Region[each.key].location
}

resource "azurerm_app_service_plan" "Region" {
  for_each = local.azure_bot_regions

  name                = "${each.key}${var.bot_name}Plan"
  location            = azurerm_resource_group.Region[each.key].location
  resource_group_name = azurerm_resource_group.Region[each.key].name

  sku {
    tier = "Basic"
    size = "B1"
  }
}

resource "azurerm_app_service" "Region" {
  for_each = local.azure_bot_regions

  name                = "${each.key}${var.bot_name}"
  location            = azurerm_app_service_plan.Region[each.key].location
  resource_group_name = azurerm_resource_group.Region[each.key].name
  app_service_plan_id = azurerm_app_service_plan.Region[each.key].id
  https_only          = "true"

  site_config {
    always_on = "true"
  }

  app_settings = {
    region       = each.key
    KeyVaultName = azurerm_key_vault.GeoBot.name
  }

  identity {
      type = "SystemAssigned"
  }
}

resource "azurerm_key_vault_access_policy" "Region" {
    for_each = local.azure_bot_regions

    key_vault_id = azurerm_key_vault.GeoBot.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_app_service.Region[each.key].identity[0].principal_id

    secret_permissions = [
        "get",
        "list"
    ]
}

resource "azurerm_key_vault_secret" "LUISKeyRegion" {
  for_each = local.azure_bot_regions

  name         = "LUISAPIKey${each.key}"
  value        = azurerm_cognitive_account.LUISRegion[each.key].primary_access_key
  key_vault_id = azurerm_key_vault.GeoBot.id
}

resource "azurerm_key_vault_secret" "LUISEndpointRegionA" {
  for_each = local.azure_bot_regions

  name         = "LUISAPIHostName${each.key}"
  value        = azurerm_cognitive_account.LUISRegion[each.key].endpoint
  key_vault_id = azurerm_key_vault.GeoBot.id
}

resource "azurerm_cognitive_account" "LUISRegion" {
  for_each = local.azure_bot_regions

  name                = "${var.bot_name}LUIS${each.key}"
  location            = azurerm_resource_group.Region[each.key].location
  resource_group_name = azurerm_resource_group.Region[each.key].name
  kind                = "LUIS"

  sku {
    name = "S0"
    tier = "Standard"
  }
}