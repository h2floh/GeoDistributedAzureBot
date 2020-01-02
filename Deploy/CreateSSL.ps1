<#
.SYNOPSIS
Issue new SSL certificate from Let's Encrypt

.DESCRIPTION
Issue new SSL certificate from Let's Encrypt

This script will do following steps:

1. Read values from previous Infrastructure Deployment run (Terraform & Bot Deployment) 
2. If custom domain is set, check if it points to TrafficManager DNS entry
3. Terraform execution to spin up container who issues SSL cert and stores in KeyVault
4. Check if certificate was created
5. Terraform destroy to clean up resources only need for SSL issuing

After the script is successfully executed the certificate should be stored in KeyVault

.EXAMPLE
.\CreateSSL.ps1 -YOUR_CERTIFICATE_EMAIL my@mymail.com -YOUR_DOMAIN bot.mydomain.com -LETS_ENCRYPT_STAGING $False -AUTOAPPROVE $True

.INPUTS
None. You cannot pipe objects.

.OUTPUTS
System.Boolean. Returns $True if executed successfully

#>
param(
    # Mail to be associated with Let's Encrypt certificate
    [Parameter(Mandatory=$true, HelpMessage="Mail to be associated with Let's Encrypt certificate")]
    [ValidatePattern("(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|""(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*"")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])")]
    [string] $YOUR_CERTIFICATE_EMAIL,

    # The domain (CN) name for the SSL certificate
    [Parameter(HelpMessage="The domain (CN) name for the SSL certificate")]
    [string] $YOUR_DOMAIN,


    # $True -> Use Let's Encrypt staging for script testing (Bot cannot be reached from Bot Framework Service) - Default: $False
    [Parameter(HelpMessage="`$True -> Use Let's Encrypt staging for script testing (Bot cannot be reached from Bot Framework Service) - Default: `$False")]
    [bool] $LETS_ENCRYPT_STAGING = $False,

    # Terraform Automation Flag. $False -> Interactive, Approval $True -> Automatic Approval
    [Parameter(HelpMessage="Terraform Automation Flag. `$False -> Interactive, Approval `$True -> Automatic Approval")]
    [bool] $AUTOAPPROVE = $False,

    # KeyVault certificate key name
    [Parameter(HelpMessage="KeyVault certificate key name")]
    [string] $KEYVAULT_CERT_NAME = "SSLcert",

    # Maximum wait time for DNS resolve and certificate generation in minutes. Default 15 min
    [Parameter(HelpMessage="Maximum wait time for DNS resolve and certificate generation in minutes. Default 15 min")]
    [int] $MAX_WAIT_TIME_MIN = 15
)
# Helper var
$success = $True
$loopcount = 0
$waitretrysec = 10
$loopmax = (60 * $MAX_WAIT_TIME_MIN ) / $waitretrysec
$terraformFolder = "SSLIssuing"
$iaCFolder = "IaC"
$PRODUCTION = 1
if ($LETS_ENCRYPT_STAGING) {
    $PRODUCTION = 0
} 

# Import Helper functions
. "$($MyInvocation.MyCommand.Path -replace($MyInvocation.MyCommand.Name))\HelperFunctions.ps1"
# Tell who you are (See HelperFunction.ps1)
Write-WhoIAm

# 1. Read values from Terraform IaC run (Bot deployment scripts)
Write-Host "## 1. Read values from Terraform IaC run (Bot deployment scripts)"
$KeyVault = terraform output -state="$(Get-ScriptPath)/$iaCFolder/terraform.tfstate" -json keyVault | ConvertFrom-Json
$success = $success -and $?
$TrafficManager = terraform output -state="$(Get-ScriptPath)/$iaCFolder/terraform.tfstate" -json trafficManager | ConvertFrom-Json
$success = $success -and $?

# 2. If custom domain is set, check if it points to TrafficManager DNS entry
Write-Host "## 2. If custom domain is set, check if it points to TrafficManager DNS entry"

