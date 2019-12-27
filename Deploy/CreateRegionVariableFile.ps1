###
#
# Create Region Variable File for Terraform
#
# This script will do following steps:
#
# 1.  Create content for variable file
#
###
# Parameters
param(
    [Parameter(Mandatory=$True, HelpMessage="Filename to use")]
    [string] $FILENAME,

    [Parameter(HelpMessage="Regions to deploy the Bot to")]
    [string[]] $BOT_REGIONS = @("koreacentral", "southeastasia")
)
# Helper var
$success = $True
$priority = 0

# Tell who you are
Write-Host "`n`n# Executing $($MyInvocation.MyCommand.Name)"

# 1.  Create content for variable file
Write-Host "## 1.  Create content for variable file"

# See IaC/variables.tf format for azure_bot_regions (here in json format)
$content = '{ "azure_bot_regions" : [' + $BOT_REGIONS.ForEach({ 
    "{ `"name`" : `"$_`", `"priority`" : $priority }," 
    $priority++
    })
$content = $content.TrimEnd(",") + ']}'

Set-Content -Path $azureBotRegions -Value $content
$success = $success -and $?

# Check successful execution
exit $success
