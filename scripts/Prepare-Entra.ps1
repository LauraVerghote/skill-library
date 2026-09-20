[CmdletBinding()]
param(
    [string]$DisplayName = 'Northstar Skill Library',
    [switch]$RotateSecret
)

$ErrorActionPreference = 'Stop'
$expectedSubscription = '07122d2f-74de-4565-bd61-4d673d621fe8'
$expectedUser = 'lverghote@MngEnvMCAP125495.onmicrosoft.com'
$account = az account show --subscription $expectedSubscription --output json | ConvertFrom-Json
if ($account.user.name -ne $expectedUser) {
    throw "Sign in with $expectedUser. Current user: $($account.user.name)"
}
az account set --subscription $expectedSubscription

$apps = @(az ad app list --display-name $DisplayName --output json | ConvertFrom-Json)
if ($apps.Count -gt 1) { throw "Multiple app registrations named '$DisplayName' exist." }
$created = $apps.Count -eq 0
$app = if ($created) { az ad app create --display-name $DisplayName --sign-in-audience AzureADMyOrg --output json | ConvertFrom-Json } else { $apps[0] }

if ($created) {
    $appRoles = @(
        @{ allowedMemberTypes=@('User'); description='Read governed skills'; displayName='Skill Reader'; id=[guid]::NewGuid(); isEnabled=$true; value='skill-readers' },
        @{ allowedMemberTypes=@('User'); description='Edit and publish governed skills'; displayName='Skill Author'; id=[guid]::NewGuid(); isEnabled=$true; value='skill-authors' },
        @{ allowedMemberTypes=@('User','Application'); description='Run published skills'; displayName='Skill Runner'; id=[guid]::NewGuid(); isEnabled=$true; value='skill-runners' }
    )
    $scope = @{
        adminConsentDescription='Access the Northstar Skill Library'
        adminConsentDisplayName='Access skill library'
        id=[guid]::NewGuid()
        isEnabled=$true
        type='User'
        userConsentDescription='Access the Northstar Skill Library on your behalf'
        userConsentDisplayName='Access skill library'
        value='access_as_user'
    }
    $manifest = @{ appRoles=$appRoles; api=@{ requestedAccessTokenVersion=2; oauth2PermissionScopes=@($scope) }; groupMembershipClaims='SecurityGroup' }
    $manifestPath = Join-Path ([System.IO.Path]::GetTempPath()) "skill-library-manifest-$([guid]::NewGuid()).json"
    try {
        $manifest | ConvertTo-Json -Depth 8 | Set-Content -Path $manifestPath -Encoding utf8NoBOM
        az rest --method PATCH --uri "https://graph.microsoft.com/v1.0/applications/$($app.id)" --body "@$manifestPath" | Out-Null
    }
    finally {
        Remove-Item $manifestPath -Force -ErrorAction SilentlyContinue
    }
}

if ($created -or $RotateSecret) {
    $credential = az ad app credential reset --id $app.appId --display-name 'container-app-auth' --years 1 --output json | ConvertFrom-Json
    $env:SKILL_LIBRARY_CLIENT_SECRET = $credential.password
    Write-Warning 'A new secret is stored only in SKILL_LIBRARY_CLIENT_SECRET for this PowerShell process. Deploy before closing it.'
}

[pscustomobject]@{
    ClientId = $app.appId
    ObjectId = $app.id
    TenantId = $account.tenantId
    SecretPrepared = [bool]($created -or $RotateSecret)
}