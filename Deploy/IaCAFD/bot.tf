// Resource Group for global and central services
resource "azurerm_resource_group" "GeoBot" {
  name     = "rg-${var.bot_name}-global"
  location = var.global_region

  tags = {
    environment = var.environment,
    region = "global"
  }
}

// Azure Front Door for accessing 
resource "azurerm_frontdoor" "GeoBot" {
  name                                         = var.bot_name
  location                                     = "global" //azurerm_resource_group.GeoBot.location
  resource_group_name                          = azurerm_resource_group.GeoBot.name
  enforce_backend_pools_certificate_name_check = true

  routing_rule {
    name               = "GeoBot"
    accepted_protocols = ["Https"]
    patterns_to_match  = ["/*"]
    frontend_endpoints = ["GeoBot"]
    forwarding_configuration {
      cache_enabled = false
      cache_use_dynamic_compression = false
      forwarding_protocol = "HttpsOnly"
      backend_pool_name   = "GeoBot"
    }
  }

  backend_pool_load_balancing {
    name = "GeoBot"
    additional_latency_milliseconds = 0
    sample_size = 2
    successful_samples_required = 1
  }

  backend_pool_health_probe {
    name = "GeoBot"
    interval_in_seconds = 30
    path = "/healthcheck"
    protocol = "Https"
  }

  backend_pool {
    name = "GeoBot"

    // Create this DB MultiMaster mode for every Bot region
    dynamic "backend" {
        for_each = [for instance in azurerm_app_service.Region: {
            url = instance.default_site_hostname 
        }]
        
      content {
        //backend.value.url
        host_header = backend.value.url
        address     = backend.value.url
        http_port   = 80
        https_port  = 443
        priority    = 1
        weight      = 50
      }
    }

    load_balancing_name = "GeoBot"
    health_probe_name   = "GeoBot"
  }

  frontend_endpoint {
    name                              = "GeoBot"
    host_name                         = "${var.bot_name}.azurefd.net"
    custom_https_provisioning_enabled = false
    session_affinity_enabled = false
    session_affinity_ttl_seconds = 0
  }
}


// Central Application Insight for all Bot regions
resource "azurerm_application_insights" "GeoBot" {
  name                = var.bot_name
  location            = azurerm_resource_group.GeoBot.location
  resource_group_name = azurerm_resource_group.GeoBot.name
  application_type    = "web"
}

// Bot Channel Registration (this is part of the Azure Bot Framework Service)
resource "azurerm_bot_channels_registration" "GeoBot" {
  name                = var.bot_name
  location            = "global"
  resource_group_name = azurerm_resource_group.GeoBot.name
  sku                 = var.bot_sku
  microsoft_app_id    = azuread_application.GeoBot.application_id
  endpoint            = "https://${azurerm_frontdoor.GeoBot.cname}/api/messages" 
  developer_app_insights_application_id = azurerm_application_insights.GeoBot.app_id
  developer_app_insights_key = azurerm_application_insights.GeoBot.instrumentation_key
}

// Central Configuration Store, this could be potentially spread between regions and or used together with Azure Configuration Services (not demonstrated)
resource "azurerm_key_vault" "GeoBot" {
  name                        = var.bot_name
  location                    = azurerm_resource_group.GeoBot.location
  resource_group_name         = azurerm_resource_group.GeoBot.name
  enabled_for_disk_encryption = false
  tenant_id                   = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"
  
  network_acls {
    default_action = "Allow"
    bypass = "None"
  }
}

// The current ARM connection for the Terraform AzureRM provider needs access rights to the KeyVault in order to store secrets there
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

// The App Service Web App Principal needs access to the KeyVault in order to import stored (SSL) certificates
resource "azurerm_key_vault_access_policy" "webAppPrincipal" {
    key_vault_id = azurerm_key_vault.GeoBot.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azuread_service_principal.MicrosoftWebSites.object_id

    secret_permissions = [
        "get",
    ]

    certificate_permissions = [
        "get",
    ]

  depends_on = [
    azurerm_key_vault_access_policy.currentClient
  ]
}

// Saving the AppInsight ID in KeyVault (for use by Bot Application)
resource "azurerm_key_vault_secret" "AppInsightId" {
  name         = "AppInsightId"
  value        = azurerm_application_insights.GeoBot.app_id
  key_vault_id = azurerm_key_vault.GeoBot.id

  depends_on = [
    azurerm_key_vault_access_policy.currentClient
  ]
}

