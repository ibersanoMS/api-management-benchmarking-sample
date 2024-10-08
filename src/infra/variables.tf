variable "location" {
  type    = string
  default = "eastus"
}

variable "apimSkuName" {
  type    = string
  default = "Premium_1"
}

variable "publisherName" {
  type    = string
  default = "APIM Load Testing"
}

variable "publisherEmail" {
  type = string
}

variable "apiName" {
  type    = string
  default = "httpbin"
}

variable "resourceGroupName" {
  type    = string
  default = "APIM-LoadTesting"
}