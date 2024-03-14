data "azurerm_api_management" "apiManagementInstance" {
  resource_group_name = var.resourceGroupName
  name = var.apiManagementInstanceName
}

data "azurerm_api_management_gateway" "gateway" {
  api_management_id = data.azurerm_api_management.apiManagementInstance.id
  name = "AKS"
}

# API for sample api in api management
resource "azurerm_api_management_api" "api" {
  name = var.apiName
  resource_group_name = var.resourceGroupName
  api_management_name = var.apiManagementInstanceName
  subscription_required = false
  revision = "1"
  display_name = var.apiName
  protocols = ["https"]
  service_url = "http://httpbin.default.svc.cluster.local:8000"
  import {
    content_format = "swagger-link-json"
    content_value = "https://raw.githubusercontent.com/Azure/api-management-samples/master/apis/httpbin.swagger.json"
  }
}

resource "azurerm_api_management_api_policy" "sampleApiPolicy" {
  api_management_name = var.apiManagementInstanceName
  api_name = azurerm_api_management_api.api.name
  resource_group_name = var.resourceGroupName
  xml_content = <<XML
    <policies>
      <inbound>
          <base />
          <set-backend-service base-url="http://httpbin.default.svc.cluster.local:8000" />
      </inbound>
      <backend>
          <base />
      </backend>
      <outbound>
          <base />
      </outbound>
      <on-error>
          <base />
      </on-error>
  </policies>
  XML
}

resource "azurerm_api_management_gateway_api" "associateSampleApi" {
  gateway_id = data.azurerm_api_management_gateway.gateway.id
  api_id = azurerm_api_management_api.api.id
}