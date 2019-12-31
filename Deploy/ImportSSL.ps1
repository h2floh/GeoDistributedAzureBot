<#
.SYNOPSIS
Import existing SSL certificate to KeyVault

.DESCRIPTION
Import existing SSL certificate to KeyVault

This script will do following steps:

1. Load KeyVault values from Terraform Infrastructure run
2. Import PFX/SSL to KeyVault

After the script is successfully executed the Bot should be in a usable from within Bot Framework Service (WebChat) and Emulator

.EXAMPLE
.\ImportSSL.ps1 -PFX_FILE_LOCATION ../SSL/mybot.pfx -PFX_FILE_PASSWORD securesecret

.INPUTS
None. You cannot pipe objects.

.OUTPUTS
System.Boolean. Returns $True if executed successfully

#>
param(
    # SSL CERT (PFX Format) file location - Default: SSL/<BOT_NAME>.pfx
    [Parameter(HelpMessage="SSL CERT (PFX Format) file location")]
    [string] $PFX_FILE_LOCATION,
    
    # SSL CERT (PFX Format) file password
    [Parameter(HelpMessage="SSL CERT (PFX Format) file password")]
    [string] $PFX_FILE_PASSWORD,

    # KeyVault certificate key name
    [Parameter(HelpMessage="KeyVault certificate key name")]
    [string] $KEYVAULT_CERT_NAME = "SSLcert"
)
# Helper var
$iaCFolder = "IaC"
# Import Helper functions
. "$($MyInvocation.MyCommand.Path -replace($MyInvocation.MyCommand.Name))\HelperFunctions.ps1"
# Tell who you are (See HelperFunction.ps1)
Write-WhoIAm

# Load Values from Terraform Infrastructure run
Write-Host "## 1. Load KeyVault values from Terraform Infrastructure run"
$keyVault = terraform output -state="$(Get-ScriptPath)/$iaCFolder/terraform.tfstate" -json keyVault | ConvertFrom-Json

# Set Default Values for Parameters
$PFX_FILE_LOCATION = Set-DefaultIfEmpty -VALUE $PFX_FILE_LOCATION -DEFAULT "$(Get-ScriptPath)/../SSL/$($KeyVault.name).pfx"

# While possible to do this also with Terraform it is one simple command with AzureCLI
Write-Host "## 2. Import PFX/SSL to KeyVault"
if ($PFX_FILE_PASSWORD -ne "") {
    az keyvault certificate import --vault-name $keyVault.name --name $KEYVAULT_CERT_NAME --file $PFX_FILE_LOCATION --password $PFX_FILE_PASSWORD
} else {
    az keyvault certificate import --vault-name $keyVault.name --name $KEYVAULT_CERT_NAME --file $PFX_FILE_LOCATION
}

if($? -eq $False) {
    Write-Host -ForegroundColor -Red "### Error while importing PFX file, please check first if password is correct and file not corrupt..."
    exit $False
}

exit $True
