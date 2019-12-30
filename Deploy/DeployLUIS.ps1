###
#
# Deploy LUIS NLP application
# Remark: There is no support in the Terraform AzureRM provider to do this.
#
# This script will do following steps:
#
# 1. Get the authoring key from KeyVault (Azure CLI - Alternative: could be done with Terraform output)
# 2. Imports the application to LUIS.ai via LUIS JSON model and LUIS cli tool
# 3. Trains the application on LUIS.ai via LUIS cli tool
# 4. Publishes the application to production slot on LUIS.ai via LUIS cli tool
# 5. Sets the LUIS Application Id in KeyVault for distribution to Bot WebApp nodes (Azure CLI)
# 6. Prepares and imports data necessary for LUIS Endpoint & Key association REST API (using Azure CLI - due to feature lag in LUIS CLI) 
# 7. Loads LUIS Account names and resource group names from Terraform output (Terraform CLI)
# 8. Loops to associate every LUIS account with the LUIS application (cURL command)
#
# After successful execution the LUIS app is available trough all regionalized LUIS Cognitive Service endpoints from all created Bots/WebApps
#
###
# Parameters
param(
    [Parameter(HelpMessage="LUIS Application Name")]
    [string] $LUIS_APP_NAME = "AddressFinder",

    [Parameter(HelpMessage="LUIS Application Package file location (JSON)")]
    [string] $LUIS_APP_PACKAGE_LOCATION,

    [Parameter(HelpMessage="LUIS Authoring Key KeyVault secret name")]
    [string] $LUIS_KEYVAULT_KEY = "LUISAuthoringKey"
)
# Helper var
$success = $True
# Import Helper functions
. "$($MyInvocation.MyCommand.Path -replace($MyInvocation.MyCommand.Name))\HelperFunctions.ps1"
# Tell who you are (See HelperFunction.ps1)
Write-WhoIAm

# Set Default Values for Parameters
$LUIS_APP_PACKAGE_LOCATION = Set-DefaultIfEmpty -VALUE $LUIS_APP_PACKAGE_LOCATION -DEFAULT "$(Get-ScriptPath)/../GeoBot/GeoBot/CognitiveModels/AddressFinder.json"

# 1. Get the authoring key from KeyVault (Azure CLI - Alternative: could be done with Terraform output)
Write-Host "## 1. Get the authoring key from KeyVault (Azure CLI - Alternative: could be done with Terraform output)"
$keyVault = terraform output -state="$(Get-ScriptPath)/IaC/terraform.tfstate" -json keyVault | ConvertFrom-Json
$LUISauthKey=$(az keyvault secret show --vault-name $keyVault.name --name $LUIS_KEYVAULT_KEY --query 'value' -o tsv)
$success = $success -and $?

# 2. Imports the application to LUIS.ai via LUIS JSON model and LUIS cli tool
Write-Host "## 2. Imports the application to LUIS.ai via LUIS JSON model and LUIS cli tool"
$LUISAppInfo=$(luis list applications --authoringKey $LUISauthKey) | ConvertFrom-Json | Where-Object -FilterScript { $_.name -eq $LUIS_APP_NAME }
if ($null -ne $LUISAppInfo.id)
{
    Write-Host "### LUIS Application with ID $($LUISAppInfo.id) found. Using this id for updating..."
    luis update application --in $LUIS_APP_PACKAGE_LOCATION --appId $LUISAppInfo.id --authoringKey $LUISauthKey
    $success = $success -and $?
} else {
    Write-Host "### LUIS Application not found. Importing..."
    $LUISAppInfo=$(luis import application --in $LUIS_APP_PACKAGE_LOCATION --appName $LUIS_APP_NAME --authoringKey $LUISauthKey) | ConvertFrom-JSON
    $success = $success -and $?
}

# 3. Trains the application on LUIS.ai via LUIS cli tool
Write-Host "## 3. Trains the application on LUIS.ai via LUIS cli tool"
luis train version --appId $LUISAppInfo.id --versionId $LUISAppInfo.activeVersion --authoringKey $LUISauthKey --wait
$success = $success -and $?

# 4. Publishes the application to production slot on LUIS.ai via LUIS cli tool
Write-Host "## 4. Publishes the application to production slot on LUIS.ai via LUIS cli tool"
luis publish version --appId $LUISAppInfo.id --versionId $LUISAppInfo.activeVersion --staging false --authoringKey $LUISauthKey 
$success = $success -and $?

# 5. Sets the LUIS Application Id in KeyVault for distribution to Bot WebApp nodes (Azure CLI)
Write-Host "## 5. Sets the LUIS Application Id in KeyVault for distribution to Bot WebApp nodes (Azure CLI)"
az keyvault secret set --vault-name $keyVault.name --name LuisAppId --value $LUISAppInfo.id
$success = $success -and $?

# 6. Prepares and imports data necessary for LUIS Endpoint & Key association REST API (using Azure CLI - due to feature lag in LUIS CLI) 
Write-Host "## 6. Prepares and imports data necessary for LUIS Endpoint & Key association REST API (using Azure CLI - due to feature lag in LUIS CLI)"
$AccessToken=$(az account get-access-token --query 'accessToken' -o tsv)
$subscriptionId=$(az account show --query 'id' -o tsv)
$success = $success -and $?

# 7. Loads LUIS Account names and resource group names from Terraform output (Terraform CLI)
Write-Host "## 7. Loads LUIS Account names and resource group names from Terraform output (Terraform CLI)"
$LUISAccounts = terraform output -state="$(Get-ScriptPath)/IaC/terraform.tfstate" -json luisAccounts | ConvertFrom-Json
$success = $success -and $?

# 8. Loops to associate every LUIS account with the LUIS application (cURL command)
Write-Host "## 8. Loops to associate every LUIS account with the LUIS application (cURL command)"
$LUISAccounts | ForEach {

    $account=$_.name
    $rg=$_.resource_group

    $body="{""azureSubscriptionId"":""$subscriptionId"",""resourceGroup"":""$rg"",""accountName"":""$account""}"
    Set-Content -Path body.json -Value $body

    $CurlArgument = '-v', '-X', 'POST', "https://westus.api.cognitive.microsoft.com/luis/api/v2.0/apps/$($LUISAppInfo.id)/azureaccounts" `
    , '-H', "Authorization: Bearer $AccessToken" `
    , '-H', "Content-Type: application/json" `
    , '-H', "Ocp-Apim-Subscription-Key: $LUISauthKey" `
    , '-d', '@body.json'
    curl @CurlArgument
    $success = $success -and $?
    
    Remove-Item -Path body.json
}

# Return execution status
Write-ExecutionStatus -success $success
exit $success