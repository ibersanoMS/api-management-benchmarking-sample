resource "random_string" "uniqueString" {
  length  = 6
  special = false
  upper   = false
}

# App insights for sample api
resource "azurerm_log_analytics_workspace" "law" {
  name                = "apimLoadTesting-${random_string.uniqueString.result}"
  location            = var.location
  resource_group_name = var.resourceGroupName
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "apimLoadTesting" {
  name                = "apimLoadTesting-${random_string.uniqueString.result}"
  resource_group_name = var.resourceGroupName
  location            = var.location
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.law.id
}

# App Service Plan for hosting the sample api
resource "azurerm_service_plan" "appServicePlan" {
  name                = "apimLoadTesting-${random_string.uniqueString.result}"
  resource_group_name = var.resourceGroupName
  location            = var.location
  os_type             = "Linux"
  sku_name            = "P1V3"
  tags = {
    environment = "Dev"
  }
}

# App Service for hosting the sample api
resource "azurerm_linux_web_app" "api" {
  name                = "${var.apiName}-${random_string.uniqueString.result}"
  resource_group_name = var.resourceGroupName
  location            = var.location
  service_plan_id     = azurerm_service_plan.appServicePlan.id

  site_config {
    application_stack {
      docker_image_name   = "kong/httpbin:latest"
      docker_registry_url = "https://index.docker.io"
    }
    always_on = true
  }
  
  app_settings = {
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.apimLoadTesting.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.apimLoadTesting.connection_string
  }
  
}

# API for sample api in api management
resource "azurerm_api_management_api" "api" {
  name                  = var.apiName
  resource_group_name   = var.resourceGroupName
  api_management_name   = var.apiManagementInstanceName
  subscription_required = false
  revision              = "1"
  display_name          = var.apiName
  protocols             = ["https"]

  import {
    content_format = "swagger-link-json"
    content_value  = "https://raw.githubusercontent.com/Azure/api-management-samples/master/apis/httpbin.swagger.json"
  }
}

resource "azurerm_api_management_api_policy" "apiPolicy" {
  api_management_name = var.apiManagementInstanceName
  api_name            = azurerm_api_management_api.api.name
  resource_group_name = var.resourceGroupName
  xml_content         = <<XML
    <policies>
      <inbound>
          <base />
          <set-backend-service base-url="https://${azurerm_linux_web_app.api.name}.azurewebsites.net/" />
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

resource "azurerm_api_management_logger" "apiLogger" {
  name                = "AppInsights"
  api_management_name = var.apiManagementInstanceName
  resource_group_name = var.resourceGroupName
  resource_id         = azurerm_application_insights.apimLoadTesting.id

  application_insights {
    instrumentation_key = azurerm_application_insights.apimLoadTesting.instrumentation_key
  }
}

resource "azurerm_api_management_api_diagnostic" "linkAppInsightsToApi" {
  identifier               = "applicationinsights"
  resource_group_name      = var.resourceGroupName
  api_management_name      = var.apiManagementInstanceName
  api_name                 = azurerm_api_management_api.api.name
  api_management_logger_id = azurerm_api_management_logger.apiLogger.id

  sampling_percentage       = 100.0
  always_log_errors         = true
  log_client_ip             = true
  verbosity                 = "information"
  http_correlation_protocol = "W3C"

  frontend_request {
    body_bytes = 32
    headers_to_log = [
      "content-type",
      "accept",
      "origin",
    ]
  }

  frontend_response {
    body_bytes = 32
    headers_to_log = [
      "content-type",
      "content-length",
      "origin",
    ]
  }

  backend_request {
    body_bytes = 32
    headers_to_log = [
      "content-type",
      "accept",
      "origin",
    ]
  }

  backend_response {
    body_bytes = 32
    headers_to_log = [
      "content-type",
      "content-length",
      "origin",
    ]
  }
}