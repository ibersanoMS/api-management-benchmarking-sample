# Workflows

## Validate
- Runs on a pull request to main
- Formats and validates your Terraform and then commits the formatting changes back to your branch
- Does not initialize Terraform with backend storage, but you can modify the Terraform init command to do so. It is not necessary because we are not modifying the resources and we do not need state information to check the formatting

## Build and Deploy

- Runs on a push to main
- Handles setting up and/or creating remote storage and deploying the Terraform
- Utilizes Azure Service Principal OIDC authentication with Federated Credentials for GitHub

## Destroy
- Runs on manual dispatch
- Handles destroying your existing Terraform infrastructure that you've deployed
- Utilizes Azure Service Principal OIDC authentication with Federated Credentials for GitHub
