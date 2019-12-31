<#
.SYNOPSIS
One Click Destroy for Geo Distributed Bot Solution

.DESCRIPTION
One Click Destroy for Geo Distributed Bot Solution

This script will do following steps:

1. Export Certificate to file [only if not in AUTOAPPROVE mode]
2. Destroy rest of environment with Terraform

After the script is successfully executed there should be nothing left

.EXAMPLE
.\OneClickDestroy.ps1 -BOT_NAME myuniquebot

.EXAMPLE
.\OneClickDestroy.ps1 -BOT_NAME myuniquebot -AUTOAPPROVE $True

.INPUTS
None. You cannot pipe objects.

.OUTPUTS
System.Boolean. Returns $True if executed successfully

#>
param(
    # Unique Bot Name
    [Parameter(Mandatory=$true, HelpMessage="Unique Bot Name")]
    [ValidatePattern("^\w+$")]
    [string] $BOT_NAME,

    # Regions the Bot was deployed to
    [Parameter(HelpMessage="Regions the Bot was deployed to")]
    [string[]] $BOT_REGIONS = @("koreacentral", "southeastasia"),

    # Region used for global services
    [Parameter(HelpMessage="Region used for global services")]
    [string] $BOT_GLOBAL_REGION = "japaneast",

    # SSL CERT (PFX Format) file location
    [Parameter(HelpMessage="SSL CERT (PFX Format) file location")]
    [string] $PFX_FILE_LOCATION,

    # KeyVault certificate key name
    [Parameter(HelpMessage="KeyVault certificate key name")]
    [string] $KEYVAULT_CERT_NAME = "SSLcert",

    # Terraform Automation Flag. $False -> Interactive and option to export SSL certificate, Approval $True -> Automatic Approval no export of SSL certificate
    [Parameter(HelpMessage="Terraform Automation Flag. `$False -> Interactive and option to export SSL certificate, Approval `$True -> Automatic Approval no export of SSL certificate")]
    [bool] $AUTOAPPROVE = $False
)
# Import Helper functions
. "$($MyInvocation.MyCommand.Path -replace($MyInvocation.MyCommand.Name))\HelperFunctions.ps1"
# Helper var
$success = $True
$terraformFolder = "IaC"
$azureBotRegions = "$(Get-ScriptPath)/$terraformFolder/azure_bot_regions.tfvars.json"

# Tell who you are (See HelperFunction.ps1)
Write-WhoIAm

# 1. Export SSL Certificate
Write-Host "## 1. Export SSL Certificate from KeyVault"
if ($AUTOAPPROVE -eq $False) {
    & "$(Get-ScriptPath)\ExportSSL.ps1" -PFX_FILE_LOCATION $PFX_FILE_LOCATION -KEYVAULT_CERT_NAME $KEYVAULT_CERT_NAME
    $success = $success -and $LASTEXITCODE
} else {
    Write-Host -ForegroundColor Yellow "### WARNING, NO SSL EXPORT DUE TO ACTIVATED AUTOAPPROVE OPTION!!"
}

# 2. Destroy all infrastructure
Write-Host "## 2. Destroy the infrastructure"

# Create Variable file for Terraform
$result = Set-RegionalVariableFile -FILENAME $azureBotRegions -BOT_REGIONS $BOT_REGIONS
$success = $success -and $result

terraform init "$(Get-ScriptPath)/$terraformFolder"
terraform destroy -var "bot_name=$BOT_NAME" -var "global_region=$BOT_GLOBAL_REGION" -var-file="$azureBotRegions" -state="$(Get-ScriptPath)/$terraformFolder/terraform.tfstate" $(Get-TerraformAutoApproveFlag $AUTOAPPROVE) "$(Get-ScriptPathTerraformApply)/$terraformFolder"
$success = $success -and $?

# Clean Up
Remove-Item -Path $azureBotRegions 

# Return execution status
Write-ExecutionStatus -success $success
exit $success