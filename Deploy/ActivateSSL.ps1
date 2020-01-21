<#
.SYNOPSIS
Activate Custom Domain Name SSL Certificate and activate TrafficManager Endpoints

.DESCRIPTION
Activate Custom Domain Name SSL Certificate and activate TrafficManager Endpoints

This script will do following steps:

1. Import information from previous Terraform runs
2. Terraform execution to activate certificate and map TrafficManager endpoints
3. Update Bot Endpoint

After the script is successfully executed the bot should be in a usable state from WebChat

.EXAMPLE
.\ActivateSSL.ps1 -YOUR_DOMAIN bot.mydomain.com

.INPUTS
None. You cannot pipe objects.

.OUTPUTS
System.Boolean. Sucessful execution

#>
param(
    # The domain (CN) name for the SSL certificate
    [Parameter(HelpMessage="The domain (CN) name for the SSL certificate")]
    [string] $YOUR_DOMAIN,

    #Terraform and SSL creation Automation Flag. $False -> Interactive, Approval $True -> Automatic Approval
    [Parameter(HelpMessage="Terraform and SSL creation Automation Flag. `$False -> Interactive, Approval `$True -> Automatic Approval")]
    [bool] $AUTOAPPROVE = $False,
    
    #KeyVault certificate key name
    [Parameter(HelpMessage="KeyVault certificate key name")]
    [string] $KEYVAULT_CERT_NAME = "SSLcert"
)
# Import Helper functions
. "$($MyInvocation.MyCommand.Path -replace($MyInvocation.MyCommand.Name))\HelperFunctions.ps1"
# Helper var
$success = $True
$terraformFolder = "SSLActivation"
$webAppsVariableFile = "$(Get-ScriptPath)/$terraformFolder/webAppVariable.tfvars.json"

# Tell who you are (See HelperFunction.ps1)
Write-WhoIAm

# 1. Read values from Terraform IaC run (Bot deployment scripts)
Write-Host "## 1. Read values from Terraform IaC run (Bot deployment scripts)"
$content = '{ "azure_webApps" : ' + $(Get-TerraformOutput("webAppAccounts")) + '}'
$success = $success -and $?
$KeyVault = Get-TerraformOutput("keyVault") | ConvertFrom-Json
$success = $success -and $?
$TrafficManager = Get-TerraformOutput("trafficManager") | ConvertFrom-Json
$success = $success -and $?
$Bot = Get-TerraformOutput("bot") | ConvertFrom-Json
$success = $success -and $?

# Set Variable File for webApps
Set-Content -Path "$webAppsVariableFile" -Value $content


# 2. Terraform execution to activate certificate and map TrafficManager endpoints
Write-Host "## 2. Terraform execution to activate certificate and map TrafficManager endpoints"
if ($YOUR_DOMAIN -eq "")
{
    $YOUR_DOMAIN = $TrafficManager.fqdn
}

# Terraform Apply (If Init is needed execute InitTerraform.ps1 first)
$inputvars = @(
    "-var 'keyVault_name=$($KeyVault.name)'",
    "-var 'keyVault_rg=$($KeyVault.resource_group)'",
    "-var 'your_domain=$YOUR_DOMAIN'",
    "-var 'trafficmanager_name=$($TrafficManager.name)'",
    "-var 'trafficmanager_rg=$($TrafficManager.resource_group)'",
    "-var 'keyVault_cert_name=$KEYVAULT_CERT_NAME'",
    "-var-file='$webAppsVariableFile'"
)   
Invoke-Terraform -TERRAFORM_FOLDER $terraformFolder -AUTOAPPROVE $AUTOAPPROVE -INPUTVARS $inputvars
$success = $success -and $LASTEXITCODE

# CleanUp
Remove-Item -Path "$webAppsVariableFile"

# 3. Update Bot Endpoint
Write-Host "## 3. Update Bot Endpoint"
az bot update --resource-group $Bot.resource_group --name $Bot.name --endpoint "https://$YOUR_DOMAIN/api/messages"
$success = $success -and $?

# Return execution status
Write-ExecutionStatus -success $success
exit $success