// Saving the AppInsight Instrumentation Key in KeyVault (for use by Bot Application)
resource "azurerm_key_vault_secret" "AppInsightInstrumentationKey" {
  name         = "ApplicationInsights--InstrumentationKey"
  value        = azurerm_application_insights.GeoBot.instrumentation_key
  key_vault_id = azurerm_key_vault.GeoBot.id

  depends_on = [
    azurerm_key_vault_access_policy.currentClient
  ]
}

// Saving the LUIS Authoring Key in KeyVault (for use by LUIS Deployment script)
resource "azurerm_key_vault_secret" "LUISAuthoringKey" {
  name         = "LUISAuthoringKey"
  value        = azurerm_cognitive_account.LUISAuthoring.primary_access_key
  key_vault_id = azurerm_key_vault.GeoBot.id

  depends_on = [
    azurerm_key_vault_access_policy.currentClient
  ]
}

// Saving the LUIS Authoring Endpoint in KeyVault (for use by LUIS Deployment script)
resource "azurerm_key_vault_secret" "LUISAuthoringEndpoint" {
  name         = "LUISAuthoringEndpoint"
  value        = azurerm_cognitive_account.LUISAuthoring.endpoint
  key_vault_id = azurerm_key_vault.GeoBot.id

  depends_on = [
    azurerm_key_vault_access_policy.currentClient
  ]
}

// LUIS Authoring Key
resource "azurerm_cognitive_account" "LUISAuthoring" {
  name                = "${var.bot_name}LUISAuthoring"
  location            = "westus" //see https://docs.microsoft.com/en-us/azure/cognitive-services/luis/luis-reference-regions
  resource_group_name = azurerm_resource_group.GeoBot.name
  kind                = "LUIS.Authoring"

  sku_name = "F0" // S0 not available
}

// Saving CosmosDB Endpoint in KeyVault (for use by Bot Application)
resource "azurerm_key_vault_secret" "CosmosDBEndpoint" {
  name         = "CosmosDBStateStoreEndpoint"
  value        = azurerm_cosmosdb_account.botdb.endpoint
  key_vault_id = azurerm_key_vault.GeoBot.id

  depends_on = [
    azurerm_key_vault_access_policy.currentClient
  ]
}

// Saving CosmosDB AccessKey in KeyVault (for use by Bot Application)
resource "azurerm_key_vault_secret" "CosmosDBKey" {
  name         = "CosmosDBStateStoreKey"
  value        = azurerm_cosmosdb_account.botdb.primary_master_key
  key_vault_id = azurerm_key_vault.GeoBot.id

  depends_on = [
    azurerm_key_vault_access_policy.currentClient
  ]
}

// Saving CosmosDB Database Name in KeyVault (for use by Bot Application as StateStore)
resource "azurerm_key_vault_secret" "CosmosDBDatabase" {
  name         = "CosmosDBStateStoreDatabaseId"
  value        = azurerm_cosmosdb_sql_database.botdb.name
  key_vault_id = azurerm_key_vault.GeoBot.id

  depends_on = [
    azurerm_key_vault_access_policy.currentClient
  ]
}

// Saving CosmosDB Container Name in KeyVault (for use by Bot Application as StateStore)
resource "azurerm_key_vault_secret" "CosmosDBCollection" {
  name         = "CosmosDBStateStoreCollectionId"
  value        = azurerm_cosmosdb_sql_container.botdb.name
  key_vault_id = azurerm_key_vault.GeoBot.id

  depends_on = [
    azurerm_key_vault_access_policy.currentClient
  ]
}

// Creating the CosmosDB account
resource "azurerm_cosmosdb_account" "botdb" {
  name                = var.bot_name
  location            = var.azure_bot_regions[0].name
  resource_group_name = azurerm_resource_group.GeoBot.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  enable_automatic_failover = false
  enable_multiple_write_locations = true

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  // Create this DB MultiMaster mode for every Bot region
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

// Add a Database to CosmosDB Account
resource "azurerm_cosmosdb_sql_database" "botdb" {
  name                = "bot"
  resource_group_name = azurerm_cosmosdb_account.botdb.resource_group_name
  account_name        = azurerm_cosmosdb_account.botdb.name
}

// Add a Container with partition key 'id' to CosmosDB Database
resource "azurerm_cosmosdb_sql_container" "botdb" {
  name                = "statestore"
  resource_group_name = azurerm_cosmosdb_account.botdb.resource_group_name
  account_name        = azurerm_cosmosdb_account.botdb.name
  database_name       = azurerm_cosmosdb_sql_database.botdb.name
  partition_key_path  = "/id"
}

