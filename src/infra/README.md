# Formatting
The examples below demonstrate how to format the files in this folder.

## Variables
``` 
variable "rg_name" {
  description = ""
  type = string
  default = ""
}
```

## Outputs
```
output "rg_name" {
  description = ""
  value = ""
 }
 ```
 
 ## Referencing Modules
 ```
 module "aks_example" {
  source            = "./modules/aks"
  sku               = var.sku
  name              = "example"
  subnet_id         = ""
}
```

