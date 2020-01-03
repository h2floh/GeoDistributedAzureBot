<#
.SYNOPSIS
Creates Markdown files from PowerShell Get-Help output

.DESCRIPTION
Creates Markdown files from PowerShell Get-Help output

Helper Tool to create GitHub Markdown files from PS1 scripts. 
Will check for all PS1 scripts in a given folder and try to create a markdown file.
If flowcharts are available integrates those into the markdown.
Since this is a helper script for the repos documentation it has limitations on usage

.EXAMPLE
.\CreateMarkdown-FromPS1.ps1 -dir ..\Deploy -savepath .\Deploy

.EXAMPLE
.\CreateMarkdown-FromPS1.ps1 -dir . -savepath .

.INPUTS
None. You cannot pipe objects.

.OUTPUTS
None.

#>
param(
    # Directory with PS1 scripts
    [Parameter(Mandatory=$True,HelpMessage="Directory with PS1 scripts")]
    [string] $dir,

    # Markdown file directory
    [Parameter(HelpMessage="Markdown file directory")]
    [string] $savepath = "."
)

function Get-ParameterMarkdownTable {
    param (
        # Get-Help Object
        [Parameter(Mandatory=$True,HelpMessage="Get-Help Object")]
        [object] $help
    )

    $result = "`n`n## Parameters`n`n| Name | Type | Required | Default | Description |`n| - | - | - | - | - |"
    
    #Write-Host $help

    $help.parameters[0].parameter.foreach({
        #Write-Host "`nParameter: $_"
        # try parse default from description
        $description = $_.description.text
        $default = ""
        if(($_.description.text -match "- Default: (.+)$"))
        {
            $default = $Matches[1]
            $description = $_.description.text.replace("- Default: $default", "")
        }
        if(($_.defaultValue -ne ""))
        {
            $default = $_.defaultValue
        }

        $result += "`n| $($_.name) | $($_.type.name) | $($_.required) | $($default) | $($description) |"
    })

    if ($help.parameters -ne "")
    {
        return $result
    } else {
        return ""
    }
    
}

function Get-Examples {
    param (
        # Get-Help Object
        [Parameter(Mandatory=$True,HelpMessage="Get-Help Object")]
        [object] $help
    )

    $result = "``````powershell`n"
    $help.Examples[0].example.foreach({
        #Write-Host "`Examples: $($_.code)"
        
        $result += "$($_.code)`n`n"
    })
    $result += "```````n";
    return $result
}

function Get-FlowChart {
    param (
        # Filename
        [Parameter(Mandatory=$True,HelpMessage="Filename")]
        [string] $file
    )

    $fileparts = $file.Split('.')
    $flowchartfile = "flowchart/$($fileparts[0]).flowchart"
    if (Test-Path -Path $flowchartfile)
    {
        # Force LF style
        (Get-Content $flowchartfile -Raw).Replace("`r`n","`n") | Set-Content $flowchartfile -Force
        # render flowchart
        diagrams flowchart $flowchartfile > $null 

        return "`n`n## Flowchart`n`n<div align='center'>`n`n![Flowchart for $file](../$flowchartfile.svg)`n</div>"

    } else {
        return ""
    }
}

function Get-RelatedScripts {
    param (
        # PS1 file
        [Parameter(Mandatory=$True,HelpMessage="PS1 file")]
        [object] $file
    )

    $script = Get-Content -Path $file.FullName

    $results = $script | Select-String "([\w]+)\.ps1" -AllMatches
    
    # Display only Unique values
    $matches = $results.Matches.Value | Select-Object -uniq
    # Remove self references
    $matches = $matches -ne $file.name 
    # Remove Helper Function references
    $matches = $matches -ne "HelperFunctions.ps1"
    $matches = $matches -ne "HelperFunction.ps1"
    $matches.foreach({
        $fileparts = $_.Split('.')
        $related += "`n- [$_]($($fileparts[0]).md)`n"
    })    
    
    #Write-Host $results.Matches

    if ($null -ne $related) {
        return "`n`n## Related Scripts$related"
    } else {
        return ""
    }
}

function ConvertHelpToMarkdown {

    param (
        # PS1 file name
        [Parameter(Mandatory=$True,HelpMessage="PS1 file name")]
        [object] $file,

        # Markdown file directory
        [Parameter(HelpMessage="Markdown file directory")]
        [string] $savepath = "."
    )

    Write-Host "Processing $($file.name)..."
    $help = Get-Help -Name "$($file.FullName)" -full
    #$help

    if ($help.description -ne $null)
    {
        # Headline + SYNOPSIS
        $markdown = "# $($file.name)`n`n$($help.synopsis)"

        # Description
        $markdown += "`n`n## Description`n`n$($help.description.text)"

        # Parameters
        $markdown += Get-ParameterMarkdownTable -help $help

        # Examples
        $examples = Get-Examples -help $help
        $markdown += "`n`n## Examples`n`n$($examples)"

        # Get Related Script
        $markdown += Get-RelatedScripts -file $file

        # flowchart
        $markdown += Get-FlowChart -file $file.name
        
        $markdownfile = $file.name.replace("ps1","md")
        Set-Content -Path "$savepath/$markdownfile" -Value $markdown
        Write-Host "Created $savepath/$markdownfile..."
    } else {
        Write-Host "Skipped $($file.name)..."
    }
}

# Load ps1 files in folder
$FILES = @(Get-ChildItem -Path $dir -File -Recurse) | Where-Object -FilterScript {$_.name.contains(".ps1")}
# Create Markdown files
$FILES.ForEach({ConvertHelpToMarkdown -file $_ -savepath $savepath})

