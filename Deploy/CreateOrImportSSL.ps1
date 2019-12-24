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
# After the script is successfully executed the bot should be in a usable from WebChat
#
###
# Parameters
param(
    # Only needed in Issuing Mode
    [Parameter(HelpMessage="Mail to be associated with Let's Encrypt certificate")]
    [ValidatePattern("(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|""(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*"")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])")]
    [string] $YOUR_CERTIFICATE_EMAIL,

    # Only needed in Issuing Mode
    [Parameter(HelpMessage="The domain (CN) name for the SSL certificate")]
    [string] $YOUR_DOMAIN,

    [Parameter(HelpMessage="SSL CERT (PFX Format) file location")]
    [string] $PFX_FILE_LOCATION = "../SSL/sslcert.pfx",
    
    [Parameter(HelpMessage="SSL CERT (PFX Format) file password")]
    [string] $PFX_FILE_PASSWORD,

    [Parameter(HelpMessage="Terraform Automation Flag. 0 -> Interactive, Approval 1 -> Automatic Approval")]
    [string] $AUTOAPPROVE = "0"
)


if (Test-Path -Path $PFX_FILE_LOCATION)
{
    # Import Mode
    echo "### Import Mode"
    # Execute Import Script
    .\ImportSSL.ps1 -PFX_FILE_LOCATION $PFX_FILE_LOCATION -PFX_FILE_PASSWORD $PFX_FILE_PASSWORD 
}
else {
    # Issuing Mode
    echo "### Issuing Mode"
    # Execute Issuing Script
    .\CreateSSL.ps1 -YOUR_CERTIFICATE_EMAIL $YOUR_CERTIFICATE_EMAIL -YOUR_DOMAIN $YOUR_DOMAIN -AUTOAPPROVE $AUTOAPPROVE -PRODUCTION 0
}

# 2. Activate SSL Endpoint
.\ActivateSSL.ps1 -YOUR_DOMAIN $YOUR_DOMAIN -AUTOAPPROVE $AUTOAPPROVE