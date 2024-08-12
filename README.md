# Getting Started with Azure API Management Benchmarking with Azure Load Testing and JMeter

Use this repository to create an environment to perform basic benchmark testing on an API Management instance either using GitHub workflows or manually deploying the Terraform setup. If you choose to manually deploy the Terraform code, you will need to go into the Portal and follow the instructions in the [related blog post](https://techcommunity.microsoft.com/t5/apps-on-azure-blog/benchmark-testing-puts-you-on-the-path-to-peak-api-performance/ba-p/4216776) to run your load tests.

This repo has basic workflows in the ```.github/``` folder and Terraform deployment files in the ``` src/infra ``` folder.

These are the workflows contained in this repository:

- ``` validate.yml ``` This workflow runs on a pull request to main. It formats and validates your Terraform and then commits the formatting changes back to your branch. 
- ``` build-and-deploy.yml ``` This workflow runs on a push to main or a manual dispatch. It handles deploying the Terraform code and running three basic load tests. 
- ``` destroy.yml ``` This workflow runs on manual dispatch. It will delete your Terraform infrastructure on demand.
- ``` dependabot.yml ``` Handles package management for GitHub Actions and Terraform versions. 

The [Terraform code](/src/infra) included in this repository demonstrates basic file structure for a Terraform solution:

- ``` main.tf ``` This file contains either resource definitions or references to [Terraform modules](/src/infra/modules/) to deploy.  
- ``` providers.tf ``` This file contains the Terraform providers needed for the solution and the versions or features required for each.
- ``` variables.tf ``` This file contains definitions for variables used in the Terraform deployment.
- ``` outputs.tf ``` This file contains definitions for outputs from the Terraform deployment.
- ``` variables.tfvars ``` This file contains definitions in the format ```variable_name=example``` of variables to be used in the deployment. This file is for local deployments and should NOT be committed to a repository as it may contain passwords, credentials, or other sensitive information.

## Environment Setup

- API Management Service with a Premium SKU
- App Service hosting a sample api, [httpbin](httpbin.org)
- Application Insights for monitoring APIM and App Service
- Azure Load Test

## Benchmarking tests

Three tests are run the deployment workflow using a [JMeter script](/src/load-test-configs/quick_test.jmx) and [config files](/src/load-test-configs/). You can use any JMeter script you already have, but for the purposes of this example, the JMeter script was generated through Azure Load Testing Quick Test. When we perform system testing, we need to look at functional and performance. The CI/CD implementation is intended to demonstrate that anytime you make a change to your environment with APIM, you need to re-run basic load tests as you would unit tests to determine if that change had any effect on your environment's performance. For the purposes of this example, we have demonstrated three basic load tests each run with 500 requests per second (RPS).

1. 500 byte payload
2. 1,000 byte payload
3. 1,500 byte payload

These cases are meant to be a basic example of how you would want to configure your environment setup. Your use cases will differ based on number of users, throughput and other factors. 

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

## GitHub Action Secrets Required

Create the following secrets in your GitHub repository:

- ``` AZURE_TENANT_ID ```
- ``` AZURE_SUBSCRIPTION_ID ```
- ``` AZURE_CLIENT_ID ```
- ```PUBLISHER_EMAIL``` (Email for setting up APIM instance)
  
## GitHub Action Variables Required

- ``` STATE_STORE_RGNAME ``` Existing resource group or name of one to be created for your remote state storage account
- ``` STORAGE_ACCOUNT_NAME ``` Existing storage account or name of one to be created for your Terraform remote state to be stored
- ``` STATE_STORAGE_CONTAINER_NAME ``` Existing container name or name of one to be created for your Terraform remote state to be stored
- ``` STATE_STORE_FILENAME ``` Existing filename or new filename for your Terraform state file
- ``` DESTROY_TERRAFORM ``` True or False. Whether you want to destroy the Terraform architecture after it's been created through the workflow.
- ``` LOCATION ``` Location where you want the Azure resources and Terraform state storage to be deployed.

## Development Process

- Create a feature/fix branch in your repository 
- When you create a pull request, it will trigger the validate workflow to check your Terraform syntax and format it.
- Once the validate workflow has completed successfully, you can merge in your changes
- Once the changes are merged in, it will trigger the build and deploy workflow to test deploying the architecture.
