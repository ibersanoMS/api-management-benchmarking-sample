output "resourceGroupName" {
  value = azurerm_resource_group.loadTesting.name
}

output "apiManagementServiceName" {
  value = azurerm_api_management.loadTesting.name
}

output "loadTestName" {
  value = azurerm_load_test.apimLoadTesting.name
}

output "apiUrl" {
  value = azurerm_api_management.loadTesting.gateway_url
}
