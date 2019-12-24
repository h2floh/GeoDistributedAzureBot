###
#
# One Click Deployment for Geo Distributed Bot Solution
#
# This script will do following steps:
#
# 1. Terraform
# 2. Deploy, train and publish LUIS
# 3. Deploy to WebApps
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
    [string] $PFX_FILE_PASSWORD,

    [Parameter(HelpMessage="Terraform Automation Flag. 0 -> Interactive, Approval 1 -> Automatic Approval")]
    [string] $AUTOAPPROVE = "0"
)

# Execute first Terraform to create the infrastructure
if ($AUTOAPPROVE -eq "1")
{
    $AUTOAPPROVE = "-auto-approve"
} else {
    $AUTOAPPROVE = ""
}
cd IaC
terraform init
terraform apply -var "bot_name=$BOT_NAME" -var "microsoft_app_id=$MICROSOFT_APP_ID" -var "microsoft_app_secret=$MICROSOFT_APP_SECRET" $AUTOAPPROVE
cd ..

# Execute LUIS Train & Deploy
.\ImportAndConnectLUIS.ps1

# Deploy to WebApps
.\DeployBotToWebapp.ps1
