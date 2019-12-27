###
#
# Check for correct choice of Parameters
#
###
# Parameters
param(
    [Parameter(HelpMessage="Unique Bot Name -> will be used as DNS prefix for a lot of services so it has to be very unique")]
    [string] $BOT_NAME,

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

    [Parameter(HelpMessage="Terraform and SSL creation Automation Flag. `$False -> Interactive, Approval `$True -> Automatic Approval")]
    [bool] $AUTOAPPROVE = $False,

    [Parameter(HelpMessage="Flag to determine if run from within OneClickDeploy.ps1")]
    [bool] $ALREADYCONFIRMED = $False,

    [Parameter(HelpMessage="To change existing infrastructure, e.g. skips DNS check. `$False -> first run/no infrastructure, `$True -> subsequent run, existing infrastructure")]
    [bool] $RERUN = $False
)

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
        $dnscheck = (.\CheckServiceAvailability.ps1 -Service "CosmosDB" -FQDN "$BOT_NAME.documents.azure.com") -and $dnscheck 
        # Traffic Manager
        $dnscheck = (.\CheckServiceAvailability.ps1 -Service "TrafficManager" -FQDN "$BOT_NAME.trafficmanager.net") -and $dnscheck
        # KeyVault
        $dnscheck = (.\CheckServiceAvailability.ps1 -Service "KeyVault" -FQDN "$BOT_NAME.vault.azure.net") -and $dnscheck
        # Skipping checks for WebApp for now

        if (-not $dnscheck)
        {
            return $False
        }
    }
} 
else {
    # Check most likly executed after creation of Infrastructure, load TrafficManager values from Terraform run
    $TrafficManager = terraform output -state=".\IaC\terraform.tfstate" -json trafficManager | ConvertFrom-Json
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
                $confirm = Read-Host "Are you sure you want to issue a new SSL certificate for domain '$YOUR_DOMAIN'? [y/n]"
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


