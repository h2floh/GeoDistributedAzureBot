resource "azurerm_resource_group" "Bot" {
  name     = "rg-geobot-global"
  location = var.global_region

  tags = {
    environment = var.environment,
    region = "global"
  }
}

resource "azurerm_traffic_manager_profile" "Bot" {
  name                = var.bot_name
  resource_group_name = azurerm_resource_group.Bot.name

  traffic_routing_method = "Performance"

  dns_config {
    relative_name = var.bot_name
    ttl           = 100
  }

  monitor_config {
    protocol                     = "https"
    port                         = 443
    path                         = "/"
    interval_in_seconds          = 30
    timeout_in_seconds           = 9
    tolerated_number_of_failures = 3
  }

  tags = {
    environment = var.environment,
    region = "global"
  }
}

resource "azurerm_application_insights" "Bot" {
  name                = var.bot_name
  location            = azurerm_resource_group.Bot.location
  resource_group_name = azurerm_resource_group.Bot.name
  application_type    = "web"
}

resource "azurerm_bot_channels_registration" "GeoDistributedBot" {
  name                = var.bot_name
  location            = "global"
  resource_group_name = azurerm_resource_group.Bot.name
  sku                 = var.bot_sku
  microsoft_app_id    = var.microsoft_app_id
  endpoint            = "https://${azurerm_traffic_manager_profile.Bot.fqdn}/api/messages" 
  developer_app_insights_application_id = azurerm_application_insights.Bot.app_id
  developer_app_insights_key = azurerm_application_insights.Bot.instrumentation_key
}

resource "azurerm_key_vault" "GeoBot" {
  name                        = var.bot_name
  location                    = azurerm_resource_group.Bot.location
  resource_group_name         = azurerm_resource_group.Bot.name
  enabled_for_disk_encryption = false
  tenant_id                   = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"
  
  network_acls {
    default_action = "Allow"
    bypass = "None"
  }
}

resource "azurerm_key_vault_access_policy" "currentClient" {
    key_vault_id = azurerm_key_vault.GeoBot.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
        "get",
        "set",
        "delete",
        "list"
    ]

    certificate_permissions = [
        "get",
        "import",
        "delete",
        "list"
    ]
}

resource "azurerm_key_vault_access_policy" "webAppPrincipal" {
    key_vault_id = azurerm_key_vault.GeoBot.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = var.magic_resource_principal_object_id

    secret_permissions = [
        "get",
    ]

    certificate_permissions = [
        "get",
    ]
}

resource "azurerm_key_vault_secret" "MSAppId" {
  name         = "MicrosoftAppId"
  value        = var.microsoft_app_id
  key_vault_id = azurerm_key_vault.GeoBot.id
}

resource "azurerm_key_vault_secret" "MSAppSecret" {
  name         = "MicrosoftAppPassword"
  value        = var.microsoft_app_secret
  key_vault_id = azurerm_key_vault.GeoBot.id
}

resource "azurerm_key_vault_secret" "AppInsightId" {
  name         = "AppInsightId"
  value        = azurerm_application_insights.Bot.app_id
  key_vault_id = azurerm_key_vault.GeoBot.id
}

resource "azurerm_key_vault_secret" "AppInsightInstrumentationKey" {
  name         = "ApplicationInsights--InstrumentationKey"
  value        = azurerm_application_insights.Bot.instrumentation_key
  key_vault_id = azurerm_key_vault.GeoBot.id
}

resource "azurerm_key_vault_secret" "LUISAuthoringKey" {
  name         = "LUISAuthoringKey"
  value        = azurerm_cognitive_account.LUISAuthoring.primary_access_key
  key_vault_id = azurerm_key_vault.GeoBot.id
}

resource "azurerm_key_vault_secret" "LUISAuthoringEndpoint" {
  name         = "LUISAuthoringEndpoint"
  value        = azurerm_cognitive_account.LUISAuthoring.endpoint
  key_vault_id = azurerm_key_vault.GeoBot.id
}

resource "azurerm_cognitive_account" "LUISAuthoring" {
  name                = "${var.bot_name}LUISAuthoring"
  location            = "westus" //see https://docs.microsoft.com/en-us/azure/cognitive-services/luis/luis-reference-regions
  resource_group_name = azurerm_resource_group.Bot.name
  kind                = "LUIS.Authoring"

  sku {
    name = "F0" // S0 not available
    tier = "Free" // Standard not available
  }
}

resource "azurerm_key_vault_secret" "CosmosDBEndpoint" {
  name         = "CosmosDBStateStoreEndpoint"
  value        = azurerm_cosmosdb_account.botdb.endpoint
  key_vault_id = azurerm_key_vault.GeoBot.id
}

resource "azurerm_key_vault_secret" "CosmosDBKey" {
  name         = "CosmosDBStateStoreKey"
  value        = azurerm_cosmosdb_account.botdb.primary_master_key
  key_vault_id = azurerm_key_vault.GeoBot.id
}

resource "azurerm_key_vault_secret" "CosmosDBDatabase" {
  name         = "CosmosDBStateStoreDatabaseId"
  value        = azurerm_cosmosdb_sql_database.botdb.name
  key_vault_id = azurerm_key_vault.GeoBot.id
}

resource "azurerm_key_vault_secret" "CosmosDBCollection" {
  name         = "CosmosDBStateStoreCollectionId"
  value        = azurerm_cosmosdb_sql_container.botdb.name
  key_vault_id = azurerm_key_vault.GeoBot.id
}

resource "azurerm_cosmosdb_account" "botdb" {
  name                = var.bot_name
  location            = var.azure_bot_regions[0].name
  resource_group_name = azurerm_resource_group.Bot.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  enable_automatic_failover = false
  enable_multiple_write_locations = true

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  dynamic "geo_location" {
      for_each = [for r in var.azure_bot_regions: {
          name = r.name
          prio = r.priority
      }]
      
    content {
      location   = geo_location.value.name
      failover_priority = geo_location.value.prio
    }
  }

}

resource "azurerm_cosmosdb_sql_database" "botdb" {
  name                = "bot"
  resource_group_name = azurerm_cosmosdb_account.botdb.resource_group_name
  account_name        = azurerm_cosmosdb_account.botdb.name
}

resource "azurerm_cosmosdb_sql_container" "botdb" {
  name                = "statestore"
  resource_group_name = azurerm_cosmosdb_account.botdb.resource_group_name
  account_name        = azurerm_cosmosdb_account.botdb.name
  database_name       = azurerm_cosmosdb_sql_database.botdb.name
  partition_key_path  = "/id"
}

resource "azurerm_key_vault_certificate" "TrafficManager" {
  name         = "TrafficManagerSSL"
  key_vault_id = azurerm_key_vault.GeoBot.id

  certificate {
    contents = filebase64(var.pfx_certificate_file_location)
    password = var.pfx_certificate_password
  }

  certificate_policy {
    issuer_parameters {
      name = "Unknown" // see https://github.com/terraform-providers/terraform-provider-azurerm/blob/master/examples/app-service-certificate/stored-in-keyvault/main.tf
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = false
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }
  }
}