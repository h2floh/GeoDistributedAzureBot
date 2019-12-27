// The AAD Application required by Bot Framework Service
resource "azuread_application" "GeoBot" {
  name                       = var.bot_name
  reply_urls                 = ["https://token.botframework.com/.auth/web/redirect"]
  available_to_other_tenants = true
}

// Adding a password to the Application
resource "azuread_application_password" "GeoBot" {
  application_object_id = azuread_application.GeoBot.object_id
  value                 = random_password.aadapppassword.result
  end_date              = var.azuread_application_password_end_date

  lifecycle {
    ignore_changes = [
      # Ignore changes to end_date
      end_date
    ]
  }
}

// Saving the Bot's App ID in KeyVault (for use by Bot Application)
resource "azurerm_key_vault_secret" "MSAppId" {
  name         = "MicrosoftAppId"
  value        = azuread_application.GeoBot.application_id
  key_vault_id = azurerm_key_vault.GeoBot.id

  depends_on = [
    azurerm_key_vault_access_policy.currentClient
  ]
}

// Saving the Bot's App Secret  in KeyVault (for use by Bot Application)
resource "azurerm_key_vault_secret" "MSAppSecret" {
  name         = "MicrosoftAppPassword"
  value        = azuread_application_password.GeoBot.value
  key_vault_id = azurerm_key_vault.GeoBot.id

  depends_on = [
    azurerm_key_vault_access_policy.currentClient
  ]
}