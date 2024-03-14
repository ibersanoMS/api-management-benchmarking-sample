variable "location" {
    default = "eastus"
    type = string
}

variable "apiName" {
    default = "httpbin"
    type = string
}

variable "resourceGroupName" {
    default = "APIM-SelfHostedGatewayTesting"
    type = string
}

variable "apiManagementInstanceName" {
    default = "shgTesting"
    type = string
}