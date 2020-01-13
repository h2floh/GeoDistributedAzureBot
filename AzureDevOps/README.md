# Azure DevOps Pipelines

Currently the repo has 4 pipelines (all in YAML format) for development checks. These pipelines are not intended to be used as CI/CD pipelines in real Bot projects. Their main purpose is to _verify_ the OneClick Deployment and Destroy scripts working if executed stand alone and to build the docker images needed in order to do so ('Container Agent' & 'KeyVault store enabled Certbot').

**Sample Pipelines for real CI/CD are on the TODO list!**

## Container Agent Build

[![Build Status Pipeline Agent Image](https://dev.azure.com/h2floh/GeoDistributedAzureBot/_apis/build/status/GeoDistributedAzureBot-PipelineAgent?branchName=master&label=Pipeline%20Agent)](https://dev.azure.com/h2floh/GeoDistributedAzureBot/_build/latest?definitionId=7)

Builds the docker image used as agent to execute the `OneClick` scripts. Get's activated by PR including folder `AzureDevOps/Agent` and on changes on master. Pushes to repo to Docker Hub only from the master branch. Regularly scheduled weekly and daily if sources changed on `master`.

## KeyVault store enabled Certbot

[![Build Status KeyVault CertBot Image](https://dev.azure.com/h2floh/GeoDistributedAzureBot/_apis/build/status/GeoDistributedAzureBot-KeyVaultCertBot?branchName=master&label=KeyVault%20CertBot)](https://dev.azure.com/h2floh/GeoDistributedAzureBot/_build/latest?definitionId=8)

Builds the docker image used within `CreateSSL.ps1` script to issue a new Let's Encrypt certificate. Get's activated by PR including folder `SSL/Docker` and on changes on master. Pushes to repo to Docker Hub only from the master branch. Regularly scheduled on Sunday and on change of sources. Regularly scheduled weekly and daily if sources changed on `master`.

## GeoBot Build

[![Build Status Sample GeoBot](https://dev.azure.com/h2floh/GeoDistributedAzureBot/_apis/build/status/GeoDistributedAzureBot-Bot?branchName=master&label=Build%20GeoBot)](https://dev.azure.com/h2floh/GeoDistributedAzureBot/_build/latest?definitionId=5)

Builds the .NET Core Bot solution. Get's activated by PR including folder `GeoBot`. Regularly scheduled weekly and daily if sources changed on `master`.

## OneClick Deployment Test

[![Test OneClickDeploy](https://dev.azure.com/h2floh/GeoDistributedAzureBot/_apis/build/status/GeoDistributedAzureBot-Deploy?branchName=master&label=Test%20OneClickDeploy)](https://dev.azure.com/h2floh/GeoDistributedAzureBot/_build/latest?definitionId=6)

> :warning: This pipeline's purpose is to test the standalone execution of `OneClick` scripts. It does not use a remote state store for Terraform and can therefore not be used for CI/CD pipelines where the environment is not meant to been destroyed again.

Uses a [container build agent](#-Container-Agent-Build) to execute the pipeline. Due to DNS errors (see [this issue](#22)) on hosted build agents it is using a custom Ubuntu 19 build agent with docker installed.

Testing the execution of the `OneClick` scripts. Get's activated by PR including folder `Deploy`. Regularly scheduled weekly and daily if sources changed on `master`.

Needs four Variables from a Variable Group called `SubscriptionDetails`

- ServicePrincipalID (Client/App ID)
- ServicePrincipalSecret (Client Secret)
- TenantId (AAD Id)
- SubscriptionId (Azure Subscription)

The service principal will need following IAM roles on the subscription level:

- Contributor
- Key Vault Contributor
