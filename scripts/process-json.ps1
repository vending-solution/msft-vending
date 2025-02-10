

# Check if powershell-yaml and Az.Subscription modules are installed
try {
    if ((Get-Module -Name powershell-yaml -ListAvailable).Count -eq 0) {
        # powershell-yaml module is not installed
        write-output "powershell-yaml module is not installed. Installing module..."
        Install-Module -Name powershell-yaml -Scope CurrentUser -Force
    }
    else {
        write-output "powershell-yaml module is already installed."
    }
}
catch {
    # Log an error message if an error occurs while installing the powershell-yaml module
    write-output "Error installing powershell-yaml module: $_"
}

try {
    if ((Get-Module -Name Az.Subscription -ListAvailable).Count -eq 0) {
        # Az.Subscription module is not installed
        write-output "Az.Subscription module is not installed. Installing module..."
        Install-Module -Name Az.Subscription -Scope CurrentUser -Force
    }
    else {
        # Az.Subscription module is installed
        write-output "Az.Subscription module is already installed."
    }
}
catch {
    # Log an error message if an error occurs while installing the Az.Subscription module
    write-output "Error installing Az.Subscription module: $_"
}

$json = Get-Content ..\schemas\request-example.json -Raw | ConvertFrom-Json -Depth 5 -AsHashtable

foreach ($subscription in $json.subscriptions) {

    write-output "sub-$($json.organization)-$($json.global_id)-$($subscription.environment)-001"
    $fileName = "sub-$($json.organization)-$($json.global_id)-$($subscription.environment)-001"
    $location = $subscription.location -replace 'westus2','wus2' -replace 'centralus','cus'
    $subHashTable = [ordered]@{
        subscription_id = $($subscription.subscription_id)
        name= "sub-$($json.organization)-$($json.global_id)-$($subscription.environment)-001"
        # subscription_display_name = $($subscription.subscription_display_name)
        # subscription_alias_name = $($subscription.subscription_alias_name)
        request_id = $($json.request_id)
        global_id = $($json.global_id)
        workload= $($json.workload)
        billing_enrollment_account= $($json.billing_enrollment_account)
        management_group_id= $($json.management_group_id)
        network_watcher_resource_group_enabled = $($json.network_watcher_resource_group_enabled)
        contact_email_address = $($json.contact_email_address)
        alternative_email_addresses = @($json.alternative_email_addresses)
        tags = $json.tags
        aad_groups = $($json.aad_groups)
        environment = $subscription.environment
        virtual_networks = @{
            vnet1 = @{
                name = "vnet-$($json.global_id)-$($location)-$($subscription.environment)-001"
                address_space = @($subscription.address_space)
                peering = $subscription.peering
                dns_servers = @("10.0.0.1","10.0.0.2")
                hub_peering_enabled= 'false' # Static values
                hub_network_resource_id = "/subscriptions/d200e3b2-/resourceGroups/cesart10-connectivity-eastus/providers/Microsoft.Network/virtualNetworks/cesart10-hub-eastus"
                hub_peering_use_remote_gateways = 'false' # Static values
                resource_group_name= "rg-$($json.global_id)-$($location)-$($subscription.environment)-001"
                resource_group_lock_enabled= 'false'
            }
        }
        location = $subscription.location
        budget_creation_enabled = 'true'
        budgets = @{budget = $subscription.budget}
        health_alerts_enabled= 'false'
        role_assignment_enabled= 'true'
        role_assignments= @{
                                    my_assignment_1 = @{
                                        principal_id= "$($json.aad_groups.contributor)" # group id
                                        definition= "Contributor"
                                        relative_scope= ''}
                                    my_assignment_2 = @{
                                        principal_id= "$($json.aad_groups.reader)" # group id
                                        definition= "Reader"
                                        relative_scope= ''}

                                    }
    
    }                                
    $subYMLFile = ConvertTo-Yaml -data $subHashTable -UseFlowStyle

    Get-ChildItem -Path .\$fileName.yml | Remove-Item

    $subYMLFile -replace '"','' | Out-File -FilePath ./$fileName.yml
    
    write-output '################################################'
}
