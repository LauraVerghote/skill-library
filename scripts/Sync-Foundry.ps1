[CmdletBinding()]
param(
    [string]$ProjectName,
    [string]$RepositoryRoot = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'
$subscriptionId = '07122d2f-74de-4565-bd61-4d673d621fe8'
$resourceGroup = 'generic-demos'
$accountName = 'generic-demos-2-resource'
$expectedUser = 'lverghote@MngEnvMCAP125495.onmicrosoft.com'

$account = az account show --subscription $subscriptionId --output json | ConvertFrom-Json
if ($account.user.name -ne $expectedUser) {
    throw "Sign in with $expectedUser. Current user: $($account.user.name)"
}
az account set --subscription $subscriptionId

if (-not $ProjectName) {
    $projects = @(az cognitiveservices account project list --name $accountName --resource-group $resourceGroup --output json | ConvertFrom-Json)
    if ($projects.Count -ne 1) {
        throw "Found $($projects.Count) Foundry projects. Pass -ProjectName explicitly."
    }
    $ProjectName = $projects[0].name.Split('/')[-1]
}

$endpoint = "https://$accountName.services.ai.azure.com/api/projects/$ProjectName"
$token = az account get-access-token --resource https://ai.azure.com --query accessToken --output tsv
$headers = @{
    Authorization = "Bearer $token"
    'Foundry-Features' = 'Skills=V1Preview'
}

Get-ChildItem "$RepositoryRoot/.github/skills" -Directory | ForEach-Object {
    $skillFile = Join-Path $_.FullName 'SKILL.md'
    if (-not (Test-Path $skillFile)) { return }
    $skillName = ([regex]::Match((Get-Content -Raw $skillFile), '(?m)^name:\s*([a-z0-9-]+)\s*$')).Groups[1].Value
    if (-not $skillName) { throw "Missing valid name front matter in $skillFile" }

    $archive = Join-Path ([System.IO.Path]::GetTempPath()) "$skillName-$([guid]::NewGuid()).zip"
    try {
        Compress-Archive -Path "$($_.FullName)/*" -DestinationPath $archive
        $response = Invoke-RestMethod `
            -Uri "$endpoint/skills/$skillName/versions?api-version=v1" `
            -Method Post `
            -Headers $headers `
            -Form @{ files = Get-Item $archive }
        Write-Host "Synced $skillName version $($response.version)"
    }
    finally {
        Remove-Item $archive -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "Foundry project endpoint: $endpoint"