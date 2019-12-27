###
#
# Export SSL from 
#
# This script will do following steps:
#
# 1. Read KeyVault information from current Terraform state
# 2. Export Certificate to file 
#
# After the script is successfully executed the SSL certificate should be exported
#
###
# Parameters
param(
    [Parameter(HelpMessage="SSL CERT (PFX Format) file location")]
    [string] $PFX_FILE_LOCATION = "../SSL/sslcert.pfx",

    [Parameter(HelpMessage="KeyVault certificate name")]
    [string] $KEYVAULT_CERT_NAME = "SSLcert"
)
# Helper var
$success = $True

# Tell who you are
Write-Host "`n`n# Executing $($MyInvocation.MyCommand.Name)"

# 1. Read values from Terraform IaC run (Bot deployment scripts)
Write-Host "## 1. Read values from Terraform IaC run (Bot deployment scripts)"
$KeyVault = terraform output -state=".\IaC\terraform.tfstate" -json keyVault | ConvertFrom-Json

# 2. Export SSL Certificate
Write-Host "## 2. Export SSL Certificate from KeyVault"
# with help from https://blogs.technet.microsoft.com/kv/2016/09/26/get-started-with-azure-key-vault-certificates/
# retrieve from KeyVault
$kvSecret = az keyvault secret show --vault-name $KeyVault.name --name $KEYVAULT_CERT_NAME | ConvertFrom-JSON
$success = $success -and $?

# Convert to X509 cert object
$kvSecretBytes = [System.Convert]::FromBase64String($kvSecret.value)
$certCollection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
$certCollection.Import($kvSecretBytes, $null ,[System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)

# Change to Read-Host
$password = Read-Host "### Please enter a password for the PFX file" -AsSecureString

# Create Byte Object
$protectedCertificateBytes = $certCollection.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12, [System.Runtime.InteropServices.marshal]::PtrToStringAuto([System.Runtime.InteropServices.marshal]::
SecureStringToBSTR($password)))

# Save to file
Set-Content -Path $PFX_FILE_LOCATION -AsByteStream -Value $protectedCertificateBytes
$success = $success -and $?

Write-Host "### Certificate successfully exported to $PFX_FILE_LOCATION`n(please store and keep it somewhere for reuse)"

# Return execution status
exit $success