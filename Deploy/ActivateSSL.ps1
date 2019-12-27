###
#
# Activate Custom Domain Name SSL Certificate and activate TrafficManager Endpoints
#
# This script will do following steps:
#
# 1. Import information from previous Terraform runs
# 2. Terraform execution to activate certificate and map TrafficManager endpoints
# 3. Update Bot Endpoint
#
# After the script is successfully executed the bot should be in a usable from WebChat
#
###
# Parameters
param(
    # Only needed in Issuing Mode
    [Parameter(HelpMessage="The domain (CN) name for the SSL certificate")]
    [string] $YOUR_DOMAIN,

    [Parameter(HelpMessage="Terraform and SSL creation Automation Flag. `$False -> Interactive, Approval `$True -> Automatic Approval")]
    [bool] $AUTOAPPROVE = $False,

    [Parameter(HelpMessage="KeyVault certificate name")]
    [string] $KEYVAULT_CERT_NAME = "SSLcert"
)
# Tell who you are
Write-Host "`n`n# Executing $($MyInvocation.MyCommand.Name)"

# 1. Read values from Terraform IaC run (Bot deployment scripts)
Write-Host "## 1. Read values from Terraform IaC run (Bot deployment scripts)"
$content = '{ "azure_webApps" : ' + $(terraform output -state=".\IaC\terraform.tfstate" -json webAppAccounts) + '}'
Set-Content -Path ".\SSLActivation\webAppVariable.tfvars.json" -Value $content
$KeyVault = terraform output -state=".\IaC\terraform.tfstate" -json keyVault | ConvertFrom-Json
$TrafficManager = terraform output -state=".\IaC\terraform.tfstate" -json trafficManager | ConvertFrom-Json
$Bot = terraform output -state=".\IaC\terraform.tfstate" -json bot | ConvertFrom-Json

# 2. Terraform execution to activate certificate and map TrafficManager endpoints
Write-Host "## 2. Terraform execution to activate certificate and map TrafficManager endpoints"
if ($AUTOAPPROVE -eq $True)
{
    $AUTOFLAG = "-auto-approve"
} else {
    $AUTOFLAG = ""
}

if ($YOUR_DOMAIN -eq "")
{
    $YOUR_DOMAIN = $TrafficManager.fqdn
}

Set-Location SSLActivation
terraform init
terraform apply -var "keyVault_name=$($KeyVault.name)" -var "keyVault_rg=$($KeyVault.resource_group)" `
-var "your_domain=$YOUR_DOMAIN" `
-var "trafficmanager_name=$($TrafficManager.name)"  -var "trafficmanager_rg=$($TrafficManager.resource_group)" `
-var-file="webAppVariable.tfvars.json" `
-var "keyVault_cert_name=$KEYVAULT_CERT_NAME" $AUTOFLAG
Set-Location ..

# 3. Update Bot Endpoint
Write-Host "## 3. Update Bot Endpoint"
az bot update --resource-group $Bot.resource_group --name $Bot.name --endpoint "https://$YOUR_DOMAIN/api/messages"

