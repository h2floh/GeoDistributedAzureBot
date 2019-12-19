# Issuing Cert Steps
#
# Parameters
param(
    [Parameter(Mandatory=$true, HelpMessage="Mail to be associated with Let's Encrypt certificate")]
    [ValidatePattern("(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|""(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*"")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])")]
    [string] $YOUR_CERTIFICATE_EMAIL,

    [Parameter(Mandatory=$true, HelpMessage="The domain (CN) name for the SSL certificate")]
    [string] $YOUR_DOMAIN,

    [Parameter(Mandatory=$true, HelpMessage="Unique Bot Name -> Traffic Manager DNS prefix")]
    [string] $BOT_NAME,

    [Parameter(Mandatory=$true, HelpMessage="Export password for generated SSL(PFX) file")]
    [string] $PFX_EXPORT_PASSWORD,

    [Parameter(HelpMessage="Local file name for generated SSL(PFX) file")]
    [string] $pfx_file_name = "letsencrypt.pfx",

    [Parameter(HelpMessage="ARM resource group for Traffic Manager and Container Instance deployment")]
    [string] $resource_group = "rg-geobot-global",
    
    [Parameter(HelpMessage="Azure region for the resource_group parameter")]
    [string] $location = "japaneast",
    
    [Parameter(HelpMessage="Docker image to be run on Azure Container Instances")]
    [string] $docker_image = "h2floh/letsencrypt:auto",

    [Parameter(HelpMessage="Flag if production or stage of Let's Encrypt will be used. 0 -> Staging 1 -> Production")]
    [string] $PRODUCTION = "1"
)

# Other Variables
$aciname = Get-Random | Out-String -NoNewline
$dnslabel = Get-Random | Out-String -NoNewline
$aci_fqdn="$dnslabel.$location.azurecontainer.io"

# 1. Create Traffic Manager and Endpoint to ACI (when it not exists)
echo "Create Traffic Manager Profile"
az network traffic-manager profile create -g $resource_group -n $BOT_NAME --routing-method Performance --unique-dns-name $BOT_NAME

echo "Create Traffic Manager Endpoint"
az network traffic-manager endpoint create -g $resource_group --profile-name $BOT_NAME -n LetsEncrypt --type externalEndpoints --endpoint-location $location --target $aci_fqdn --endpoint-status enabled

# 2. Run ACI Container
echo "Spin up customized Certbot container"
az container create --name $aciname -g $resource_group --location $location --image $docker_image --ip-address public --dns-name-label $dnslabel --environment-variables YOUR_CERTIFICATE_EMAIL=$YOUR_CERTIFICATE_EMAIL YOUR_DOMAIN=$YOUR_DOMAIN PRODUCTION=$PRODUCTION --secure-environment-variables PFX_EXPORT_PASSWORD=$PFX_EXPORT_PASSWORD --restart-policy never

# 3. Wait for 1 min
echo "Wait for 60 seconds for certbot to complete work"
Start-Sleep -seconds 60

# 4. Copy data in BASE64 from container (bad workaround)
echo "Copy data from container (workaround for missing file copy feature in ACI)"
az container exec --name $aciname -g $resource_group --exec-command "/base64.sh" > sslcert.base

# 5. Load data clean it (remove newlines) and decode it back to binary
echo "Clean data and save in pfx format (workaround for missing file copy feature in ACI)"
try {
    $cert64unclean = Get-Content -Path sslcert.base | Out-String 
    $cert64clean = $cert64unclean -replace [Environment]::NewLine,""
    $certbyte =  [System.Convert]::FromBase64String($cert64clean)
    Set-Content -Path $pfx_file_name -AsByteStream -Value $certbyte
}
catch [FormatException] {
    echo "Container could not create pfx file. Please check container.log"
}

# 6. Save the container log check the container logs by uncommenting this line
echo "Saving container logs for error check"
az container logs --name $aciname -g $resource_group >> container.log

# 7. Delete ACI
echo "Clean up... (deleting ACI and Traffic Manager Endpoint)"
az container delete --name $aciname -g $resource_group -y
az network traffic-manager endpoint delete -g $resource_group --profile-name $BOT_NAME -n LetsEncrypt --type externalEndpoints