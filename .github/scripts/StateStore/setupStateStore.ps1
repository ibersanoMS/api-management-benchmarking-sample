## This script creates a storage account to store the remote state of Terraform code.
## We are using the CLI so that the state of the storage account doesn't need to be managed. 

## ------------------------------------------------------------------------
## Input Parameters
## 
## ------------------------------------------------------------------------

param(
  [Parameter()]
  [String]$resourceGroupName,
  [String]$location,
  [String]$storageAccountName
) 

## ------------------------------------------------------------------------
## Resource Group for State Store
## Check if resource groups exists with name provided, if not create it
## ------------------------------------------------------------------------

Write-Output "*** Check if Resource Group $resourceGroupName exists"
$checkRg = az group exists --name $resourceGroupName | ConvertFrom-Json
if (!$checkRg) {
  Write-Warning "*** WARN! Resource Group $resourceGroupName does not exist. Creating..."
  az group create --name $resourceGroupName --location $location

  if ($LastExitCode -ne 0) {
    throw "*** Error - could not create resource group"
  }
}
else
{
  Write-Output "*** Ok"
}

## ------------------------------------------------------------------------
## Storage Account
## Create storage account for state store
## ------------------------------------------------------------------------

Write-Output "*** Check if Storage Account $storageAccountName exists"
$check = az storage account show --name $storageAccountName --resource-group $resourceGroupName | ConvertFrom-Json
if (!$check) {
  Write-Warning "*** WARN! Storage Account $storageAccountName does not exist. Creating..."

  Write-Output "*** Creating storage account"
  # If enabling private endpoints down below, we create the storage account with public access disabled to comply with Azure polices that might be in place
  az storage account create --name $storageAccountName `
                            --resource-group $resourceGroupName `
                            --https-only true `
                            --sku Standard_LRS `
                            --min-tls-version TLS1_2
  if ($LastExitCode -ne 0) {
    throw "*** Error - could not create storage account"
  }
}
  
else
{
  Write-Output "*** Ok"
}

## ------------------------------------------------------------------------
## Resource Lock
## Put a resource lock on the storage account 
## ------------------------------------------------------------------------

Write-Output "*** Set a resource lock on storage account $storageAccountName"
az lock create --name LockStateStore `
        --lock-type CanNotDelete `
        --resource-group $resourceGroupName `
        --resource-name  $storageAccountName `
        --resource-type Microsoft.Storage/storageAccounts

if ($LastExitCode -ne 0) {
  throw "*** Error - could not create resource lock on storage account"
}

$servicePrincipalId = $(az account show --query "user.name" -o tsv)
$storageAccountId = $(az storage account show --name $storageAccountName `
                                              --resource-group $resourceGroupName `
                                              --query "id" -o tsv)

## --------------------------------------------------------------------------------------
## Role Assignment
## Create role assignment for the deploying service principal on the storage account.
## Terraform will then use RBAC to access the storage account instead of account keys
## --------------------------------------------------------------------------------------

$roleName = "Storage Blob Data Owner"

# Check if the role assignment already exists. MUST be generated using a service principal, not specific user
$existingRole = az role assignment list --assignee $servicePrincipalId --role $roleName --scope $storageAccountId | ConvertFrom-Json

if(-not $existingRole)
{
  Write-Output "*** Creating role assignment $roleName for deploying service principal on $storageAccountId"
  az role assignment create --assignee $servicePrincipalId --role $roleName --scope $storageAccountId
}
else
{
  Write-Output "*** Role assignment $roleName already exists on Terraform state storage $storageAccountName"
}

if ($LastExitCode -ne 0) {
  throw "*** Error - could not create role assignment"
}

##------------------------------------------------------------------------
## Storage Container
## Create blob storage container for state files
##------------------------------------------------------------------------

$terraformContainerName = "tfstate" # do not change unless you have a strong reason to. If so, also change in 'terraform init' step template
Write-Output "*** Check if Container $terraformContainerName exists"
$check = az storage container exists --account-name $storageAccountName `
                                      --name $terraformContainerName --auth-mode login | ConvertFrom-Json
if (!$check.exists) {
  Write-Warning "*** WARN! Container $terraformContainerName does not exist. Creating..."
  az storage container create --name $terraformContainerName `
                              --account-name $storageAccountName `
                              --public-access off `
                              --auth-mode login

  if ($LastExitCode -ne 0) {
    throw "*** Error - could not create storage container"
  }
}
else
{
  Write-Output "*** Ok"
}

# ------------------------------------------------------------------------
# Storage Account Versioning
# Set versioning properties on blob to enable soft delete
# ------------------------------------------------------------------------

# Enable 7 days soft delete on container and blob-level for the TF state storage account
# The command is idempotent, so we can run it every time without other checks

Write-Output "*** Enabling versioning and soft delete on container- and blob-level"
az storage account blob-service-properties update `
                                          --account-name $storageAccountName `
                                          --resource-group $resourceGroupName `
                                          --enable-versioning true `
                                          --enable-delete-retention true `
                                          --delete-retention-days 7 `
                                          --enable-container-delete-retention true `
                                          --container-delete-retention-days 7
if ($LastExitCode -ne 0) {
  throw "*** Error - could not update storage account properties"
}
