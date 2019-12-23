###
#
# One Click Destroy for Geo Distributed Bot Solution
#
# This script will do following steps:
#
# 1. Destroy Traffic Manager manually (due to unresolvable dependency - WebApp Custom Domain Name can not be deleted by design, breaks destroy process)
# 2. Destroy Central KeyVault manually (if current client looses access_policy there is a authorization error while deleting the vault)
# 3. Destroy rest of environment with Terraform
#
# After the script is successfully executed the bot should be in a usable state
#
###
# Parameters
param(
    [Parameter(Mandatory=$true, HelpMessage="Unique Bot Name -> will be used as DNS prefix for a lot of services so it has to be very unique")]
    [ValidatePattern("^\w+$")]
    [string] $BOT_NAME,

    [Parameter(Mandatory=$true, HelpMessage="AAD AppId for Bot")]
    [string] $MICROSOFT_APP_ID,

    [Parameter(Mandatory=$true, HelpMessage="AAD AppId Secret")]
    [string] $MICROSOFT_APP_SECRET,

    [Parameter(HelpMessage="SSL CERT (PFX Format) file location")]
    [string] $PFX_FILE_LOCATION,
    
    [Parameter(HelpMessage="SSL CERT (PFX Format) file password")]
    [string] $PFX_FILE_PASSWORD
)

# Check if relative or absolute file path
if( $PFX_FILE_LOCATION -match '^.\:' -eq $False ) {
    # relative
    echo "relative"
    $PFX_FILE_LOCATION = '../' + $PFX_FILE_LOCATION
}

# Destroy Traffic Manager
# echo "Destroying Traffic Manager"
# $trafficManager = terraform output -state=".\IaC\terraform.tfstate" -json trafficManager | ConvertFrom-Json
# az network traffic-manager profile delete -n $trafficManager.name -g $trafficManager.resource_group

# Destroy Key vault
# echo "Destroying Central KeyVault"
# $keyVault = terraform output -state=".\IaC\terraform.tfstate" -json keyVault | ConvertFrom-Json
# az keyvault delete -n $keyVault.name -g $keyVault.resource_group

# Destroy with Terraform
cd IaC
terraform init
terraform destroy -var "bot_name=$BOT_NAME" -var "microsoft_app_id=$MICROSOFT_APP_ID" -var "microsoft_app_secret=$MICROSOFT_APP_SECRET"
cd ..