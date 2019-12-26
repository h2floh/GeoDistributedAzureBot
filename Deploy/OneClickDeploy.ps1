###
#
# One Click Deployment for Geo Distributed Bot Solution
#
# This script will do following steps:
#
# 1. Deploy Infrastructure
# 2. Deploy, train and publish LUIS
# 3. Deploy Bot Code
# 4. Create or Import SSL certificate and activate WebApps and TrafficManager endpoints
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

    # Only needed in Issuing Mode (CreateSSL.ps1)
    [Parameter(HelpMessage="Mail to be associated with Let's Encrypt certificate")]
    [ValidatePattern("(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|""(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*"")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])")]
    [string] $YOUR_CERTIFICATE_EMAIL,

    # Only needed in Issuing Mode (CreateSSL.ps1)
    [Parameter(HelpMessage="The domain (CN) name for the SSL certificate")]
    [string] $YOUR_DOMAIN,

    # Only needed in Import Mode (ImportSSL.ps1)
    [Parameter(HelpMessage="SSL CERT (PFX Format) file location")]
    [string] $PFX_FILE_LOCATION,

    # Only needed in Import Mode (ImportSSL.ps1)
    [Parameter(HelpMessage="SSL CERT (PFX Format) file password")]
    [string] $PFX_FILE_PASSWORD,

    [Parameter(HelpMessage="Terraform and SSL creation Automation Flag. `$False -> Interactive, Approval `$True -> Automatic Approval")]
    [bool] $AUTOAPPROVE = $False
)
# Tell who you are
Write-Host "`n`n# Executing $($MyInvocation.MyCommand.Name)"

# Validate Input parameter combination
$validationresult = .\ValidateParameter.ps1 -BOT_NAME $BOT_NAME -YOUR_CERTIFICATE_EMAIL $YOUR_CERTIFICATE_EMAIL -YOUR_DOMAIN $YOUR_DOMAIN -PFX_FILE_LOCATION $PFX_FILE_LOCATION -PFX_FILE_PASSWORD $PFX_FILE_PASSWORD -AUTOAPPROVE $AUTOAPPROVE

if ($validationresult)
{
    # Execute first Terraform to create the infrastructure
    .\DeployInfrastructure -BOT_NAME $BOT_NAME -MICROSOFT_APP_ID $MICROSOFT_APP_ID -MICROSOFT_APP_SECRET $MICROSOFT_APP_SECRET -AUTOAPPROVE $AUTOAPPROVE

    # Execute LUIS Train & Deploy
    .\DeployLUIS.ps1

    # Deploy the Bot
    .\DeployBot.ps1

    # Import or issue a SSL certificate and activate it in WebApps and connect WebApps to TrafficManager
    .\CreateOrImportSSL.ps1 -YOUR_CERTIFICATE_EMAIL $YOUR_CERTIFICATE_EMAIL -YOUR_DOMAIN $YOUR_DOMAIN -PFX_FILE_LOCATION $PFX_FILE_LOCATION -PFX_FILE_PASSWORD $PFX_FILE_PASSWORD -AUTOAPPROVE $AUTOAPPROVE -ALREADYCONFIRMED $True
}

