terraform {
  backend "local" {
  }
  //   required_providers {
  //     azurerm = {
  //       source  = "hashicorp/azurerm"
  //       version = "=2.99.0"
  //     }
  //   }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false 
      }
  }
   subscription_id = "" # abrego-4 # "ee5d2fa3-deed-4b33-bc7c-b5fbe997bc65" abrego-1

}
