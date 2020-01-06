// Current connection/authorization information for Terraform AzureRM provider
data "azurerm_client_config" "current" {}

// Retrieve Microsoft WebApps / WebSites Application Principal, because ObjectID is different in every tenant.
data "azuread_service_principal" "MicrosoftWebSites" {
  application_id = "abfa0a7c-a6b6-4736-8310-5855508787cd"
}