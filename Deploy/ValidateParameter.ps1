<#
.SYNOPSIS
Check for correct choice of Parameters and if Bot name is available

.DESCRIPTION
Check for correct choice of Parameters and if Bot name is available

This script will do following steps:

1. If Bot name provided check if Azure Services (KeyVault, CosmosDB, TrafficManager) are available under this name
2. Check if logged into Azure CLI
3. Check various combinations of possible parameters concerning the SSL certificate
-- if PFX_FILE_LOCATION is supplied file has to exist
-- -- if YOUR_DOMAIN is empty use _botname_.trafficmanager.net as Bot endpoint
-- -- if YOUR_DOMAIN is provided use this custom domain name as Bot endpoint
-- -- PFX_FILE_PASSWORD can be an empty password and therefore is always optional
-- if YOUR_CERTIFICATE_EMAIL is supplied
-- -- if YOUR_DOMAIN is empty issue SSL for _botname_.trafficmanager.net and use as Bot endpoint
-- -- if YOUR_DOMAIN is provided issue SSL for this domain name and use as Bot endpoint

After the script is successfully executed it should be ensured that the deployment should be succesful

.EXAMPLE
.\ValidateParameter.ps1 -BOT_NAME myuniquebot -YOUR_CERTIFICATE_EMAIL me@mymail.com -YOUR_DOMAIN bot.mydomain.com 

.INPUTS
None. You cannot pipe objects.

.OUTPUTS
System.Boolean. Returns $True if the check was successful

#>
param(
    # Unique Bot Name -> will be used as DNS prefix for CosmosDB, TrafficManager and KeyVault
    [Parameter(HelpMessage="Unique Bot Name -> will be used as DNS prefix for CosmosDB, TrafficManager and KeyVault")]
    [string] $BOT_NAME,

    # Mail to be associated with Let's Encrypt certificate
    [Parameter(HelpMessage="Mail to be associated with Let's Encrypt certificate")]
    [string] $YOUR_CERTIFICATE_EMAIL,

    # The domain (CN) name for the SSL certificate
    [Parameter(HelpMessage="The domain (CN) name for the SSL certificate")]
    [string] $YOUR_DOMAIN,

    # SSL CERT (PFX Format) file location
    [Parameter(HelpMessage="SSL CERT (PFX Format) file location")]
    [string] $PFX_FILE_LOCATION,
    
    # SSL CERT (PFX Format) file password
    [Parameter(HelpMessage="SSL CERT (PFX Format) file password")]
    [string] $PFX_FILE_PASSWORD,

    # Terraform and SSL creation Automation Flag. $False -> Interactive, Approval $True -> Automatic Approval
    [Parameter(HelpMessage="Terraform and SSL creation Automation Flag. `$False -> Interactive, Approval `$True -> Automatic Approval")]
    [bool] $AUTOAPPROVE = $False,

    # Flag to determine if run from within OneClickDeploy.ps1
    [Parameter(HelpMessage="Flag to determine if run from within OneClickDeploy.ps1")]
    [bool] $ALREADYCONFIRMED = $False,

    # To change existing infrastructure, e.g. skips DNS check. `$False -> first run/no infrastructure, `$True -> subsequent run, existing infrastructure
    [Parameter(HelpMessage="To change existing infrastructure, e.g. skips DNS check. `$False -> first run/no infrastructure, `$True -> subsequent run, existing infrastructure")]
    [bool] $RERUN = $False
)
# Import Helper functions
. "$($MyInvocation.MyCommand.Path -replace($MyInvocation.MyCommand.Name))\HelperFunctions.ps1"

# Check Bot Name, if provided
if ($BOT_NAME -ne "")
{
    if (-not ($BOT_NAME -match "^\w+$") -or $BOT_NAME.Length -gt 20)
    {
        Write-Host "### ERROR, Bot Name will be used for a lot of DNS prefixes and services please stick to alphanumeric between 8 and 20 characters."
        return $False
    } 
    elseif ($RERUN -eq $False) {
        # Check service name availability
        $dnscheck = $True
        # CosmosDB
        $dnscheck = (Check-ServiceAvailability -Service "CosmosDB" -FQDN "$BOT_NAME.documents.azure.com") -and $dnscheck 
        # Traffic Manager
        $dnscheck = (Check-ServiceAvailability -Service "TrafficManager" -FQDN "$BOT_NAME.trafficmanager.net") -and $dnscheck
        # KeyVault
        $dnscheck = (Check-ServiceAvailability -Service "KeyVault" -FQDN "$BOT_NAME.vault.azure.net") -and $dnscheck
        # Skipping checks for WebApp for now

        if (-not $dnscheck)
        {
            return $False
        }
    }
} 
else {
    # Check most likly executed after creation of Infrastructure, load TrafficManager values from Terraform run
    $TrafficManager = terraform output -state="$(Get-ScriptPath)/IaC/terraform.tfstate" -json trafficManager | ConvertFrom-Json
}

