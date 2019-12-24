###
#
# Issue new SSL certificate from Let's Encrypt
#
# This script will do following steps:
#
# 1. Read values from previous Infrastructure Deployment run (Terraform & Bot Deployment) 
# 2. Terraform execution to spin up container who issues SSL cert and stores in KeyVault
# 3. Check if certificate was created
# 3. Terraform destroy to clean up resources only need for SSL issuing
#
# After the script is successfully executed the certificate should be stored in KeyVault
#
###
# Parameters
param(
    [Parameter(Mandatory=$true, HelpMessage="Mail to be associated with Let's Encrypt certificate")]
    [ValidatePattern("(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|""(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*"")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])")]
    [string] $YOUR_CERTIFICATE_EMAIL,

    [Parameter(HelpMessage="The domain (CN) name for the SSL certificate")]
    [string] $YOUR_DOMAIN,

    [Parameter(HelpMessage="Flag if production or stage of Let's Encrypt will be used. 0 -> Staging 1 -> Production")]
    [string] $PRODUCTION = "1",

    [Parameter(HelpMessage="Terraform Automation Flag. 0 -> Interactive, Approval 1 -> Automatic Approval")]
    [string] $AUTOAPPROVE = "0",

    [Parameter(HelpMessage="KeyVault certificate name")]
    [string] $KEYVAULT_CERT_NAME = "SSLcert"
)

# 1. Read values from Terraform IaC run (Bot deployment scripts)
echo "1. Read values from Terraform IaC run (Bot deployment scripts)"
$KeyVault = terraform output -state=".\IaC\terraform.tfstate" -json keyVault | ConvertFrom-Json
$TrafficManager = terraform output -state=".\IaC\terraform.tfstate" -json trafficManager | ConvertFrom-Json

# 2. Apply Terraform for SSLIssuing
echo "2. Apply Terraform for SSLIssuing"

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

cd SSLIssuing
terraform init
terraform apply -var "keyVault_name=$($KeyVault.name)" -var "keyVault_rg=$($KeyVault.resource_group)" `
-var "your_certificate_email=$YOUR_CERTIFICATE_EMAIL"  -var "your_domain=$YOUR_DOMAIN" `
-var "trafficmanager_name=$($TrafficManager.name)"  -var "trafficmanager_rg=$($TrafficManager.resource_group)" `
-var "aci_rg=$($KeyVault.resource_group)"  -var "aci_location=$($KeyVault.location)" `
-var "keyVault_cert_name=$KEYVAULT_CERT_NAME" -var "production=$PRODUCTION" $AUTOAPPROVE
cd ..

# 3. Check for creation of certificate
echo "3. Check for availability of certificate"
$cert = az keyvault certificate show --vault-name $KeyVault.name --name $KEYVAULT_CERT_NAME
while ($? -eq False)
{
    echo "Not yet created. Waiting for 10 seconds"
    Start-Sleep -s 10
    $cert = az keyvault certificate show --vault-name $KeyVault.name --name $KEYVAULT_CERT_NAME
}
echo "Certificate found!"

# 4. Destroy Terraform SSLIssuing
echo "4. Destroy unneccessary infrastructure again"
cd SSLIssuing
terraform init
terraform destroy -var "keyVault_name=$($KeyVault.name)" -var "keyVault_rg=$($KeyVault.resource_group)" `
-var "your_certificate_email=$YOUR_CERTIFICATE_EMAIL"  -var "your_domain=$YOUR_DOMAIN" `
-var "trafficmanager_name=$($TrafficManager.name)"  -var "trafficmanager_rg=$($TrafficManager.resource_group)" `
-var "aci_rg=$($KeyVault.resource_group)"  -var "aci_location=$($KeyVault.location)" `
-var "keyVault_cert_name=$KEYVAULT_CERT_NAME" -var "production=$PRODUCTION" $AUTOAPPROVE
cd ..
