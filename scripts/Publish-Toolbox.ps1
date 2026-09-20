[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ProjectName,
    [string]$ToolboxName = 'northstar-skills',
    [string]$RepositoryRoot = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'
$endpoint = "https://generic-demos-2-resource.services.ai.azure.com/api/projects/$ProjectName"
azd ai project set $endpoint
azd ai toolbox create $ToolboxName --from-file "$RepositoryRoot/foundry/toolbox.yaml" --no-prompt
azd ai toolbox publish $ToolboxName --no-prompt
azd ai toolbox show $ToolboxName