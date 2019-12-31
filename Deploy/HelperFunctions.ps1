# To avoid to complex setup of scripts we do not use PowerShell Modules on purpose

function Write-WhoIAm {
    <#
    .SYNOPSIS
    Simple function to print current scripts name
    #>
    $CallerScriptName = $MyInvocation.ScriptName.split('/').split('\')[-1] 
    Write-Host "`n`n# Executing $($CallerScriptName)"
}

function Write-ExecutionStatus {
    <#
    .SYNOPSIS
    Simple function to print success or failure of current script
    #>
    param([bool] $success)

    $CallerScriptName = $MyInvocation.ScriptName.split('/').split('\')[-1] 

    if($success)
    {
        Write-Host -ForegroundColor Green "`n`n# Execution Result $($CallerScriptName): SUCCESS"
    } else {
        Write-Host -ForegroundColor Red "`n`n# Execution Result $($CallerScriptName): FAILURE"
    }
}

function Get-TerraformAutoApproveFlag {
    <#
    .SYNOPSIS
    Simple function to return Terraform Auto Approve flag
    #>
    param([bool] $AUTOAPPROVE)

    if ($AUTOAPPROVE -eq $True)
    {
        return "-auto-approve"
    } else {
        return ""
    }
}

function Get-ScriptPath {
    <#
    .SYNOPSIS
    Simple function to return caller script absolute path
    #>
    return $MyInvocation.PSScriptRoot
}

function Check-ServiceAvailability {
    <#
    .SYNOPSIS
    Check for availability of DNS

    .OUTPUTS
    System.Boolean. returns $False if service is already
    #>
    param(
        # Service Name
        [Parameter(HelpMessage="Service Name")]
        [string] $Service,

        # Full Qualified Domain Name to check
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

function Set-RegionalVariableFile {
    <#
    .SYNOPSIS
    Create Region Variable File for Terraform
    This function will do following steps:
    1.  Create content for variable file

    .OUTPUTS
    System.Boolean. returns if execution/creation was successful
    #>
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

function Set-DefaultIfEmpty {
    <#
    .SYNOPSIS
    Sets a default value if the string parameter is empty

    .OUTPUTS
    System.String
    #>
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

function Get-ScriptPathTerraformApply {
    <#
    .SYNOPSIS
    Simple function to return caller script absolute path 
      Windows -> without drive letter (Windows Terraform bug)
      Linux -> default

    .OUTPUTS
    System.String
    #>

    if ($PSVersionTable.Platform -eq "Win32NT")
    {
        return $MyInvocation.PSScriptRoot.SubString(2, $MyInvocation.PSScriptRoot.Length-2) 
    } else {
        return $MyInvocation.PSScriptRoot
    }
}
