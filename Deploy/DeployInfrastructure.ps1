<#
.SYNOPSIS
Terraform Deployment of the base infrastructure

.DESCRIPTION
Terraform Deployment of the base infrastructure

This script will do following steps:

1. Deploy Infrastructure with Terraform

After the script is successfully executed the Bot can be deployed to WebApps and infrastructure is ready for import 
a SSL certificate and activation of TrafficManager

.EXAMPLE
.\DeployInfrastructure.ps1 -BOT_NAME myuniquebot -AUTOAPPROVE $True

.INPUTS
None. You cannot pipe objects.

.OUTPUTS
System.Boolean. Returns $True if executed successfully

#>
param(
    # Unique Bot Name -> will be used as DNS prefix for CosmosDB, TrafficManager and KeyVault
    [Parameter(Mandatory=$true, HelpMessage="Unique Bot Name -> will be used as DNS prefix for CosmosDB, TrafficManager and KeyVault")]
    [ValidatePattern("^\w+$")]
    [string] $BOT_NAME,

    # Regions to deploy the Bot to
    [Parameter(HelpMessage="Regions to deploy the Bot to")]
    [string[]] $BOT_REGIONS = @("koreacentral", "southeastasia"),

    # Region used for global services
    [Parameter(HelpMessage="Region used for global services")]
    [string] $BOT_GLOBAL_REGION = "japaneast",

    # Terraform and SSL creation Automation Flag. $False -> Interactive, Approval $True -> Automatic Approval
    [Parameter(HelpMessage="Terraform and SSL creation Automation Flag. `$False -> Interactive, Approval `$True -> Automatic Approval")]
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

# Execute first Terraform to create the infrastructure
Write-Host "## 1. Deploy Infrastructure with Terraform"

# Create Variable file for Terraform
$result = Set-RegionalVariableFile -FILENAME $azureBotRegions -BOT_REGIONS $BOT_REGIONS
$success = $success -and $result

terraform init "$(Get-ScriptPath)/$terraformFolder"
terraform apply -var "bot_name=$BOT_NAME" -var "global_region=$BOT_GLOBAL_REGION" -var-file="$azureBotRegions" -state="$(Get-ScriptPath)/$terraformFolder/terraform.tfstate" $(Get-TerraformAutoApproveFlag $AUTOAPPROVE) "$(Get-ScriptPathTerraformApply)/$terraformFolder"
$success = $success -and $?

# Clean Up
Remove-Item -Path $azureBotRegions

# Check successful execution
Write-ExecutionStatus -success $success
exit $success
