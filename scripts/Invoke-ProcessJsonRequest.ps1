<#
.SYNOPSIS
This PowerShell script is used to process a JSON request for vending solution and generate the corresponding YAML files.

.DESCRIPTION

Requirements:
1. A set of yaml files includes one for resources and one for the subscription.
1. Generate 1 set of yaml files for each subscription in the JSON request.
1. Subscription yaml files should be created under workloads/subscriptions/{GLOBAL_ID}
1. Resource yaml files should be created under workloads/builds/{GLOBAL_ID}

Logic:
- Install required modules
- Read the JSON request
- Create Subscription YAML files
- Create Resource YAML files

.PARAMETER GlobalId
This is the unique identifier of the request and context to where files are generated.

.PARAMETER WorkloadsDirectory
This is the directory where the YAML files will be created.

.PARAMETER HubNetworkResourceId
This is the resource ID of the hub network.

.PARAMETER DnsServers
This is the list of DNS servers to be used for the virtual network.

.EXAMPLE

. 'Invoke-ProcessJsonRequest.ps1' -GlobalId "ABCD123" -HubNetworkResourceId "" -DnsServers "10.0.0.1", "10.0.0.2" -WorkloadsDirectory "../workloads"

.NOTES

#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [string]$GlobalId, 
    [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [string]$WorkloadsDirectory,
    [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [string]$HubNetworkResourceId,
    [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [string[]]$DnsServers = @("10.0.0.1","10.0.0.2")
)

# Break on any error
$ErrorActionPreference = "Stop"

Write-Host "Start generating files for $GlobalId..."

function Install-RequiredModules() {
    # Check if powershell-yaml and Az.Subscription modules are installed
    try {
        if ((Get-Module -Name powershell-yaml -ListAvailable).Count -eq 0) {
            # powershell-yaml module is not installed
            Write-Host "powershell-yaml module is not installed. Installing module..."
            Install-Module -Name powershell-yaml -Scope CurrentUser -Force
        }
        else {
            Write-Host "powershell-yaml module is already installed."
        }
    }
    catch {
        # Log an error message if an error occurs while installing the powershell-yaml module
        Write-Host "Error installing powershell-yaml module: $_"
    }

    try {
        if ((Get-Module -Name Az.Subscription -ListAvailable).Count -eq 0) {
            # Az.Subscription module is not installed
            Write-Host "Az.Subscription module is not installed. Installing module..."
            Install-Module -Name Az.Subscription -Scope CurrentUser -Force
        }
        else {
            # Az.Subscription module is installed
            Write-Host "Az.Subscription module is already installed."
        }
    }
    catch {
        # Log an error message if an error occurs while installing the Az.Subscription module
        Write-Host "Error installing Az.Subscription module: $_"
    }
}

function Get-SubscriptionData() {
    param(
        [hashtable]$Request,
        [hashtable]$Subscription
    ) 
    $subHashTable = [ordered]@{
        name= "sub-$($Request.organization)-$($Request.global_id)-$($subscription.environment)-001"        
        request_id = $($Request.request_id)
        global_id = $($Request.global_id)
        workload= $($Request.workload)
        billing_enrollment_account= $($Request.billing_enrollment_account)
        management_group_id= $($Request.management_group_id)
        network_watcher_resource_group_enabled = $($Request.network_watcher_resource_group_enabled)
        contact_email_address = $($Request.contact_email_address)
        alternative_email_addresses = @($Request.alternative_email_addresses)
        tags = $Request.tags
        aad_groups = $($Request.aad_groups)
        environment = $Subscription.environment
    }
    return $subHashTable
}

function Get-BuildData() {
    param(
        [string]$Location,
        [hashtable]$Request,
        [hashtable]$Subscription
    ) 
    $buildHashTable = [ordered]@{
        virtual_networks = @{
            vnet001 = @{
                name = "vnet-$($Request.global_id)-$($Location)-$($Subscription.environment)-001"
                address_space = @($Subscription.address_space)
                peering = $Subscription.peering
                dns_servers = @($DnsServers)
                hub_peering_enabled= If ($HubNetworkResourceId -eq '') { 'fa;se' } else { 'true' }
                hub_network_resource_id = $HubNetworkResourceId
                hub_peering_use_remote_gateways = 'false' # Static values
                resource_group_name= "rg-$($Request.global_id)-$($Location)-$($Subscription.environment)-001"
                resource_group_lock_enabled= 'false'
            }
        }
        location = $Subscription.location
        budget_creation_enabled = 'true'
        budgets = @{budget = $Subscription.budget}
        health_alerts_enabled= 'false'
        role_assignment_enabled= 'true'
        role_assignments= @{
            assignment_1 = @{
                principal_id= "$($Request.aad_groups.contributor)" # group id
                definition= "Contributor"
                relative_scope= ''}
            assignment_2 = @{
                principal_id= "$($Request.aad_groups.reader)" # group id
                definition= "Reader"
                relative_scope= ''}
            }
    }
    $subData = Get-SubscriptionData -Request $Request -Subscription $Subscription
    return $subData + $buildHashTable
}

function New-SubscriptionYamlFile() {
    param(
        [hashtable]$Request,
        [hashtable]$Subscription
    ) 
    $data = Get-SubscriptionData -Request $Request -Subscription $Subscription
    $content = ConvertTo-Yaml -data $data -UseFlowStyle
    $content -replace '"','' | Out-File -FilePath "$WorkloadsDirectory/subscriptions/$GlobalId/$($data.name).yml" -Force
}

function New-BuildYamlFile() {
    param(
        [hashtable]$Request,
        [hashtable]$Subscription
    )
    $location = $Subscription.location -replace 'westus2','wus2' -replace 'centralus','cus'
    $data = Get-BuildData -Location $location -Request $Request -Subscription $Subscription
    $content = ConvertTo-Yaml -data $data -UseFlowStyle
    $content -replace '"','' | Out-File -FilePath "$WorkloadsDirectory/builds/$GlobalId/$($data.name).yml" -Force
}    

# Install modules
Install-RequiredModules

# Load Request
$request = Get-Content "$WorkloadsDirectory/requests/$GlobalId/" -Raw | ConvertFrom-Json -Depth 100 -AsHashtable

# For each subscription, create a subscription YAML and build/resource YAML
foreach ($subscription in $request.subscriptions) {
    New-SubscriptionYamlFile -Request $request -Subscription $subscription
    New-BuildYamlFile -Request $request -Subscription $subscription
}

Write-Host "Completed generating files."