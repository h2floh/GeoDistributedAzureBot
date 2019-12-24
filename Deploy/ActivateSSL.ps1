###
#
# Activate Custom Domain Name SSL Certificate and Reactivate TrafficManager Endpoints
#
# This script will do following steps:
#
# 1. Import information from previous Terraform runs
# 2. Terraform execution to activate certificate
#
# After the script is successfully executed the bot should be in a usable from WebChat
#
###
# Parameters
param(
    # Only needed in Issuing Mode
    [Parameter(HelpMessage="The domain (CN) name for the SSL certificate")]
    [string] $YOUR_DOMAIN,

    [Parameter(HelpMessage="Terraform Automation Flag. 0 -> Interactive, Approval 1 -> Automatic Approval")]
    [string] $AUTOAPPROVE = "0",

    [Parameter(HelpMessage="KeyVault certificate name")]
    [string] $KEYVAULT_CERT_NAME = "SSLcert"
)

# 1. Read values from Terraform IaC run (Bot deployment scripts)
echo "1. Read values from Terraform IaC run (Bot deployment scripts)"
$content = '{ "azure_webApps" : ' + $(terraform output -state=".\IaC\terraform.tfstate" -json webAppAccounts) + '}'
Set-Content -Path ".\SSLActivation\webAppVariable.tfvars.json" -Value $content
$KeyVault = terraform output -state=".\IaC\terraform.tfstate" -json keyVault | ConvertFrom-Json
$TrafficManager = terraform output -state=".\IaC\terraform.tfstate" -json trafficManager | ConvertFrom-Json

# 2. Execute Terraform
if ($AUTOAPPROVE -eq "1")
{
    $AUTOAPPROVE = "-auto-approve"
} else {
    $AUTOAPPROVE = ""
}

if ($YOUR_DOMAIN -eq "")
{
    $YOUR_DOMAIN = $TrafficManager.fqdn
}

cd SSLActivation
terraform init
terraform apply -var "keyVault_name=$($KeyVault.name)" -var "keyVault_rg=$($KeyVault.resource_group)" `
-var "your_domain=$YOUR_DOMAIN" `
-var "trafficmanager_name=$($TrafficManager.name)"  -var "trafficmanager_rg=$($TrafficManager.resource_group)" `
-var-file="webAppVariable.tfvars.json" `
-var "keyVault_cert_name=$KEYVAULT_CERT_NAME" $AUTOAPPROVE
cd ..

