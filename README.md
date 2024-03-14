# Getting Started with Azure API Management Self-Hosted Gateway Testing using Terraform

Use this repository to create an environment to test API Management Self-Hosted Gateway using GitHub workflows for validation and deployment on Azure. 

This template has basic workflows and scripts needed for the workflows in the ```.github/ ``` folder and basic Terraform files in the ``` src/ ``` folder.

These are the workflows contained in this repository:
- ``` validate.yml ``` This workflow runs on a pull request to main. It formats and validates your Terraform and then commits the formatting changes back to your branch. 
- ``` build-and-deploy.yml ``` This workflow runs on a push to main. It handles setting up and/or creating remote storage and deploying the Terraform code.
- ``` destroy.yml ``` This workflow runs on manual dispatch. It will delete your Terraform infrastructure on demand.
- ``` dependabot.yml ``` Handles package management for GitHub Actions and Terraform versions. 

The [Terraform code](/src/) included in this repository demonstrates basic file structure for a Terraform solution:
- ``` main.tf ``` This file contains either resource definitions or references to [Terraform modules](/src/infra/modules/) to deploy.  
- ``` providers.tf ``` This file contains the Terraform providers needed for the solution and the versions or features required for each. 
- ``` variables.tf ``` This file contains definitions for variables used in the Terraform deployment. 
- ``` outputs.tf ``` This file contains definitions for outputs from the Terraform deployment. 
- ``` variables.tfvars``` This file contains definitions in the format ```variable_name=example``` of variables to be used in the deployment. This file is for local deployments and should NOT be committed to a repository as it may contain passwords, credentials, or other sensitive information. 

## Environment Setup
- API Management Service with a Premium SKU
- App Service hosting a sample api
- AKS cluster to host self-hosted gateway 
- Application Insights for monitoring
- Container Insights for monitoring self-hosted gateway memory and CPU usage
- Azure Load Test

<Need diagram>

## Credential Setup

You will need a service principal that is scoped to either the subscription level or resource group level. This repository uses [OIDC authentication](https://learn.microsoft.com/en-us/azure/active-directory/fundamentals/auth-oidc) for [Azure login](https://github.com/Azure/login). This method requires [Federated Credentials](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-portal%2Cwindows#add-federated-credentials) for GitHub to deploy resources to Azure on your behalf. Follow the steps below for setting them up in the portal or use the Azure CLI or PowerShell instructions in the provided link. 

Follow the steps below to setup:
1. Navigate to your service principal in the Azure Portal
2. Click on Certificates and Secrets and then Federated Credentials
3. Click on Add credential and select *GitHub Actions deploying Azure resources*
4. Fill out your organization, repository, and entity type information.
5. If you only want users to deploy resources off the main branch, select *Branch* as the entity type and put *main* as the branch name.
6. If you only want users to deploy resources into a specific environment, select *Environment* as the entity type and put your environment name in the name field.
7. If you only want users to deploy resources during a pull request, select *Pull request* as the entity type. 
8. If you only want users to deploy resources off a GitHub tag, select *Tag* as the entity type. 

## Terraform Remote State Storage
This repository configures Terraform remote state using an Azure Storage Account with a Blob container. You can also use [Terraform Cloud](https://learn.microsoft.com/en-us/shows/devops-lab/remote-state-management-with-terraform-cloud) to store state and you would need to make the following modifications to use that feature:

1. In the [Setup Terraform] step in the [build and deploy workflow](.github/workflows/build-and-deploy.yml), replace the setup with the following:
``` 
- name: Setup Terraform
        uses: hashicorp/setup-terraform@v1
        with:
          cli_config_credentials_token: ${{ secrets.TF_API_TOKEN }}    
```
2. You will need to add a new GitHub secret to your repository with the above name. The [API token](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/api-tokens) will come from the [Terraform Cloud Portal](https://app.terraform.io/session). 

## GitHub Action Secrets Required

Create the following secrets in your GitHub repository:
- ``` AZURE_TENANT_ID  ``` 
- ``` AZURE_SUBSCRIPTION_ID ```
- ``` AZURE_CLIENT_ID ```
- ``` STATE_STORE_RGNAME  ``` Existing resource group or name of one to be created for your remote state storage account
- ``` STORAGE_ACCOUNT_NAME ``` Existing storage account or name of one to be created for your Terraform remote state to be stored
- ``` STATE_STORAGE_CONTAINER_NAME ``` Existing container name or name of one to be created for your Terraform remote state to be stored
- ``` STATE_STORE_FILENAME ``` Existing filename or new filename for your Terrform state file
- ``` DESTROY_TERRAFORM ``` True or False. Whether you want to destroy the Terraform architecture after it's been created through the workflow. 
- ``` LOCATION ``` Location where you want the Azure resources and Terraform state storage to be deployed. 
- ``` CREATE_STATE_STORE ``` True or False. Whether you want to create a new storage account for your remote state or if you have an existing one you'd like to use. 

## Development Process

- Create a feature/fix branch in your repository 
- When you create a pull request, it will trigger the validate workflow to check your Terraform syntax and format it. 
- Once the validate workflow has completed successfully, you can merge in your changes
- Once the changes are merged in, it will trigger the build and deploy workflow to test deploying the architecture. 
