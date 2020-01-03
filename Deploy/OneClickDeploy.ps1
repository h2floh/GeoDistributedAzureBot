<#
.SYNOPSIS
One Click Deployment for Geo Distributed Bot Solution

.DESCRIPTION
One Click Deployment for Geo Distributed Bot Solution

This script will do following steps:

1. Deploy Infrastructure
2. Deploy, train and publish LUIS
3. Deploy Bot Code
4. Create or Import SSL certificate and activate WebApps and TrafficManager endpoints

After the script is successfully executed the bot should be in a usable state

.EXAMPLE
.\OneClickDeploy.ps1 -BOT_NAME myuniquebot -YOUR_CERTIFICATE_EMAIL me@mymail.com -AUTOAPPROVE $True

.EXAMPLE
.\OneClickDeploy.ps1 -BOT_NAME myuniquebot -YOUR_CERTIFICATE_EMAIL me@mymail.com -YOUR_DOMAIN bot.mydomain.com -AUTOAPPROVE $True

.EXAMPLE
.\OneClickDeploy.ps1 -BOT_NAME myuniquebot -PFX_FILE_LOCATION ../../ssl.pfx -PFX_FILE_PASSWORD mostsecure -AUTOAPPROVE $True

.EXAMPLE
.\OneClickDeploy.ps1 -BOT_NAME myuniquebot -PFX_FILE_LOCATION ../../ssl.pfx -PFX_FILE_PASSWORD mostsecure -YOUR_DOMAIN bot.mydomain.com -AUTOAPPROVE $True

.INPUTS
None. You cannot pipe objects.

.OUTPUTS
System.Boolean. Returns $True if executed successfully

#>
param(
    # Unique Bot Name -> will be used as DNS prefix for CosmosDB, TrafficManager and KeyVault
    [Parameter(Mandatory=$true, HelpMessage="Unique Bot Name -> will be used as DNS prefix for CosmosDB, TrafficManager and KeyVault")]
    [ValidatePattern("^\w+$")]
    [string] $BOT_NAME,

    # Regions to deploy the Bot to - Default: koreacentral, southeastasia
    [Parameter(HelpMessage="Regions to deploy the Bot to - Default: koreacentral, southeastasia")]
    [string[]] $BOT_REGIONS = @("koreacentral", "southeastasia"),

    # Region used for global services - Default: japaneast
    [Parameter(HelpMessage="Region used for global services - Default: japaneast")]
    [string] $BOT_GLOBAL_REGION = "japaneast",

    # Mail to be associated with Let's Encrypt certificate
    [Parameter(HelpMessage="Mail to be associated with Let's Encrypt certificate")]
    [ValidatePattern("(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|""(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*"")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])")]
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

    # Terraform and SSL creation Automation Flag. $False -> Interactive, Approval $True -> Automatic Approval - Default: $False
    [Parameter(HelpMessage="Terraform and SSL creation Automation Flag. `$False -> Interactive, Approval `$True -> Automatic Approval - Default: `$False")]
    [bool] $AUTOAPPROVE = $False,

    # To change existing infrastructure, e.g. skips DNS check. $False -> first run/no infrastructure, $True -> subsequent run, existing infrastructure - Default: $False
    [Parameter(HelpMessage="To change existing infrastructure, e.g. skips DNS check. `$False -> first run/no infrastructure, `$True -> subsequent run, existing infrastructure - Default: `$False")]
    [bool] $RERUN = $False
)
# Helper var
$success = $True
# Import Helper functions
. "$($MyInvocation.MyCommand.Path -replace($MyInvocation.MyCommand.Name))\HelperFunctions.ps1"
# Tell who you are (See HelperFunctions.ps1)
Write-WhoIAm

# Validate Input parameter combination
$validationresult = & "$(Get-ScriptPath)\ValidateParameter.ps1" -BOT_NAME $BOT_NAME -YOUR_CERTIFICATE_EMAIL $YOUR_CERTIFICATE_EMAIL -YOUR_DOMAIN $YOUR_DOMAIN -PFX_FILE_LOCATION $PFX_FILE_LOCATION -PFX_FILE_PASSWORD $PFX_FILE_PASSWORD -AUTOAPPROVE $AUTOAPPROVE -RERUN $RERUN

if ($validationresult)
{
    # Execute first Terraform to create the infrastructure
    & "$(Get-ScriptPath)\DeployInfrastructure.ps1" -BOT_NAME $BOT_NAME -BOT_REGIONS $BOT_REGIONS -BOT_GLOBAL_REGION $BOT_GLOBAL_REGION -AUTOAPPROVE $AUTOAPPROVE
    $success = $success -and $LASTEXITCODE

    # Execute LUIS Train & Deploy
    if ($success)
    {
        & "$(Get-ScriptPath)\DeployLUIS.ps1"
        $success = $success -and $LASTEXITCODE
    }
    
    # Deploy the Bot
    if ($success)
    {
        & "$(Get-ScriptPath)\DeployBot.ps1"
        $success = $success -and $LASTEXITCODE
    }

    # Import or issue a SSL certificate and activate it in WebApps and connect WebApps to TrafficManager
    if ($success)
    {
        & "$(Get-ScriptPath)\CreateOrImportSSL.ps1" -YOUR_CERTIFICATE_EMAIL $YOUR_CERTIFICATE_EMAIL -YOUR_DOMAIN $YOUR_DOMAIN -LETS_ENCRYPT_STAGING $LETS_ENCRYPT_STAGING -PFX_FILE_LOCATION $PFX_FILE_LOCATION -PFX_FILE_PASSWORD $PFX_FILE_PASSWORD -AUTOAPPROVE $AUTOAPPROVE -RERUN $RERUN -ALREADYCONFIRMED $True
        $success = $success -and $LASTEXITCODE
    }

    # Display the WebChat link (local & online version)
    if ($success)
    {
        & "$(Get-ScriptPath)\RetrieveWebChatLink.ps1"
        $success = $success -and $LASTEXITCODE
    }
}

# Check write execution process
if ($success -eq $False -or $validationresult -eq $False)
{
    # Additional Helper message
    Write-Host -ForegroundColor Red "`n`n# ERROR Occured while execution. Please check your output for errors and rerun the script or scriptlets.`n# Include the '-RERUN `$True' flag in case the execution of script 'DeployInfrastructure.ps1' was already successful."
} else {
    Write-ExecutionStatus -success $success
}

exit $success