<#
.SYNOPSIS
    This script processes a JSON file and converts its content to YAML format.

.DESCRIPTION
    The script reads a JSON file containing subscription details, converts the data to a YAML format, and saves the YAML files to a specified output directory. It also ensures that the required PowerShell modules (powershell-yaml and Az.Subscription) are installed.

.PARAMETER JsonFilePath
    The path to the input JSON file. Default is ".\request.json".

.PARAMETER OutputDirectory
    The directory where the YAML files will be saved. Default is the current directory.

.EXAMPLE
    .\process-json.ps1 -JsonFilePath ".\input.json" -OutputDirectory ".\output"

.NOTES
    Author: Your Name
    Date: February 10, 2025
#>

param (
    [string]$JsonFilePath = ".\request.json",
    [string]$OutputDirectory = "."
)

# Check if powershell-yaml and Az.Subscription modules are installed
try {
    if ((Get-Module -Name powershell-yaml -ListAvailable).Count -eq 0) {
        # powershell-yaml module is not installed
        Write-Output "powershell-yaml module is not installed. Installing module..."
        Install-Module -Name powershell-yaml -Scope CurrentUser -Force
    }
    else {
        # Write-Output "powershell-yaml module is already installed."
    }
}
catch {
    # Log an error message if an error occurs while installing the powershell-yaml module
    Write-Output "Error installing powershell-yaml module: $_"
}

try {
    if ((Get-Module -Name Az.Subscription -ListAvailable).Count -eq 0) {
        # Az.Subscription module is not installed
        Write-Output "Az.Subscription module is not installed. Installing module..."
        Install-Module -Name Az.Subscription -Scope CurrentUser -Force
    }
    else {
        # Az.Subscription module is installed
        # Write-Output "Az.Subscription module is already installed."
    }
}
catch {
    # Log an error message if an error occurs while installing the Az.Subscription module
    Write-Output "Error installing Az.Subscription module: $_"
}

# Read and parse the JSON file
$json = Get-Content $JsonFilePath -Raw | ConvertFrom-Json -Depth 5 -AsHashtable

# Iterate through each subscription in the JSON data
foreach ($subscription in $json.subscriptions) {
    # Generate the file name based on the subscription details

    Write-Output "Processing subscription sub-$($json.organization)-$($json.global_id)-$($subscription.environment)-001"
    $fileName = "sub-$($json.organization)-$($json.global_id)-$($subscription.environment)-001"
    $location = $subscription.location -replace 'westus2','wus2' -replace 'centralus','cus'
    
    # Create a hashtable with subscription details
    $subHashTable = [ordered]@{
        subscription_id = $($subscription.subscription_id)
        name= "sub-$($json.organization)-$($json.global_id)-$($subscription.environment)-001"
        request_id = $($json.request_id)
        global_id = $($json.global_id)
        workload= $($json.workload)
        billing_enrollment_account= $($json.billing_enrollment_account)
        management_group_association_enabled = $($json.management_group_association_enabled)
        management_group_id= $($json.management_group_id)
        network_watcher_resource_group_enabled = $($json.network_watcher_resource_group_enabled)
        contact_email_address = $($json.contact_email_address)
        alternative_email_addresses = @($json.alternative_email_addresses)
        tags = $json.tags
        aad_groups = $($json.aad_groups)
        environment = $subscription.environment
        virtual_network_enabled = $($subscription.virtual_network_enabled)
        virtual_networks = @{
            vnet1 = @{
                name = "vnet-$($json.global_id)-$($location)-$($subscription.environment)-001"
                address_space = @($subscription.address_space)
                peering = $subscription.peering
                dns_servers = @("10.0.0.1","10.0.0.2")
                hub_peering_enabled= 'false' # Static values
                hub_network_resource_id = "/subscriptions/d200e3b2-c0dc-4076-bd30-4ccccf05ffeb/resourceGroups/cesart10-connectivity-eastus/providers/Microsoft.Network/virtualNetworks/cesart10-hub-eastus"
                hub_peering_use_remote_gateways = 'false' # Static values
                resource_group_name= "rg-$($json.global_id)-$($location)-$($subscription.environment)-001"
                resource_group_lock_enabled= 'false'
            }
        }
        location = $subscription.location
        budget_creation_enabled = 'true'
        budgets = @{budget = $subscription.budget}
        health_alerts_enabled = 'false'
        role_assignment_enabled = $($json.role_assignment_enabled)
        role_assignments= @{
            my_assignment_1 = @{
                principal_id = "$($json.aad_groups.contributor)" # group id
                definition= "Contributor"
                relative_scope = ''
            }
            my_assignment_2 = @{
                principal_id = "$($json.aad_groups.reader)" # group id
                definition = "Reader"
                relative_scope = ''
            }
        }
    }
    
    # Convert the hashtable to YAML format
    $subYMLFile = ConvertTo-Yaml -data $subHashTable -UseFlowStyle

    # Check if the YAML file exists before attempting to remove it
    $outputFilePath = Join-Path -Path $OutputDirectory -ChildPath "$fileName.yml"
    if (Test-Path -Path $outputFilePath) {
        Remove-Item -Path $outputFilePath -Force
    }

    # Write the YAML content to a file, removing double quotes
    $subYMLFile -replace '"','' | Out-File -FilePath $outputFilePath
    
    # Output a separator for readability
    Write-Output '################################################'
}