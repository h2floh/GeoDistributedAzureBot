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

    [Parameter(HelpMessage="Regions to deploy the Bot to")]
    [string[]] $BOT_REGIONS = @("koreacentral", "southeastasia"),

    [Parameter(HelpMessage="Region used for global services")]
    [string] $BOT_GLOBAL_REGION = "japaneast",

    [Parameter(HelpMessage="Terraform and SSL creation Automation Flag. `$False -> Interactive, Approval `$True -> Automatic Approval")]
    [bool] $AUTOAPPROVE = $False
)
# Helper var
$success = $True
$azureBotRegions = "azure_bot_regions.tfvars.json"

# Tell who you are
Write-Host "`n`n# Executing $($MyInvocation.MyCommand.Name)"

# Execute first Terraform to create the infrastructure
Write-Host "## 1. Deploy Infrastructure with Terraform"
Set-Location IaC

if ($AUTOAPPROVE)
{
    $AUTOFLAG = "-auto-approve"
} else {
    $AUTOFLAG = ""
}

# Create Variable file for Terraform
..\CreateRegionVariableFile.ps1 -FILENAME $azureBotRegions -BOT_REGIONS $BOT_REGIONS
$success = $success -and $LASTEXITCODE

terraform init
terraform apply -var "bot_name=$BOT_NAME" -var "global_region=$BOT_GLOBAL_REGION" -var-file="$azureBotRegions" $AUTOFLAG
$success = $success -and $?

# Clean Up
Remove-Item -Path $azureBotRegions 
Set-Location ..

# Check successful execution
exit $success
