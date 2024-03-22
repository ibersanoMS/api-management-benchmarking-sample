output "backendUrl" {
  value = azurerm_linux_web_app.api.default_hostname
}