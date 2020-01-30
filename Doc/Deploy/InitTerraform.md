# InitTerraform.ps1

Init the remote state store used by Terraform (Blob Storage) and the execution folders

## Description

Init the remote state store used by Terraform (Blob Storage) and the execution folders

This script will do following steps:

1. Ensure Resource group for Terraform
2. Ensure Storage Account and Container for Terraform Remote State
3. Initalizes all Terraform folders

After the script is successfully executed the Terraform can use the storage as remote state store.

## Parameters

| Name | Type | Required | Default | Description |
| - | - | - | - | - |
| STORAGE_ACCOUNT_NAME | String | true |  | Storage Account Name for Terraform remote state |
| RESOURCE_GROUP_NAME | String | true |  | Resource Group Name where Storage Account is placed for Terraform remote state |
| LOCATION | String | false | japaneast | Region used for Resource Group and Storage Account |
| TERRAFORM_FOLDERS | String[] | false | @("IaCTM", "IaCAFD", "SSLActivation", "SSLIssuing") | Terraform folders from within Deploy folder |
| MAX_WAIT_TIME_MIN | Int32 | false | 3 | Maximum wait time for RBAC rights to be propagated. Default 3 min |

## Examples

```powershell
.\InitTerraform.ps1 -STORAGE_ACCOUNT_NAME myterraformstate -RESOURCE_GROUP_NAME rg-myterraformstate

```

