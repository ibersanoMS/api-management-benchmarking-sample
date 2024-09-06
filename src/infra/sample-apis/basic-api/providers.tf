# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.1.0"
    }
  }
  required_version = ">= 1.3.4"

  # backend "azurerm" {
  # }
}
provider "azurerm" {
  features {}
}

