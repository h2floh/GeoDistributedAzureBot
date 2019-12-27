###
#
# Import existing or create/issue new SSL certificate
#
# This script will do following steps:
#
#   In Import Mode
#   1. Execute Import script
#
#   In Issuing Mode
#   1. Execute Issuing script
#
# 2. Terraform execution to activate certificate
#
# After the script is successfully executed the Bot should be in a usable from within Bot Framework Service (WebChat) and Emulator
#
###
# Parameters
param(
    # Only needed in Issuing Mode
    [Parameter(HelpMessage="Mail to be associated with Let's Encrypt certificate")]
    [string] $YOUR_CERTIFICATE_EMAIL,

    # Only needed in Issuing Mode
    [Parameter(HelpMessage="The domain (CN) name for the SSL certificate")]
    [string] $YOUR_DOMAIN,

    [Parameter(HelpMessage="SSL CERT (PFX Format) file location")]
    [string] $PFX_FILE_LOCATION,
    
    [Parameter(HelpMessage="SSL CERT (PFX Format) file password")]
    [string] $PFX_FILE_PASSWORD,

    [Parameter(HelpMessage="KeyVault certificate name")]
    [string] $KEYVAULT_CERT_NAME = "SSLcert",

    [Parameter(HelpMessage="Terraform and SSL creation Automation Flag. `$False -> Interactive, Approval `$True -> Automatic Approval")]
    [bool] $AUTOAPPROVE = $False,

    [Parameter(HelpMessage="Flag to determine if run from within OneClickDeploy.ps1")]
    [bool] $ALREADYCONFIRMED = $False,

    [Parameter(HelpMessage="Force Reimport or Reissuing if certificate already exists")]
    [bool] $FORCE = $False,

    [Parameter(HelpMessage="To change existing infrastructure, e.g. skips DNS check. `$False -> first run/no infrastructure, `$True -> subsequent run, existing infrastructure")]
    [bool] $RERUN = $False
)
# Tell who you are
Write-Host "`n`n# Executing $($MyInvocation.MyCommand.Name)"

# Helper Variable
$success = $True
$sslexists = $False

# Validate Input parameter combination
$validationresult = .\ValidateParameter.ps1 -YOUR_CERTIFICATE_EMAIL $YOUR_CERTIFICATE_EMAIL -YOUR_DOMAIN $YOUR_DOMAIN -PFX_FILE_LOCATION $PFX_FILE_LOCATION -PFX_FILE_PASSWORD $PFX_FILE_PASSWORD -AUTOAPPROVE $AUTOAPPROVE -ALREADYCONFIRMED $ALREADYCONFIRMED

# Check if SSL Certificate exists
if ($FORCE -eq $False) 
{
    $sslexists = .\CheckExistingSSL.ps1 -KEYVAULT_CERT_NAME $KEYVAULT_CERT_NAME
}

if ($validationresult -and (-not $sslexists))
{
    # 0. Deactivate SSL Endpoints (needed if you want to change the SSL for a <yourbot>.trafficmanager.net domain - not needed for custom domain)
    if ($FORCE -eq $True)
    {
        Write-Host "## 0. Deactivate SSL Endpoints"
        .\DeactivateSSL.ps1
        $success = $success -and $LASTEXITCODE
    }

    # 1. Import SSL Certificate to KeyVault
    Write-Host "## 1. Import SSL Certificate to KeyVault"
    if (Test-Path -Path $PFX_FILE_LOCATION)
    {
        # Import Mode
        Write-Host "### Import Mode, load local PFX file"
        # Execute Import Script
        .\ImportSSL.ps1 -PFX_FILE_LOCATION $PFX_FILE_LOCATION -PFX_FILE_PASSWORD $PFX_FILE_PASSWORD -KEYVAULT_CERT_NAME $KEYVAULT_CERT_NAME
        $success = $success -and $LASTEXITCODE
    }
    else {
        # Issuing Mode
        Write-Host "### Issuing Mode, issue new certificate and directly upload it to KeyVault from within a container"
        .\CreateSSL.ps1 -YOUR_CERTIFICATE_EMAIL $YOUR_CERTIFICATE_EMAIL -YOUR_DOMAIN $YOUR_DOMAIN -KEYVAULT_CERT_NAME $KEYVAULT_CERT_NAME -AUTOAPPROVE $AUTOAPPROVE
        $success = $success -and $LASTEXITCODE
    }
    
}
elseif ($sslexists -eq $True) {
    Write-Host "### WARNING, SSL Certificate with KeyVault name-key '$KEYVAULT_CERT_NAME' already exists.`n### If you want to recreate/upload a new one please use -FORCE `$True parameter."
}

if ((($success -eq $True) -and ($validationresult -eq $True)) -or ($RERUN -eq $True))
{
    # 2. Activate SSL Endpoint
    Write-Host "## 2. Activate SSL Endpoints"
    .\ActivateSSL.ps1 -YOUR_DOMAIN $YOUR_DOMAIN -AUTOAPPROVE $AUTOAPPROVE
    $success = $success -and $LASTEXITCODE
}

# Return execution status
exit $success