[CmdletBinding()]
param([string]$BaseUrl = 'http://127.0.0.1:5187')

$ErrorActionPreference = 'Stop'
$skills = Invoke-RestMethod "$BaseUrl/api/skills"
if ($skills.Count -lt 3) { throw "Expected at least three visible skills, found $($skills.Count)." }

$body = @{ inputs = @{ customer='Contoso'; question='What is the migration status?' } } | ConvertTo-Json -Depth 4
$run = Invoke-RestMethod "$BaseUrl/api/skills/customer-response/run" -Method Post -ContentType 'application/json' -Body $body
if ($run.skillId -ne 'customer-response' -or $run.version -ne '1') { throw 'Unexpected invocation envelope.' }

try {
    Invoke-WebRequest "$BaseUrl/api/skills/customer-response/run" -Method Post -Headers @{ 'X-Demo-Grants'='skill-readers' } -ContentType 'application/json' -Body $body | Out-Null
    throw 'A reader without run permission was incorrectly authorized.'
}
catch {
    if ([int]$_.Exception.Response.StatusCode -ne 403) { throw }
}

Write-Host 'Local smoke tests passed: discover, run, and deny.'