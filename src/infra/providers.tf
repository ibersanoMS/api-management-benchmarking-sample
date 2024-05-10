# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.103.1"
    }
  }
  required_version = ">= 1.3.4"

  backend "azurerm" {
  }
}
provider "azurerm" {
  features {}
}