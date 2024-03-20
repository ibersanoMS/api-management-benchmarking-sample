data "azurerm_client_config" "current" {}

resource "random_string" "uniqueString" {
  length  = 6
  special = false
  upper   = false
}

# Resource Group for all resources
resource "azurerm_resource_group" "loadTesting" {
  name     = var.resourceGroupName
  location = var.location
}

# API Management Service
resource "azurerm_api_management" "loadTesting" {
  name                = "loadTesting-${random_string.uniqueString.result}"
  resource_group_name = azurerm_resource_group.loadTesting.name
  location            = azurerm_resource_group.loadTesting.location
  publisher_name      = var.publisherName
  publisher_email     = var.publisherEmail
  sku_name            = var.apimSkuName
}

# Azure Load Test
resource "azurerm_load_test" "apimLoadTesting" {
  name                = "basic-${random_string.uniqueString.result}"
  resource_group_name = azurerm_resource_group.loadTesting.name
  location            = azurerm_resource_group.loadTesting.location
}

# Sample API - default is httpbin
module "api" {
  source                    = "./sample-apis/basic-api"
  location                  = var.location
  resourceGroupName         = azurerm_resource_group.loadTesting.name
  apiManagementInstanceName = azurerm_api_management.loadTesting.name
}