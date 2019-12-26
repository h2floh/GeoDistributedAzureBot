###
#
# One Click Deployment for Geo Distributed Bot Solution
#
# This script will do following steps:
#
# 1. Deploy Infrastructure with Terraform
#
# After the script is successfully executed the Bot can be deployed to WebApps and infrastructure is ready for import 
# a SSL certificate and activation of TrafficManager
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

    [Parameter(HelpMessage="Terraform and SSL creation Automation Flag. `$False -> Interactive, Approval `$True -> Automatic Approval")]
    [bool] $AUTOAPPROVE = $False
)
# Tell who you are
Write-Host "`n`n# Executing $($MyInvocation.MyCommand.Name)"

# Execute first Terraform to create the infrastructure
if ($AUTOAPPROVE)
{
    $AUTOFLAG = "-auto-approve"
} else {
    $AUTOFLAG = ""
}
Write-Host "## 1. Deploy Infrastructure with Terraform"
Set-Location IaC
terraform init
terraform apply -var "bot_name=$BOT_NAME" -var "microsoft_app_id=$MICROSOFT_APP_ID" -var "microsoft_app_secret=$MICROSOFT_APP_SECRET" $AUTOFLAG
Set-Location ..