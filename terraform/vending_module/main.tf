variable "global_id" {
  type = string
}

locals {
  # landing_zone_data_dir is the directory containing the YAML files for the landing zones.
  landing_zone_data_dir = "${path.root}/${var.global_id}"

  # landing_zone_files is the list of landing zone YAML files to be processed
  landing_zone_files = fileset(local.landing_zone_data_dir, "sub*.yml")

  # landing_zone_data_map is the decoded YAML data stored in a map
  landing_zone_data_map = {
    for f in local.landing_zone_files :
    f => yamldecode(file("${local.landing_zone_data_dir}/${f}"))
  }
}

# The landing zone module will be called once per landing_zone_*.yaml file
# in the data directory.
module "lz_yml" {
  source   = "Azure/lz-vending/azurerm"
  disable_telemetry = true
    #   version  = "<version>" # change this to your desired version, https://www.terraform.io/language/expressions/version-constraints
    for_each = local.landing_zone_data_map

    location = each.value.location

    # subscription variables
    subscription_id = each.value.subscription_id
    subscription_alias_enabled = false
    #   subscription_billing_scope = "/providers/Microsoft.Billing/billingAccounts/1234567/enrollmentAccounts/${each.value.billing_enrollment_account}"
  subscription_display_name  = each.value.name
  subscription_alias_name    = each.value.name
  subscription_workload      = each.value.workload

  network_watcher_resource_group_enabled = each.value.network_watcher_resource_group_enabled

  # management group association variables
  subscription_management_group_association_enabled = true
  subscription_management_group_id                  = each.value.management_group_id

  # virtual network variables
  virtual_network_enabled = true
  virtual_networks        = each.value.virtual_networks

  # role assignment variables
  role_assignment_enabled = true
  role_assignments        = each.value.role_assignments
}

/*
module "lz_vending" {
  source  = "Azure/lz-vending/azurerm"
    #   version = "<version>" # change this to your desired version, https://www.terraform.io/language/expressions/version-constraints

  # Set the default location for resources
  location = "westus3"
  # subscription variables
  subscription_id = "6284f04c-ec26-45e3-a7a6-24c2ef4722e4"

  # subscription variables
  subscription_alias_enabled = false
    #   subscription_billing_scope = "/providers/Microsoft.Billing/billingAccounts/1234567/enrollmentAccounts/123456"
    subscription_display_name  = "ME-MngEnvMCAP478293-cabrego-3"
    subscription_alias_name    = "ME-MngEnvMCAP478293-cabrego-3"
    #   subscription_workload      = "Production"

  network_watcher_resource_group_enabled = true

  # management group association variables
  subscription_management_group_association_enabled = true
  subscription_management_group_id                  = "Corp"
  

  # virtual network variables
  virtual_network_enabled = true
  virtual_networks = {
    one = {
      name                    = "my-vnet1"
      resource_group_name     = "my-rg1"
      address_space           = ["192.168.1.0/24"]
      hub_peering_enabled     = false
      hub_network_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-hub-network-rg/providers/Microsoft.Network/virtualNetworks/my-hub-network"
      mesh_peering_enabled    = true
    }
    two = {
      name                    = "my-vnet2"
      resource_group_name     = "my-rg2"
      location                = "westus2"
      address_space           = ["192.168.2.0/24"]
      hub_peering_enabled     = false
      hub_network_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-hub-network-rg/providers/Microsoft.Network/virtualNetworks/my-hub-network2"
      mesh_peering_enabled    = true
    }
  }

  umi_enabled             = true
  umi_name                = "umi"
  umi_resource_group_name = "rg-identity"
  umi_role_assignments = {
    myrg-contrib = {
      definition     = "Contributor"
      relative_scope = "/resourceGroups/MyRg"
    }
  }

  resource_group_creation_enabled = true
  resource_groups = {
    myrg = {
      name     = "MyRg"
      location = "westeurope"
    }
  }

  # role assignments
  role_assignment_enabled = true
  role_assignments = {
    # using role definition name, created at subscription scope
    contrib_user_sub = {
      principal_id   = "afb20305-6add-4eba-9c4f-b4cd3948bb6f"
      definition     = "Contributor"
      relative_scope = ""
    },
    # using a custom role definition
    # custdef_sub_scope = {
    #   principal_id   = "afb20305-6add-4eba-9c4f-b4cd3948bb6f1"
    #   definition     = "/providers/Microsoft.Management/MyMg/providers/Microsoft.Authorization/roleDefinitions/ffffffff-ffff-ffff-ffff-ffffffffffff"
    #   relative_scope = ""
    # },
    # using relative scope (to the created or supplied subscription)
    rg_owner = {
      principal_id   = "afb20305-6add-4eba-9c4f-b4cd3948bb6f"
      definition     = "Owner"
      relative_scope = "/resourceGroups/MyRg"
    },
  }
}
*/