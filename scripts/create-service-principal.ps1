
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroup = 'scandic-ohip-logic-rg',

    [Parameter(Mandatory = $false)]
    [string]$SpName = 'scandic-ohip-logic-sp',

    [Parameter(Mandatory = $false)]
    [string]$GitHubRepo = 'sup3r7-fabio/fabio-ohip-logic-apps-test',

    [Parameter()]
    [switch]$UseSubscriptionScope = [switch]$false
)

# Get subscription ID
$subId = (az account show --query id -o tsv)

try {
    az account show > $null 2>&1
}
catch {
    Write-Error "Please run 'az login' first."
    exit 1
}

# compute scope (resource-group preferred for least privilege)
if ($UseSubscriptionScope) {
    $scope = "/subscriptions/$subId"
}
else {
    $scope = "/subscriptions/$subId/resourceGroups/$ResourceGroup"
}

Write-Host "Creating service principal '$SpName' with role 'Contributor' scoped to: $scope"

# create the SP and write SDK auth JSON (suitable for Azure/login GH action)
try {
    az ad sp create-for-rbac `
        --name $SpName `
        --role Contributor `
        --scopes $scope ` | Out-File -FilePath azure-creds.json -Encoding utf8

    Write-Host "Service principal created. SDK auth JSON written to: $(Resolve-Path ./azure-creds.json)"
}
catch {
    Write-Error "Failed to create service principal: $_"
    exit 2
}

# optional: set GitHub Actions secret (requires gh CLI authenticated)
if ($GitHubRepo -and (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "Setting GitHub secret AZURE_CREDENTIALS for repo $GitHubRepo (using gh CLI)"
    $body = Get-Content -Raw ./azure-creds.json
    gh secret set AZURE_CREDENTIALS --repo $GitHubRepo --body $body --env 'dev'
    Write-Host "GitHub secret AZURE_CREDENTIALS set for $GitHubRepo"
}
elseif ($GitHubRepo) {
    Write-Warning 'gh CLI not found. Install and run: gh auth login; then run this script again or paste azure-creds.json into GitHub Secrets (AZURE_CREDENTIALS).'
}

Write-Host 'Done. Keep azure-creds.json secure and do not commit it to source control.'
