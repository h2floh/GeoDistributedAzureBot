###
# This script will do following steps:
#
# 1. Publish the .NET Core 2.2 Bot for x64 Windows (see App Service Plan)
# 2. Compress publish folder to zip file
# 3. Loads WebApp Account names and resource group names from Terraform output (Terraform CLI)
# 4. Deploy to WebApps
#
# After the script is successfully executed the bot code is deployed
#
###

# 1. Publish the .NET Core 2.2 Bot for x64 Windows (see App Service Plan)
echo "1. Publish the .NET Core 2.2 Bot for x64 Windows (see App Service Plan)"
dotnet publish ..\GeoBot\GeoBot\GeoBot.csproj -r win-x64 -c release --no-self-contained

# 2. Compress publish folder to zip file
echo "2. Compress publish folder to zip file"
Compress-Archive -Path ..\GeoBot\GeoBot\bin\release\netcoreapp2.2\win-x64\publish\* -DestinationPath botnotselfcontained.zip -Force

# 3. Loads WebApp Account names and resource group names from Terraform output (Terraform CLI)
echo "3. Loads WebApp Account names and resource group names from Terraform output (Terraform CLI)"
$WebAppAccounts = terraform output -state=".\IaC\terraform.tfstate" -json webAppAccounts | ConvertFrom-Json

# 4. Deploy to WebApps
echo "4. Deploy to WebApps"
$WebAppAccounts | ForEach {

    $account=$_.name
    $rg=$_.resource_group

    echo "- Deploy to $account"
    az webapp deployment source config-zip --src botnotselfcontained.zip --name $account --resource-group $rg
}