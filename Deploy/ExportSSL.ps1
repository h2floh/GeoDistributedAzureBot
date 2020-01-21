<#
.SYNOPSIS
Export SSL Certificate as PFX from KeyVault

.DESCRIPTION
Export SSL Certificate as PFX from KeyVault

This script will do following steps:

1. Read KeyVault information from current Terraform state
2. Export Certificate to file 

After the script is successfully executed the SSL certificate should be saved as PFX file

.EXAMPLE
.\ExportSSL.ps1

.INPUTS
None. You cannot pipe objects.

.OUTPUTS
System.Boolean. Returns $True if executed successfully

#>
param(
    # SSL CERT (PFX Format) file location - Default: SSL/<BOT_NAME>.pfx
    [Parameter(HelpMessage="SSL CERT (PFX Format) file location")]
    [string] $PFX_FILE_LOCATION,

    # KeyVault certificate key name
    [Parameter(HelpMessage="KeyVault certificate key name")]
    [string] $KEYVAULT_CERT_NAME = "SSLcert"
)
# Helper var
$success = $True
# Import Helper functions
. "$($MyInvocation.MyCommand.Path -replace($MyInvocation.MyCommand.Name))\HelperFunctions.ps1"
# Tell who you are (See HelperFunction.ps1)
Write-WhoIAm

# 1. Read values from Terraform IaC run (Bot deployment scripts)
Write-Host "## 1. Read values from Terraform IaC run (Bot deployment scripts)"
$KeyVault = Get-TerraformOutput("keyVault") | ConvertFrom-Json
$success = $success -and $?

# Set Default Values for Parameters
$PFX_FILE_LOCATION = Set-DefaultIfEmpty -VALUE $PFX_FILE_LOCATION -DEFAULT "$(Get-ScriptPath)/../SSL/$($KeyVault.name).pfx"

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

if ($PSVersionTable.Platform -eq "Win32NT")
{
    # Change to Read-Host
    $password = Read-Host "### Please enter a password for the PFX file" -AsSecureString
    # Create Byte Object
    $protectedCertificateBytes = $certCollection.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12, [System.Runtime.InteropServices.marshal]::PtrToStringAuto([System.Runtime.InteropServices.marshal]::SecureStringToBSTR($password)))
} else {
    # Change to Read-Host
    $password = Read-Host "### Please enter a password for the PFX file"
    # Create Byte Object
    $protectedCertificateBytes = $certCollection.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12, $password)
}

# Save to file
Set-Content -Path $PFX_FILE_LOCATION -AsByteStream -Value $protectedCertificateBytes
$success = $success -and $?

# Report
$pfxfile = Get-ItemProperty -Path $PFX_FILE_LOCATION
Write-Host "### Certificate successfully exported to $($pfxfile.FullName)`n(please store and keep it somewhere for reuse)"

# Return execution status
Write-ExecutionStatus -success $success
exit $success