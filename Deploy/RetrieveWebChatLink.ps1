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

# 1. Retrieve Bot Data from Terraform infrastructure execution
Write-Host "## 1. Retrieve Bot Data from Terraform infrastructure execution"
$Bot = Get-TerraformOutput("bot") | ConvertFrom-Json
$success = $success -and $?

# 2. Retrieve Bot endpoint information using Azure CLI
Write-Host "## 2. Retrieve Bot endpoint information using Azure CLI"
$botSettings = $(az bot show -n $Bot.name -g $Bot.resource_group) | ConvertFrom-Json
$success = $success -and $?
$endpoint = $botSettings.properties.endpoint
# If this bot using azure web app, we need to replace '/api/messages'
if ($endpoint -like "*/api/messages") { 
    $endpoint = $endpoint.Replace("/api/messages", "")
}
Write-Host "endpoint: $endpoint"

# 3. Generate Link
Write-Host "## 3. Generate Link"
Write-Host -ForegroundColor Green "`n`n### If you were lucky and there were no errors in between your Geo Distributed Bot is ready!`n### If you are just testing you can use this link to open a WebChat to your Bot from any browser.`n### E.g. if you want to test it from different VM's or VPN connections."
Write-Host -ForegroundColor Yellow "###`n### Use this link with your browser"
Write-Host -ForegroundColor Yellow "### $endpoint/"

# Return execution status
Write-ExecutionStatus -success $success
exit $success