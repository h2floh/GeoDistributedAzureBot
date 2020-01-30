<#
.SYNOPSIS
Init the remote state store used by Terraform (Blob Storage) and the execution folders

.DESCRIPTION
Init the remote state store used by Terraform (Blob Storage) and the execution folders

This script will do following steps:

1. Ensure Resource group for Terraform
2. Ensure Storage Account and Container for Terraform Remote State
3. Initalizes all Terraform folders

After the script is successfully executed the Terraform can use the storage as remote state store.

.EXAMPLE
.\InitTerraform.ps1 -STORAGE_ACCOUNT_NAME myterraformstate -RESOURCE_GROUP_NAME rg-myterraformstate

.INPUTS
None. You cannot pipe objects.

.OUTPUTS
System.Boolean. Returns $True if executed successfully

#>
param(
    # Storage Account Name for Terraform remote state
    [Parameter(Mandatory=$true, HelpMessage="Storage Account Name for Terraform remote state")]
    [string] $STORAGE_ACCOUNT_NAME,

    # Resource Group Name where Storage Account is placed for Terraform remote state
    [Parameter(Mandatory=$true, HelpMessage="Resource Group Name where Storage Account is placed for Terraform remote state")]
    [string] $RESOURCE_GROUP_NAME,

    # Region used for Resource Group and Storage Account
    [Parameter(HelpMessage="Region used for global services")]
    [string] $LOCATION = "japaneast",

    # Terraform folders from within Deploy folder
    [Parameter(HelpMessage="Terraform folders from within Deploy folder")]
    [string[]] $TERRAFORM_FOLDERS =  @("IaCTM", "IaCAFD", "SSLActivation", "SSLIssuing"),

    # Maximum wait time for RBAC rights to be propagated. Default 3 min
    [Parameter(HelpMessage="Maximum wait time for RBAC rights to be propagated. Default 3 min")]
    [int] $MAX_WAIT_TIME_MIN = 3
)
# Import Helper functions
. "$($MyInvocation.MyCommand.Path -replace($MyInvocation.MyCommand.Name))\HelperFunctions.ps1"
# Helper var
$success = $True
$loopcount = 0
$waitretrysec = 10
$loopmax = (60 * $MAX_WAIT_TIME_MIN ) / $waitretrysec
$container_name = "tfstate"

# Tell who you are (See HelperFunction.ps1)
Write-WhoIAm

# 1. Ensure Resource group for Terraform
Write-Host "## 1. Ensure Resource group for Terraform"
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION > $null
$success = $success -and $?

# 2. Ensure Storage Account and Container for Terraform Remote State
Write-Host "## 2. Ensure Storage Account and Container for Terraform Remote State"
$account = az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --kind StorageV2 --sku Standard_LRS --https-only true | ConvertFrom-Json
$success = $success -and $?

# Get info around current connection
$currentConnection = az account show | ConvertFrom-Json
$success = $success -and $?

# Save Principal Type and Id
$principalType = $currentConnection.user.type
$principalId = ""

if($principalType -eq "user")
{
    # If type is user object Id of user has to be retrieved
    $currentUser = az ad signed-in-user show | ConvertFrom-Json
    $principalId = $currentUser.objectId
}
elseif ($principalType -eq "servicePrincipal")
{
    # If type is servicePrincipal object Id of sp has to be retrieved
    $currentSp = az ad sp show --id $currentConnection.user.name | ConvertFrom-Json
    $principalId = $currentSp.objectId
}

# Finally we can assign the role (ServicePrincipal role needs "Contributor", "Key Vault Contributor" and "User Access Administrator" role at subscription level to succeed)
az role assignment create --role "Storage Blob Data Contributor" --assignee-object-id $principalId --assignee-principal-type $principalType --scope $account.id > $null
$success = $success -and $?

# Wait until rights are propagated on failure
$roleassignmentcomplete = $success
$loopcount = 0
az storage container create --name $container_name --public-access off --account-name $STORAGE_ACCOUNT_NAME --auth-mode login > $null 2> $1
while ($? -eq $False -and $roleassignmentcomplete -and ($loopcount -le $loopmax))
{
    $loopcount++
    Write-Host "Waiting for rights to be propagated. Waiting for $waitretrysec seconds"
    Start-Sleep -s $waitretrysec
    az storage container create --name $container_name --public-access off --account-name $STORAGE_ACCOUNT_NAME --auth-mode login > $null 2> $1
}
$success = $success -and $?

# Create Storage Account
Write-Host "## 3. Init all Terraform folders"
$TERRAFORM_FOLDERS | ForEach { 
    $curr_location = Get-Location
    Set-Location "$(Get-ScriptPath)\$_"
    terraform init -backend-config="resource_group_name=$RESOURCE_GROUP_NAME" -backend-config="storage_account_name=$STORAGE_ACCOUNT_NAME" .
    $success = $success -and $?
    Set-Location $curr_location
}

# Check successful execution
Write-ExecutionStatus -success $success
exit $success