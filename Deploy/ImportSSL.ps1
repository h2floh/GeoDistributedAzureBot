###
#
# Import existing SSL certificate to KeyVault
#
# This script will do following steps:
#
# 1. Load KeyVault values from Terraform Infrastructure run
# 2. Import PFX/SSL to KeyVault
#
# After the script is successfully executed the Bot should be in a usable from within Bot Framework Service (WebChat) and Emulator
#
###
# Parameters
param(
    [Parameter(HelpMessage="SSL CERT (PFX Format) file location")]
    [string] $PFX_FILE_LOCATION = "../SSL/sslcert.pfx",
    
    [Parameter(HelpMessage="SSL CERT (PFX Format) file password")]
    [string] $PFX_FILE_PASSWORD,

    [Parameter(HelpMessage="KeyVault certificate name")]
    [string] $KEYVAULT_CERT_NAME = "SSLcert"
)
# Tell who you are
Write-Host "`n`n# Executing $($MyInvocation.MyCommand.Name)"

# Load Values from Terraform Infrastructure run
Write-Host "## 1. Load KeyVault values from Terraform Infrastructure run"
$keyVault = terraform output -state=".\IaC\terraform.tfstate" -json keyVault | ConvertFrom-Json

# While possible to do this also with Terraform it is one simple command with AzureCLI
Write-Host "## 2. Import PFX/SSL to KeyVault"
if ($PFX_FILE_PASSWORD -ne "") {
    az keyvault certificate import --vault-name $keyVault.name --name $KEYVAULT_CERT_NAME --file $PFX_FILE_LOCATION --password $PFX_FILE_PASSWORD
} else {
    az keyvault certificate import --vault-name $keyVault.name --name $KEYVAULT_CERT_NAME --file $PFX_FILE_LOCATION
}

if($? -eq $False) {
    Write-Host "### Error while importing PFX file, please check first if password is correct and file not corrupt..."
    exit $False
}

exit $True
