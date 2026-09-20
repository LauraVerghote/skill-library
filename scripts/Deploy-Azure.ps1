[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$TenantId,
    [Parameter(Mandatory)]
    [string]$ClientId,
    [Parameter(Mandatory)]
    [securestring]$ClientSecret,
    [string]$RepositoryRoot = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'
$subscriptionId = '07122d2f-74de-4565-bd61-4d673d621fe8'
$resourceGroup = 'generic-demos'
$appName = 'skill-library-demo'

$account = az account show --subscription $subscriptionId --output json | ConvertFrom-Json
if ($account.tenantId -ne $TenantId) {
    throw "Azure CLI tenant '$($account.tenantId)' does not match requested tenant '$TenantId'."
}
if ($account.user.name -ne 'lverghote@MngEnvMCAP125495.onmicrosoft.com') {
    throw "Sign in with lverghote@MngEnvMCAP125495.onmicrosoft.com before deployment. Current user: $($account.user.name)"
}

az account set --subscription $subscriptionId
$plainSecret = [System.Net.NetworkCredential]::new('', $ClientSecret).Password
try {
    az deployment group create `
        --resource-group $resourceGroup `
        --template-file "$RepositoryRoot/infra/main.bicep" `
        --parameters appName=$appName tenantId=$TenantId clientId=$ClientId clientSecret=$plainSecret `
        --parameters containerImage='mcr.microsoft.com/dotnet/samples:aspnetapp' `
        --name 'skill-library-infrastructure'

    az containerapp up `
        --name $appName `
        --resource-group $resourceGroup `
        --source $RepositoryRoot `
        --ingress external `
        --target-port 8080
}
finally {
    $plainSecret = $null
}

$fqdn = az containerapp show --name $appName --resource-group $resourceGroup --query properties.configuration.ingress.fqdn --output tsv
az ad app update --id $ClientId --web-redirect-uris "https://$fqdn/.auth/login/aad/callback"
Write-Host "Skill Library: https://$fqdn"