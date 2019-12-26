###
#
# Check if already a SSL certificate was imported to KeyVault
#
# This script will do following steps:
#
# 1. Read values from Terraform IaC run (Bot deployment scripts)
# 2. Check if certificate exists in Key Vault
#
# Returns $True if certificate already exists
#
###
# Parameters
param(
    [Parameter(HelpMessage="KeyVault certificate name")]
    [string] $KEYVAULT_CERT_NAME = "SSLcert"
)
# Tell who you are
Write-Host "`n`n# Executing $($MyInvocation.MyCommand.Name)"

# 1. Read values from Terraform IaC run (Bot deployment scripts)
Write-Host "## 1. Read values from Terraform IaC run (Bot deployment scripts)"
$KeyVault = terraform output -state=".\IaC\terraform.tfstate" -json keyVault | ConvertFrom-Json

# 2. Check if certificate exists in Key Vault
Write-Host "## 2. Check if certificate exists in Key Vault"
az keyvault certificate show --vault-name $KeyVault.name --name $KEYVAULT_CERT_NAME > $null 2> $1
if ($? -eq $True)
{
    Write-Host "### Existing Certificate found"
    return $True
} else {
    Write-Host "### No existing Certificate found"
    return $False
}