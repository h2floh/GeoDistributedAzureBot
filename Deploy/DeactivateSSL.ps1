###
#
# Deactivate SSL Certificate when in direct use with TrafficManager Domain
#
# This script will do following steps:
#
# 1. Read relevant data of TrafficManager from Terraform Infrastructure execution
# 2. Delete all TrafficManager endpoints, this will also remove the custom domain name entry from WebApps automatically
#
###
# Parameters
param(

)
# Helper var
$success = $True
$iaCFolder = "IaC"
# Import Helper functions
. "$($MyInvocation.MyCommand.Path -replace($MyInvocation.MyCommand.Name))\HelperFunctions.ps1"
# Tell who you are (See HelperFunction.ps1)
Write-WhoIAm

# 1. Read values from Terraform IaC run (Bot deployment scripts)
Write-Host "## 1. Read values from Terraform IaC run (Bot deployment scripts)"
$TrafficManager = terraform output -state="$(Get-ScriptPath)/$iaCFolder/terraform.tfstate" -json trafficManager | ConvertFrom-Json
$success = $success -and $?

# 2. Delete all TrafficManager endpoints
Write-Host "## 2. Delete all TrafficManager endpoints"
$endpoints = $(az network traffic-manager endpoint list --resource-group $TrafficManager.resource_group --profile-name $TrafficManager.name) | ConvertFrom-Json
$success = $success -and $?

# Execute delete command for each endpoint
$endpoints.foreach({ 
    $type = $_.type.split("/")
    #Write-Host "az network traffic-manager endpoint delete --resource-group $($TrafficManager.resource_group) --profile-name $($TrafficManager.name) --type $($type[2]) --name $($_.name)"
    az network traffic-manager endpoint delete --resource-group $TrafficManager.resource_group --profile-name $TrafficManager.name --type $type[2] --name $_.name
    $success = $success -and $?
})

# Return execution status
Write-ExecutionStatus -success $success
exit $success