# CreateMarkdown-FromPS1.ps1

Creates Markdown files from PowerShell Get-Help output

## Description

Creates Markdown files from PowerShell Get-Help output

Helper Tool to create GitHub Markdown files from PS1 scripts. 
Will check for all PS1 scripts in a given folder and try to create a markdown file.
If flowcharts are available integrates those into the markdown.
Since this is a helper script for the repos documentation it has limitations on usage

## Parameters

| Name | Type | Required | Default | Description |
| - | - | - | - | - |
| dir | String | true |  | Directory with PS1 scripts |
| savepath | String | false | . | Markdown file directory |

## Examples

```powershell
.\CreateMarkdown-FromPS1.ps1 -dir ..\Deploy -savepath .\Deploy

.\CreateMarkdown-FromPS1.ps1 -dir . -savepath .

```

