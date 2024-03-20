resource "azurerm_api_management_api" "loadTestApi" {
  name = "load-test-500-bytes"
  display_name = "Load Test (500 bytes)"
  resource_group_name = var.resourceGroupName
  api_management_name = var.apiManagementInstanceName
  subscription_required = false
  protocols = ["https"]
  revision = "1"
}

resource "azurerm_api_management_api_operation" "loadTestApiOperation" {
  api_management_name = var.apiManagementInstanceName
  resource_group_name = var.resourceGroupName
  api_name = azurerm_api_management_api.loadTestApi.name
  display_name = "load-test-500-bytes"
  method = "GET"
  url_template = "/load-test"
  operation_id = "load-test-500-bytes"
}

resource "azurerm_api_management_api_operation_policy" "loadTestApiOperationPolicy" {
    api_management_name = var.apiManagementInstanceName
    api_name = azurerm_api_management_api.loadTestApi.name
    operation_id = azurerm_api_management_api_operation.loadTestApiOperation.operation_id
    resource_group_name = var.resourceGroupName
    xml_content = <<XML
        <policies>
        <inbound>
            <return-response>
                <set-status code="200" reason="OK" />
                <set-header name="Content-Type" exists-action="override">
                    <value>application/json</value>
                </set-header>
                <set-body>{"data":"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstu"}</set-body>
		    </return-response>
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


resource "azurerm_api_management_product" "loadTestProduct" {
    api_management_name = var.apiManagementInstanceName
    resource_group_name = var.resourceGroupName
    display_name = "Load Test"
    description = "No Auth, No logging, 500 byte response body"
    subscription_required = false
    published = true
    product_id = "load-test"
}

resource "azurerm_api_management_product_api" "loadTestProductApi" {
  api_management_name = var.apiManagementInstanceName
  product_id = azurerm_api_management_product.loadTestProduct.product_id
  api_name = azurerm_api_management_api.loadTestApi.name
  resource_group_name = var.resourceGroupName
}