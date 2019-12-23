// Bot name has to be unique (services account and dns names will be determined by this setting)
variable "bot_name" {
}

// Creation of AAD Application has to be done apriori
variable "microsoft_app_id" {
}

// Creation of AAD Application's Secret has to be done apriori
variable "microsoft_app_secret" {
}

// These is the list of regions in which you will deploy the Bot
// each Azure region which provides AppService WebApps and LUIS is possible
// Check availability of Language Understanding and WebApps here:
// https://azure.microsoft.com/en-us/global-infrastructure/services/?products=cognitive-services,app-service&regions=all
//
// CosmosDB Failover: Lowest priority will be failovered to first
variable "azure_bot_regions" {
  type = list
  default = [ 
    { 
      name = "southeastasia"
      priority = 0 // For CosmosDB MultiMaster, bot regions will be selected by traffic manager
    }, 
    { 
      name = "koreacentral"
      priority = 1 // For CosmosDB MultiMaster, bot regions will be selected by traffic manager
    }
    ]
}

// "Global Region" - Management Region for Global Services
variable "global_region" {
  default = "japaneast"
}

// Environment Tag Name
variable "environment" {
  default = "geobotpoc"
}

// Bot SKU
variable "bot_sku" {
  default = "S1"
}

// App Service WebApp Principal's Object ID
variable "webapp_resource_principal_object_id" {
  default = "f8daea97-62e7-4026-becf-13c2ea98e8b4"
}
