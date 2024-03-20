output "resourceGroupName" {
  value = azurerm_resource_group.loadTesting.name
}

output "apiManagementServiceName" {
    value = azurerm_api_management.loadTesting.name
}
