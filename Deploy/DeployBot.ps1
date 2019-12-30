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
# Parameters
param(
    [Parameter(HelpMessage="Bot Project File")]
    [string] $BOT_PROJECT_FILE,

    [Parameter(HelpMessage="Target Runtime see https://docs.microsoft.com/en-us/dotnet/core/rid-catalog")] 
    [string] $TARGET_RUNTIME = "win-x64",

    [Parameter(HelpMessage="Configuration release or debug")]
    [string] $CONFIGURATION = "release",

    [Parameter(HelpMessage="Folder to dotnet publish artifacts")]
    [string] $PUBLISH_ARTIFACTS,

    [Parameter(HelpMessage="Deployment Zip File Name")]
    [string] $ZIP_FILE_NAME = "botnotselfcontained.zip"
)
# Helper var
$success = $True
# Import Helper functions
. "$($MyInvocation.MyCommand.Path -replace($MyInvocation.MyCommand.Name))\HelperFunctions.ps1"
# Tell who you are (See HelperFunction.ps1)
Write-WhoIAm

# Set Default Values for Parameters
$BOT_PROJECT_FILE = Set-DefaultIfEmpty -VALUE $BOT_PROJECT_FILE -DEFAULT "$(Get-ScriptPath)/../GeoBot/GeoBot/GeoBot.csproj"
$PUBLISH_ARTIFACTS = Set-DefaultIfEmpty -VALUE $PUBLISH_ARTIFACTS -DEFAULT "$(Get-ScriptPath)/../GeoBot/GeoBot/bin/release/netcoreapp2.2/win-x64/publish/*"

# 0. Dotnet clean
Write-Host "## 0. Clean build/project for $TARGET_RUNTIME (check with App Service Plan)"
dotnet clean $BOT_PROJECT_FILE -r $TARGET_RUNTIME -c $CONFIGURATION
$success = $success -and $?

# 1. Publish the .NET Core 2.2 Bot for correct runtime (see App Service Plan Linux or Windows)
Write-Host "## 1. Publish the .NET Core 2.2 Bot for $TARGET_RUNTIME (check with App Service Plan)"
dotnet publish $BOT_PROJECT_FILE -r $TARGET_RUNTIME -c $CONFIGURATION --no-self-contained
$success = $success -and $?

# 2. Compress publish folder to zip file
Write-Host "## 2. Compress publish folder to zip file"
Compress-Archive -Path $PUBLISH_ARTIFACTS -DestinationPath "$(Get-ScriptPath)/$ZIP_FILE_NAME" -Force #Override if exists
$success = $success -and $?

# 3. Loads WebApp Account names and resource group names from Terraform output (Terraform CLI)
Write-Host "## 3. Loads WebApp Account names and resource group names from Terraform output (Terraform CLI)"
$WebAppAccounts = terraform output -state="$(Get-ScriptPath)/IaC/terraform.tfstate" -json webAppAccounts | ConvertFrom-Json
$success = $success -and $?

# 4. Deploy to WebApps
Write-Host "## 4. Deploy to WebApps"
$WebAppAccounts | ForEach {

    $account=$_.name
    $rg=$_.resource_group

    Write-Host "### - Deploy to $account"
    az webapp deployment source config-zip --src "$(Get-ScriptPath)/$ZIP_FILE_NAME" --name $account --resource-group $rg
    $success = $success -and $?
}
# Remove zip file
Remove-Item -Path "$(Get-ScriptPath)/$ZIP_FILE_NAME"

# Return execution status
Write-ExecutionStatus -success $success
exit $success