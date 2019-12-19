###
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

# 1. Get the authoring key from KeyVault (Azure CLI - Alternative: could be done with Terraform output)
echo "1. Get the authoring key from KeyVault (Azure CLI - Alternative: could be done with Terraform output)"
$keyVault = terraform output -state=".\IaC\terraform.tfstate" -json keyVault | ConvertFrom-Json
$LUISauthKey=$(az keyvault secret show --vault-name $keyVault.name --name LUISAuthoringKey --query 'value' -o tsv)

# 2. Imports the application to LUIS.ai via LUIS JSON model and LUIS cli tool
echo "2. Imports the application to LUIS.ai via LUIS JSON model and LUIS cli tool"
$LUISappInfo=$(luis import application --in ../GeoBot/GeoBot/CognitiveModels/AddressFinder.json --appName GeoBotAddressFinder --authoringKey $LUISauthKey) | ConvertFrom-JSON

# 3. Trains the application on LUIS.ai via LUIS cli tool
echo "3. Trains the application on LUIS.ai via LUIS cli tool"
luis train version --appId $LUISappInfo.id --versionId $LUISappInfo.activeVersion --authoringKey $LUISauthKey --wait

# 4. Publishes the application to production slot on LUIS.ai via LUIS cli tool
echo "4. Publishes the application to production slot on LUIS.ai via LUIS cli tool"
luis publish version --appId $LUISappInfo.id --versionId $LUISappInfo.activeVersion --staging false --authoringKey $LUISauthKey 

# 5. Sets the LUIS Application Id in KeyVault for distribution to Bot WebApp nodes (Azure CLI)
echo "5. Sets the LUIS Application Id in KeyVault for distribution to Bot WebApp nodes (Azure CLI)"
az keyvault secret set --vault-name $keyVault.name --name LuisAppId --value $LUISappInfo.id

# 6. Prepares and imports data necessary for LUIS Endpoint & Key association REST API (using Azure CLI - due to feature lag in LUIS CLI) 
echo "6. Prepares and imports data necessary for LUIS Endpoint & Key association REST API (using Azure CLI - due to feature lag in LUIS CLI)"
$LUISAppId=$LUISappInfo.id
$AccessToken=$(az account get-access-token --query 'accessToken' -o tsv)
$subscriptionId=$(az account show --query 'id' -o tsv)

# 7. Loads LUIS Account names and resource group names from Terraform output (Terraform CLI)
echo "7. Loads LUIS Account names and resource group names from Terraform output (Terraform CLI)"
$LUISAccounts = terraform output -state=".\IaC\terraform.tfstate" -json luisAccounts | ConvertFrom-Json

# 8. Loops to associate every LUIS account with the LUIS application (cURL command)
echo "8. Loops to associate every LUIS account with the LUIS application (cURL command)"
$LUISAccounts | ForEach {

    $account=$_.name
    $rg=$_.resource_group

    $body="{""azureSubscriptionId"":""$subscriptionId"",""resourceGroup"":""$rg"",""accountName"":""$account""}"
    echo $body | Out-File -FilePath body.json
    
    $CurlArgument = '-v', '-X', 'POST', "https://westus.api.cognitive.microsoft.com/luis/api/v2.0/apps/$LUISAppId/azureaccounts" `
    , '-H', "Authorization: Bearer $AccessToken" `
    , '-H', "Content-Type: application/json" `
    , '-H', "Ocp-Apim-Subscription-Key: $LUISauthKey" `
    , '-d', '@body.json'
    curl @CurlArgument

}


