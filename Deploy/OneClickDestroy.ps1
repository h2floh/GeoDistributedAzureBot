###
#
# One Click Destroy for Geo Distributed Bot Solution
#
# This script will do following steps:
#
# 1. Export Certificate to file [only if not in AUTOAPPROVE mode]
# 2. Destroy rest of environment with Terraform
#
# After the script is successfully executed there should be nothing left
#
###
# Parameters
param(
    [Parameter(Mandatory=$true, HelpMessage="Unique Bot Name")]
    [ValidatePattern("^\w+$")]
    [string] $BOT_NAME,

    [Parameter(HelpMessage="Regions the Bot was deployed to")]
    [string[]] $BOT_REGIONS = @("koreacentral", "southeastasia"),

    [Parameter(HelpMessage="Region used for global services")]
    [string] $BOT_GLOBAL_REGION = "japaneast",

    [Parameter(HelpMessage="SSL CERT (PFX Format) file location")]
    [string] $PFX_FILE_LOCATION = "../SSL/sslcert.pfx",

    [Parameter(HelpMessage="KeyVault certificate name")]
    [string] $KEYVAULT_CERT_NAME = "SSLcert",

    [Parameter(HelpMessage="Terraform Automation Flag. `$False -> Interactive and option to export SSL certificate, Approval `$True -> Automatic Approval no export of SSL certificate")]
    [bool] $AUTOAPPROVE = $False
)
# Helper var
$success = $True
$azureBotRegions = "azure_bot_regions.tfvars.json"

# Tell who you are
Write-Host "`n`n# Executing $($MyInvocation.MyCommand.Name)"

# 1. Export SSL Certificate
Write-Host "## 1. Export SSL Certificate from KeyVault"
if ($AUTOAPPROVE -eq $False) {
    .\ExportSSL.ps1 -PFX_FILE_LOCATION $PFX_FILE_LOCATION -KEYVAULT_CERT_NAME $KEYVAULT_CERT_NAME
    $success = $success -and $LASTEXITCODE
} else {
    Write-Host "### NO SSL EXPORT DUE TO ACTIVATED AUTOAPPROVE OPTION!!"
}

# 2. Destroy all infrastructure
if ($AUTOAPPROVE)
{
    $AUTOFLAG = "-auto-approve"
} else {
    $AUTOFLAG = ""
}

Write-Host "## 2. Destroy the infrastructure"
Set-Location IaC

# Create Variable file for Terraform
..\CreateRegionVariableFile.ps1 -FILENAME $azureBotRegions -BOT_REGIONS $BOT_REGIONS
$success = $success -and $LASTEXITCODE

terraform init
terraform destroy -var "bot_name=$BOT_NAME" -var "global_region=$BOT_GLOBAL_REGION" -var-file="$azureBotRegions" $AUTOFLAG
$success = $success -and $?

# Clean Up
Remove-Item -Path $azureBotRegions 
Set-Location ..

# Return execution status
exit $success