# Check Azure Login
$azureAccount = az account show | ConvertFrom-Json
if ($? -eq $False)
{
    Write-Host -ForegroundColor Red "### ERROR, az not logged in. Please log into Azure CLI first. Command 'az login'"
    return $False
}
if ($AUTOAPPROVE -eq $False -and $ALREADYCONFIRMED -eq $False)
{
    # Request for approval
    $confirm = Read-Host "### Are you sure you want to deploy to Azure Subscription '$($azureAccount.name)' (ID:$($azureAccount.id))? [y/n]"

    if ($confirm -ne "y")
    {
        return $False
    }
} 
elseif ($ALREADYCONFIRMED -eq $False) {
    # Informational note
    Write-Host -ForegroundColor Yellow "### Deploying to Azure Subscription '$($azureAccount.name)' (ID:$($azureAccount.id))"
}

if ($PFX_FILE_LOCATION -ne "")
{
    if (-not (Test-Path -Path $PFX_FILE_LOCATION)) {
        # User wants SSL Import but file could not be found
        Write-Host "### ERROR, PFX File with location '$PFX_FILE_LOCATION' does not exists."
        Write-Host "### If you want to import an existing SSL certificate please check the correct location of the file."
        Write-Host "### If you want to issue a new SSL certificate please remove the -PFX_FILE_LOCATION parameter for execution."

        return $False
    } else {
        return $True
    }
} else {
    # User wants to create a new certificate, check if preconditions are met. Reassure if not in Autoapprove mode
    if ($YOUR_CERTIFICATE_EMAIL -ne "")
    {
        # Validate eMail
        if (-not ($YOUR_CERTIFICATE_EMAIL -match "(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|""(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*"")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])"))
        {
            Write-Host "### ERROR: Please provide a valid mail for the -YOUR_CERTIFICATE_EMAIL parameter. Provided value ($YOUR_CERTIFICATE_EMAIL)"
            return $False
        } else {

            # Confirm SSL creation/issuing process
            if ($YOUR_DOMAIN -eq "")
            {
                # Use Traffic Manager Domain
                if ($BOT_NAME -eq "")
                {
                    $YOUR_DOMAIN = $TrafficManager.fqdn
                } else {
                    $YOUR_DOMAIN = "$BOT_NAME.trafficmanager.net"
                }
                
            }
            # SSL creation/issuing reassure
            if ($AUTOAPPROVE -eq $False -and $ALREADYCONFIRMED -eq $False)
            {
                $confirm = Read-Host "### Are you sure you want to issue a new SSL certificate for domain '$YOUR_DOMAIN'? [y/n]"
            } else {
                $confirm = "y"
            }
        
            if ($confirm -eq "y")
            {
                return $True
            } else {
                Write-Host "### Hint: If you want to issue a SSL certificate for a custom domain name please add the FQDN with the -YOUR_DOMAIN parameter."
                Write-Host "### Hint: If you want to import an existing SSL certificate please rerun the script with -PFX_FILE_LOCATION and -PFX_FILE_PASSWORD parameter."
                return $False
            }
        }
        

    } else {
        # Parameter combination check
        if ($YOUR_DOMAIN -ne "")
        {
            Write-Host "### ERROR, if you want to issue a SSL certificate please also provide your eMail Adress in -YOUR_CERTIFICATE_EMAIL parameter"
        } 
        if ($YOUR_DOMAIN -eq "")
        {
            Write-Host "### CAN'T CONTINUE, we don't know if you want to issue a SSL certificate or import one."
            Write-Host "### If you want to import an existing SSL certificate please provide the -PFX_FILE_LOCATION and -PFX_FILE_PASSWORD parameter."
            Write-Host "### If you want to issue a new SSL certificate please provide the -YOUR_CERTIFICATE_EMAIL"
            Write-Host "### If you want to issue a new SSL certificate for a Custom Domain Name (not trafficmanager.net) you also have to specify the FQDN in -YOUR_DOMAIN parameter."
        } 

        return $False
    }
}


