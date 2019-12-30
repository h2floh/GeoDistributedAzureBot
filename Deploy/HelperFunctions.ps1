# To avoid to complex setup of scripts we do not use PowerShell Modules on purpose

# Simple function to print current scripts name
function Write-WhoIAm {
    $CallerScriptName = $MyInvocation.ScriptName.split('/').split('\')[-1] 
    Write-Host "`n`n# Executing $($CallerScriptName)"
}

# Simple function to print success or failure of current script
function Write-ExecutionStatus {
    param([bool] $success)

    $CallerScriptName = $MyInvocation.ScriptName.split('/').split('\')[-1] 

    if($success)
    {
        Write-Host -ForegroundColor Green "`n`n# Execution Result $($CallerScriptName): SUCCESS"
    } else {
        Write-Host -ForegroundColor Red "`n`n# Execution Result $($CallerScriptName): FAILURE"
    }
}

# Simple function to return Terraform Auto Approve flag
function Get-TerraformAutoApproveFlag {
    param([bool] $AUTOAPPROVE)

    if ($AUTOAPPROVE -eq $True)
    {
        return "-auto-approve"
    } else {
        return ""
    }
}

# Simple function to return caller script absolute path
function Get-ScriptPath {
    return $MyInvocation.PSScriptRoot
}

###
#
# Check for availability of DNS
# returns $False if service is already
#
###
function Check-ServiceAvailability {
    # Parameters
    param(
        [Parameter(HelpMessage="Service Name")]
        [string] $Service,

        # Only needed in Issuing Mode
        [Parameter(HelpMessage="Full Qualified Domain Name to check")]
        [string] $FQDN
    )
    # Not working in PowerShellCore: Resolve-DnsName -Name $FQDN -DnsOnly > $null 2> $1
    # Changing to nslookup
    $resolved = nslookup $FQDN 2> $null
    if ((($resolved | Select-String $FQDN).Length -gt 0) -and (($resolved | Select-String "server can't find").Length -eq 0))
    {
        Write-Host -ForegroundColor Red "### ERROR, $Service with name '$FQDN' already exists. Please try another Bot Name."
        return $False
    } else {
        return $True
    }
}

###
#
# Create Region Variable File for Terraform
#
# This script will do following steps:
#
# 1.  Create content for variable file
#
###
function Set-RegionalVariableFile {
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

    # 1.  Create content for variable file
    # See IaC/variables.tf format for azure_bot_regions (here in json format)
    $content = '{ "azure_bot_regions" : [' + $BOT_REGIONS.ForEach({ 
        "{ `"name`" : `"$_`", `"priority`" : $priority }," 
        $priority++
        })
    $content = $content.TrimEnd(",") + ']}'

    Set-Content -Path $azureBotRegions -Value $content
    $success = $success -and $?

    # Return status
    return $success 
}

###
#
# Sets a default value if the string parameter is empty
#
###
function Set-DefaultIfEmpty {
    # Parameters
    param(
        [Parameter(HelpMessage="Current Value of Parameter")]
        [string] $VALUE,

        [Parameter(Mandatory=$True, HelpMessage="Default Value")]
        [string] $DEFAULT
    )

    if ($VALUE -eq "")
    {
        return $DEFAULT
    } else {
        return $VALUE
    }

}

#
# Terraform Windows behavior is strange on apply plan
#
# Simple function to return caller script absolute path
function Get-ScriptPathTerraformApply {

    if ($PSVersionTable.Platform -eq "Win32NT")
    {
        return $MyInvocation.PSScriptRoot.SubString(2, $MyInvocation.PSScriptRoot.Length-2) 
    } else {
        return $MyInvocation.PSScriptRoot
    }
}
