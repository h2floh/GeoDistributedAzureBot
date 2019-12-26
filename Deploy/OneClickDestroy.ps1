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
    [Parameter(Mandatory=$true, HelpMessage="Unique Bot Name -> will be used as DNS prefix for a lot of services so it has to be very unique")]
    [ValidatePattern("^\w+$")]
    [string] $BOT_NAME,

    [Parameter(Mandatory=$true, HelpMessage="AAD AppId for Bot")]
    [string] $MICROSOFT_APP_ID,

    [Parameter(Mandatory=$true, HelpMessage="AAD AppId Secret")]
    [string] $MICROSOFT_APP_SECRET,

    [Parameter(HelpMessage="SSL CERT (PFX Format) file location")]
    [string] $PFX_FILE_LOCATION = "../SSL/sslcert.pfx",

    [Parameter(HelpMessage="KeyVault certificate name")]
    [string] $KEYVAULT_CERT_NAME = "SSLcert",

    [Parameter(HelpMessage="Terraform Automation Flag. `$False -> Interactive and option to export SSL certificate, Approval `$True -> Automatic Approval no export of SSL certificate")]
    [bool] $AUTOAPPROVE = $False
)
# Tell who you are
Write-Host "`n`n# Executing $($MyInvocation.MyCommand.Name)"

# 1. Export SSL Certificate
Write-Host "## 1. Export SSL Certificate from KeyVault"
if ($AUTOAPPROVE -eq $False) {
    .\ExportSSL.ps1 -PFX_FILE_LOCATION $PFX_FILE_LOCATION -KEYVAULT_CERT_NAME $KEYVAULT_CERT_NAME
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
terraform init
terraform destroy -var "bot_name=$BOT_NAME" -var "microsoft_app_id=$MICROSOFT_APP_ID" -var "microsoft_app_secret=$MICROSOFT_APP_SECRET" $AUTOFLAG
Set-Location ..