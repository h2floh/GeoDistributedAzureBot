###
#
# One Click Destroy for Geo Distributed Bot Solution
#
# This script will do following steps:
#
# 1. Read KeyVault information from current Terraform state
# 2. Export Certificate to file
# 3. Destroy rest of environment with Terraform
#
# After the script is successfully executed the bot should be in a usable state
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

    [Parameter(HelpMessage="Terraform Automation Flag. 0 -> Interactive, Approval 1 -> Automatic Approval")]
    [string] $AUTOAPPROVE = "0"
)

# # 1. Read values from Terraform IaC run (Bot deployment scripts)
# echo "1. Read values from Terraform IaC run (Bot deployment scripts)"
# $KeyVault = terraform output -state=".\IaC\terraform.tfstate" -json keyVault | ConvertFrom-Json

# # 2. Export SSL Certificate
# echo "Export SSL Certificate from KeyVault"
# # with help from https://blogs.technet.microsoft.com/kv/2016/09/26/get-started-with-azure-key-vault-certificates/
# # retrieve from KeyVault
# $kvSecret = az keyvault certificate show --vault-name $KeyVault.name --name $KEYVAULT_CERT_NAME

# # Convert to X509 cert object
# $kvSecretBytes = [System.Convert]::FromBase64String($kvSecret.value)
# $certCollection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
# $certCollection.Import($kvSecretBytes,$null,[System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)
# # Generate Password 
# $password = [System.Web.Security.Membership]::GeneratePassword(13,5)
# # Create Byte Object
# $protectedCertificateBytes = $certCollection.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12, $password)
# # Save to file
# Set-Content -Path $PFX_FILE_LOCATION -AsByteStream -Value $protectedCertificateBytes

# echo "Certificate successfully exported to $PFX_FILE_LOCATION`nImport Password for PFX file is: $password`n`n(please store and keep both somewhere for reuse)"

# 3. Destroy all infrastructure
if ($AUTOAPPROVE -eq "1")
{
    $AUTOAPPROVE = "-auto-approve"
} else {
    $AUTOAPPROVE = ""
}

cd IaC
terraform init
terraform destroy -var "bot_name=$BOT_NAME" -var "microsoft_app_id=$MICROSOFT_APP_ID" -var "microsoft_app_secret=$MICROSOFT_APP_SECRET" $AUTOAPPROVE
cd ..