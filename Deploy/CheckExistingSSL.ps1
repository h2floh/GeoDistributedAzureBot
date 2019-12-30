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
# Import Helper functions
. "$($MyInvocation.MyCommand.Path -replace($MyInvocation.MyCommand.Name))\HelperFunctions.ps1"
# Tell who you are (See HelperFunction.ps1)
Write-WhoIAm

# 1. Read values from Terraform IaC run (Bot deployment scripts)
Write-Host "## 1. Read values from Terraform IaC run (Bot deployment scripts)"
$KeyVault = terraform output -state="$(Get-ScriptPath)/IaC/terraform.tfstate" -json keyVault | ConvertFrom-Json

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