<#
.SYNOPSIS
Import existing or create/issue new SSL certificate

.DESCRIPTION
Import existing or create/issue new SSL certificate

This script will do following steps:

1. Validate Parameters

2. Deactivate SSL Endpoints (in FORCE mode e.g. changing certificate or changing to custom domain name)

In Import Mode
  3. Execute Import script

In Issuing Mode
  3. Execute Issuing script

4. Terraform execution to activate certificate

After the script is successfully executed the Bot should be in a usable from within Bot Framework Service (WebChat) and Bot Emulator

.EXAMPLE
.\CreateOrImportSSL.ps1 -YOUR_CERTIFICATE_EMAIL my@mymail.com -YOUR_DOMAIN bot.mydomain.com -LETS_ENCRYPT_STAGING $False -AUTOAPPROVE $True

.EXAMPLE
.\CreateOrImportSSL.ps1 -PFX_FILE_LOCATION ../SSL/mybot.pfx -PFX_FILE_PASSWORD securesecret -AUTOAPPROVE $False

.INPUTS
None. You cannot pipe objects.

.OUTPUTS
System.Boolean. Returns $True if executed successfully

#>
param(
    # Mail to be associated with Let's Encrypt certificate
    [Parameter(HelpMessage="Mail to be associated with Let's Encrypt certificate")]
    [string] $YOUR_CERTIFICATE_EMAIL,

    # The domain (CN) name for the SSL certificate
    [Parameter(HelpMessage="The domain (CN) name for the SSL certificate")]
    [string] $YOUR_DOMAIN,

    # $True -> Use Let's Encrypt staging for script testing (Bot cannot be reached from Bot Framework Service) - Default: $False
    [Parameter(HelpMessage="`$True -> Use Let's Encrypt staging for script testing (Bot cannot be reached from Bot Framework Service) - Default: `$False")]
    [bool] $LETS_ENCRYPT_STAGING = $False,

    # SSL CERT (PFX Format) file location
    [Parameter(HelpMessage="SSL CERT (PFX Format) file location")]
    [string] $PFX_FILE_LOCATION,
    
    # SSL CERT (PFX Format) file password
    [Parameter(HelpMessage="SSL CERT (PFX Format) file password")]
    [string] $PFX_FILE_PASSWORD,

    # KeyVault certificate key name
    [Parameter(HelpMessage="KeyVault certificate key name")]
    [string] $KEYVAULT_CERT_NAME = "SSLcert",

    # Terraform and SSL creation Automation Flag. $False -> Interactive, Approval $True -> Automatic Approval
    [Parameter(HelpMessage="Terraform and SSL creation Automation Flag. `$False -> Interactive, Approval `$True -> Automatic Approval")]
    [bool] $AUTOAPPROVE = $False,

    # Flag to determine if run from within OneClickDeploy.ps1
    [Parameter(HelpMessage="Flag to determine if run from within OneClickDeploy.ps1")]
    [bool] $ALREADYCONFIRMED = $False,

    # Force Reimport or Reissuing if certificate already exists
    [Parameter(HelpMessage="Force Reimport or Reissuing if certificate already exists")]
    [bool] $FORCE = $False,

    # To change existing infrastructure, e.g. skips DNS check. $False -> first run/no infrastructure, $True -> subsequent run, existing infrastructure
    [Parameter(HelpMessage="To change existing infrastructure, e.g. skips DNS check. `$False -> first run/no infrastructure, `$True -> subsequent run, existing infrastructure")]
    [bool] $RERUN = $False
)
# Import Helper functions
. "$($MyInvocation.MyCommand.Path -replace($MyInvocation.MyCommand.Name))\HelperFunctions.ps1"
# Tell who you are (See HelperFunction.ps1)
Write-WhoIAm

# Helper Variable
$success = $True
$sslexists = $False

# Validate Input parameter combination
$validationresult = & "$(Get-ScriptPath)\ValidateParameter.ps1" -YOUR_CERTIFICATE_EMAIL $YOUR_CERTIFICATE_EMAIL -YOUR_DOMAIN $YOUR_DOMAIN -PFX_FILE_LOCATION $PFX_FILE_LOCATION -PFX_FILE_PASSWORD $PFX_FILE_PASSWORD -AUTOAPPROVE $AUTOAPPROVE -ALREADYCONFIRMED $ALREADYCONFIRMED

# Check if SSL Certificate exists
if ($FORCE -eq $False) 
{
    $sslexists = & "$(Get-ScriptPath)\CheckExistingSSL.ps1" -KEYVAULT_CERT_NAME $KEYVAULT_CERT_NAME
}

if ($validationresult -and (-not $sslexists))
{
    # 0. Deactivate SSL Endpoints (needed if you want to change the SSL for a <yourbot>.trafficmanager.net domain - not needed for custom domain)
    if ($FORCE -eq $True)
    {
        Write-Host "## 0. Deactivate SSL Endpoints"
        & "$(Get-ScriptPath)\DeactivateSSL.ps1"
        $success = $success -and $LASTEXITCODE
    }

    # 1. Import SSL Certificate to KeyVault
    Write-Host "## 1. Import SSL Certificate to KeyVault"
    if (Test-Path -Path $PFX_FILE_LOCATION)
    {
        # Import Mode
        Write-Host "### Import Mode, load local PFX file"
        # Execute Import Script
        & "$(Get-ScriptPath)\ImportSSL.ps1" -PFX_FILE_LOCATION $PFX_FILE_LOCATION -PFX_FILE_PASSWORD $PFX_FILE_PASSWORD -KEYVAULT_CERT_NAME $KEYVAULT_CERT_NAME
        $success = $success -and $LASTEXITCODE
    }
    else {
        # Issuing Mode
        Write-Host "### Issuing Mode, issue new certificate and directly upload it to KeyVault from within a container"
        & "$(Get-ScriptPath)\CreateSSL.ps1" -YOUR_CERTIFICATE_EMAIL $YOUR_CERTIFICATE_EMAIL -YOUR_DOMAIN $YOUR_DOMAIN -LETS_ENCRYPT_STAGING $LETS_ENCRYPT_STAGING -KEYVAULT_CERT_NAME $KEYVAULT_CERT_NAME -AUTOAPPROVE $AUTOAPPROVE
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
    & "$(Get-ScriptPath)\ActivateSSL.ps1" -YOUR_DOMAIN $YOUR_DOMAIN -AUTOAPPROVE $AUTOAPPROVE
    $success = $success -and $LASTEXITCODE
}

# Return execution status
Write-ExecutionStatus -success $success
exit $success