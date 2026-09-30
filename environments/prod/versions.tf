terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.50"
    }
  }

  # Local state is fine for a personal lab. For team use, move state into a
  # storage account (see docs/LAB-GUIDE.md, "Level up" section):
  #
  # backend "azurerm" {
  #   resource_group_name  = "rg-tfstate"
  #   storage_account_name = "sttfstate<unique>"
  #   container_name       = "tfstate"
  #   key                  = "landingzone.prod.tfstate"
  # }
}

provider "azurerm" {
  features {
    resource_group {
      # Lets `terraform destroy` succeed even if something was created in a
      # resource group by hand during the lab (e.g. while testing policy).
      prevent_deletion_if_contains_resources = false
    }
  }

  subscription_id = var.subscription_id
}
