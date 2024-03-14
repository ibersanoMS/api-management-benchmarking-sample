output "resourceGroupName" {
  value = azurerm_resource_group.selfHostedGatewayTesting.name
}

output "apiManagementServiceName" {
    value = azurerm_api_management.selfHostedGatewayTesting.name
}

output "clusterName" {
    value = azurerm_kubernetes_cluster.selfHostedGateway.name
}

output "aksDnsPrefix" {
  value = azurerm_kubernetes_cluster.selfHostedGateway.dns_prefix
}

output "gatewayName" {
  value = azurerm_api_management_gateway.selfHostedGateway.name
}

output "keyVaultName" {
  value = azurerm_key_vault.selfHostedGateway.name
}

output "keyVaultId" {
    value = azurerm_key_vault.selfHostedGateway.id
}

output location {
    value = azurerm_resource_group.selfHostedGatewayTesting.location
}