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

    $available = $True

    if ($Service -eq "FrontDoor")
    {
        # FrontDoor DNS always exists, curl on unavailable resource reveals 302 redirect to /pages/404.html (notfound)
        # curl -I https://mygeobot2.azurefd.net
        # HTTP/1.1 302 Found
        # Content-Length: 0
        # Location: /pages/404.html
        # Server: Microsoft-IIS/10.0
        # X-MSEdge-Ref: Ref A: C18D49B3B18F4EBB950B562E01AB4347 Ref B: SLAEDGE0808 Ref C: 2020-01-30T04:40:26Z
        # Date: Thu, 30 Jan 2020 04:40:26 GMT
        $CurlArgument = '-I', "https://$FQDN"
        $httpresult = curl @CurlArgument 2> $null
        $result = [string]::Concat($httpresult)
        $available = $result.Contains("302 Found") -and $result.Contains("404.html")
    }
    else {
        # Not working in PowerShellCore: Resolve-DnsName -Name $FQDN -DnsOnly > $null 2> $1
        # Changing to nslookup
        $resolved = nslookup $FQDN 2> $null
        $available = -not ((($resolved | Select-String $FQDN).Length -gt 0) -and (($resolved | Select-String "server can't find").Length -eq 0))
    }

    if (-not $available)
    {
        Write-Host -ForegroundColor Red "### ERROR, $Service with name '$FQDN' already exists. Please try another Bot Name."
    }

    return $available
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

function Get-TerraformOutput {
    <#
    .SYNOPSIS
    Function wraps the retrieval of Terraform output (due to limitations in terraform output command https://github.com/hashicorp/terraform/issues/17300)
        
    .OUTPUTS
    System.String. Raw Terraform Output
    #>
    param(
        [Parameter(Mandatory=$True, HelpMessage="Terraform Output Object")]
        [string] $OUTPUTOBJECT,

        [Parameter(HelpMessage="Terraform folder relative to Deploy/")]
        [string] $TERRAFORM_FOLDER = "IaC"
    )

    $curr_location = Get-Location
    Set-Location "$(Get-ScriptPath)\$TERRAFORM_FOLDER"
    $result = terraform output -json $OUTPUTOBJECT
    $success = $success -and $?
    Set-Location $curr_location

    return $result
}

function Invoke-Terraform {
    <#
    .SYNOPSIS
    Invokes Terraform command within the Terraform folder with parameters
    #>
    param(
        [Parameter(Mandatory=$True, HelpMessage="Terraform folder relative to 'Deploy/'")]
        [string] $TERRAFORM_FOLDER,

        [Parameter(Mandatory=$True, HelpMessage="AUTOAPPROVE")]
        [bool] $AUTOAPPROVE,

        [Parameter(HelpMessage="Terraform Action (Apply/Destroy)")]
        [string] $ACTION = "apply",

        [Parameter(HelpMessage="Terraform Variables")]
        [string[]] $INPUTVARS
    )

    $curr_location = Get-Location
    Set-Location "$(Get-ScriptPath)\$TERRAFORM_FOLDER"
    Invoke-Expression "terraform $ACTION $INPUTVARS $(Get-TerraformAutoApproveFlag $AUTOAPPROVE); `$TFEXEC = `$?;"
    Set-Location $curr_location

    # Forward Execution result of Terraform
    $LASTEXITCODE=$TFEXEC
    $global:LastExitCode=$TFEXEC
}

function Copy-TerraformFolder {
    <#
    .SYNOPSIS
    Copys contents from one Terraform Folder to another folder
    #>
    param(
        [Parameter(Mandatory=$True, HelpMessage="Source Folder")]
        [string] $FROM,

        [Parameter(HelpMessage="Destination Folder")]
        [string] $TO = "IaC"
    )
    # Ensure target folder exists
    New-Item -ItemType Directory -Force -Path "$(Get-ScriptPath)\$TO" > $null
    # Remove any content in target folder
    Get-ChildItem "$(Get-ScriptPath)\$TO" -Recurse -Force | Remove-Item -Recurse -Force
    # Copy content
    Copy-Item "$(Get-ScriptPath)\$FROM\*" -Destination "$(Get-ScriptPath)\$TO" -Recurse -Force
}