if ($YOUR_DOMAIN -eq "")
{
    # If no custom domain is given use DNS of Traffic Manager Profile
    $YOUR_DOMAIN = $TrafficManager.fqdn
} 
elseif ($YOUR_DOMAIN -ne $TrafficManager.fqdn) {
    # create dummy endpoint in TrafficManager (this is needed to ensure a resolving DNS), change healthcheck to 80 HTTP (will succeed for Bing with HTTP redirect and work for standalone Certbot)
    az network traffic-manager profile update --name $TrafficManager.name --resource-group $TrafficManager.resource_group --path "/" --port 80 --protocol "HTTP" > $null
    az network traffic-manager endpoint create --profile-name $TrafficManager.name --resource-group $TrafficManager.resource_group --name dummy --type externalEndpoints --endpoint-location koreacentral --target www.bing.com > $null

    # If a custom domain is set check if CNAME to TrafficManager FQDN is set
    # Not working in PowerShellCore: $resolved = Resolve-DnsName -Name $YOUR_DOMAIN -DnsOnly 2> $null
    # Changing to nslookup
    $resolved = nslookup $YOUR_DOMAIN 2> $null
    while (((($resolved | Select-String $TrafficManager.fqdn).Length -eq 0)) -and ($loopcount -le $loopmax))
    {
        $loopcount++
        Write-Host "### WARNING, there is no CNAME entry for domain '$YOUR_DOMAIN' pointing to '$($TrafficManager.fqdn)'."
        Write-Host "### Please check your DNS entry, or create the missing CNAME entry. Sleeping for $waitretrysec seconds and try again..."
        Start-Sleep -s $waitretrysec

        # Not working in PowerShellCore: $resolved = Resolve-DnsName -Name $YOUR_DOMAIN -DnsOnly 2> $null
        # Changing to nslookup
        $resolved = nslookup $YOUR_DOMAIN 2> $null
    } 

    # delete dummy endpoint again
    az network traffic-manager endpoint delete --name dummy --type externalEndpoints --profile-name $TrafficManager.name --resource-group $TrafficManager.resource_group > $null
    # TrafficManager healthcheck profile will be changed back in SSLActivate Terraform (ActivateSSL.ps1)
}

# 3. Apply Terraform for SSLIssuing
Write-Host "## 3. Apply Terraform for SSLIssuing"

# Terraform Init
terraform init "$(Get-ScriptPath)/$terraformFolder"
# Terraform Apply
terraform apply -var "keyVault_name=$($KeyVault.name)" -var "keyVault_rg=$($KeyVault.resource_group)" `
-var "your_certificate_email=$YOUR_CERTIFICATE_EMAIL"  -var "your_domain=$YOUR_DOMAIN" `
-var "trafficmanager_name=$($TrafficManager.name)"  -var "trafficmanager_rg=$($TrafficManager.resource_group)" `
-var "aci_rg=$($KeyVault.resource_group)"  -var "aci_location=$($KeyVault.location)" `
-var "keyVault_cert_name=$KEYVAULT_CERT_NAME" `
-var "production=$PRODUCTION" -state="$(Get-ScriptPath)/$terraformFolder/terraform.tfstate" $(Get-TerraformAutoApproveFlag $AUTOAPPROVE) "$(Get-ScriptPathTerraformApply)/$terraformFolder"
$success = $success -and $?

# 4. Check for creation of certificate
Write-Host "## 4. Check for availability of certificate"
$loopcount = 0
az keyvault certificate show --vault-name $KeyVault.name --name $KEYVAULT_CERT_NAME > $null 2> $1
while ($? -eq $False -and ($loopcount -le $loopmax))
{
    $loopcount++
    Write-Host "Not yet created. Waiting for $waitretrysec seconds"
    Start-Sleep -s $waitretrysec
    az keyvault certificate show --vault-name $KeyVault.name --name $KEYVAULT_CERT_NAME > $null 2> $1
}
$success = $success -and $?
Write-Host "## Certificate found!"

# 5. Destroy Terraform SSLIssuing
Write-Host "## 5. Destroy unneccessary infrastructure again"

# Terraform Init (should not be needed)
terraform init "$(Get-ScriptPath)/$terraformFolder"
# Terraform Destroy
terraform destroy -var "keyVault_name=$($KeyVault.name)" -var "keyVault_rg=$($KeyVault.resource_group)" `
-var "your_certificate_email=$YOUR_CERTIFICATE_EMAIL"  -var "your_domain=$YOUR_DOMAIN" `
-var "trafficmanager_name=$($TrafficManager.name)"  -var "trafficmanager_rg=$($TrafficManager.resource_group)" `
-var "aci_rg=$($KeyVault.resource_group)"  -var "aci_location=$($KeyVault.location)" `
-var "keyVault_cert_name=$KEYVAULT_CERT_NAME" `
-var "production=$PRODUCTION" -state="$(Get-ScriptPath)/$terraformFolder/terraform.tfstate" $(Get-TerraformAutoApproveFlag $AUTOAPPROVE) "$(Get-ScriptPathTerraformApply)/$terraformFolder"
$success = $success -and $?

# Return execution status
Write-ExecutionStatus -success $success
exit $success