<#
.SYNOPSIS
Retrieve Test Web Chat Link for Geo Distributed Bot Solution

.DESCRIPTION
Retrieve Test Web Chat Link for Geo Distributed Bot Solution

This script will do following steps:

1. Retrieve Bot Data from Terraform infrastructure execution
2. Retrieve DirectLine Secret and generate Link

After the script is successfully executed you should have a link to check you bot

.EXAMPLE
.\RetrieveWebChatLink.ps1

.INPUTS
None. You cannot pipe objects.

.OUTPUTS
System.Boolean. Returns $True if executed successfully

#>
param(

)
# Helper var
$success = $True
# Import Helper functions
. "$($MyInvocation.MyCommand.Path -replace($MyInvocation.MyCommand.Name))\HelperFunctions.ps1"
# Tell who you are (See HelperFunction.ps1)
Write-WhoIAm

# 1. Export SSL Certificate
Write-Host "## 1. Retrieve Bot Data from Terraform infrastructure execution"
$Bot = Get-TerraformOutput("bot") | ConvertFrom-Json
$success = $success -and $?

# 2. Retrieve DirectLine Secret and generate Link
Write-Host "## 2. Retrieve DirectLine Secret and generate Link"
$directline = $(az bot directline show --resource-group $Bot.resource_group --name $Bot.name --with-secrets true) | ConvertFrom-Json
$success = $success -and $?
$queryparams = "?bot=$($Bot.name)&key=$($directline.properties.properties.sites.key)"
$webchathtmlfile = Get-ItemProperty -Path "$(Get-ScriptPath)/../WebChat/index.html"

Write-Host -ForegroundColor Green "`n`n### If you were lucky and there were no errors in between your Geo Distributed Bot is ready!`n### If you are just testing you can use this link to open a WebChat to your Bot from any browser.`n### E.g. if you want to test it from different VM's or VPN connections."
Write-Host -ForegroundColor Red "### Do not use this link if you want to go to production since the Directline Key will get exposed on the network (query params are not encrypted):"
Write-Host -ForegroundColor Red "### https://h2floh.github.io/GeoDistributedAzureBot/WebChat/index.html$queryparams"
Write-Host -ForegroundColor Yellow "###`n### Use this link on your local computer (if you cloned the repo to your local computer) in order to not expose your Directline Key:"
Write-Host -ForegroundColor Yellow "### $($webchathtmlfile.FullName)$queryparams"

# Return execution status
Write-ExecutionStatus -success $success
exit $success