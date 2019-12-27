resource "azurerm_container_group" "LetsEncryptACI" {
  name                = data.azurerm_key_vault.SSLVault.name
  location            = var.aci_location
  resource_group_name = var.aci_rg
  ip_address_type     = "public"
  dns_name_label      = random_string.dnslabel.result
  os_type             = "Linux"
  restart_policy      = "Never"

  container {
    name   = "letsencrypt"
    image  = var.aci_image
    cpu    = "0.5"
    memory = "1"

    ports {
      port     = 80
      protocol = "TCP"
    }

    environment_variables = {
      YOUR_CERTIFICATE_EMAIL = var.your_certificate_email,
      YOUR_DOMAIN = var.your_domain,
      KEY_VAULT_NAME = var.keyVault_name,
      KEY_VAULT_CERT_NAME = var.keyVault_cert_name,
      PRODUCTION = var.production
    }
  }

  identity {
    type = "SystemAssigned"
  }

  // creating a reference to the Traffic Manager Endpoint, only when endpoint was created starting this container
  depends_on = [
    azurerm_traffic_manager_endpoint.LetsEncryptACI
  ]
}

resource "azurerm_key_vault_access_policy" "LetsEncryptACI" {
    key_vault_id = data.azurerm_key_vault.SSLVault.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_container_group.LetsEncryptACI.identity[0].principal_id

    secret_permissions = [
        "set"
    ]

    certificate_permissions = [
        "create",
        "import"
    ]
}

resource "azurerm_traffic_manager_endpoint" "LetsEncryptACI" {
  name                = "LetsEncrypt"
  resource_group_name = var.trafficmanager_rg
  profile_name        = var.trafficmanager_name
  type                = "externalEndpoints"
  target              = "${random_string.dnslabel.result}.${var.aci_location}.azurecontainer.io"
  endpoint_location   = var.aci_location
}