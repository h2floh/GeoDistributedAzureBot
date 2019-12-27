# Azure Bot Framework based Geo Distributed Bot with failover capability

This repo contains deployment scripts and a sample bot to spin up a geo distributed and geo failover capable bot, which can be accessed like any other Azure Bot Framework Service based bot via the Bot Framework Service Channels (Directline/WebChat and may more).

The idea of this repo is to give you a full working starting point for a Azure Cloud Native architecture pattern from where you can customize it for your Bot and your needs.

This repo focuses on the surrounding architectural aspects rather than to have a good conversational AI experience.

Things you can learn about (most are Bot unrelated):

- **Centralized and secure** configuration of services
- Simple but powerful **Auto-Failover** capabilities by cloud architecture design
- **Advanced Terraform** functionalities like __for_each__ and __dynamic__
- Fully **automated LUIS deployment** for CI/CD pipelines
- Automated Let's encrypt certification issuing

## Why should I care?

Most bot projects focusing on the user experience and natural language processing and other AI capabilities of the bot.
But as this bot becomes a main core service of your organization it will be critical that you can provide a **globally spanning bot service** and have a **integrated failover/always-on architecture** or strategy even in the (unlikely) downtime of a whole Azure region.

Since there is limited guidance on how to create such an architecture we started creating this repo as an idea book.

## The big picture

We don't claim that this is the only valid architecture. There are a lot of ways to build this and to customize and improve from this base architecture on.

![The used architecture](Doc/img/architecture.png)

### Architecture explanation

Your client apps or channels (Teams, Slack, Facebook Messenger) connect via the Azure Bot Frameworks Server (BFS), a already globally distributed service, to your bot. We configure BFS to use a Traffic Manager endpoint with 'Performance' mode. So Traffic Manager will lookup the bot which is nearest to the current connected BFS instance, which should be the same as the nearest to the client/user. TrafficManager is also capable of doing a healthcheck on the registered endpoints, which allows the regional failover by design.

Doing this comes actually with a price, BFS by design requires the Bot endpoint to have a valid trust chain SSL certificate in place, so we can not just create a self-signed SSL for a test run or demo.

In order to easily deploy the bot (and to be able to create a lean CI/CD pipeline), the bot(s) will reference a central configuration store, KeyVault to retrieve all configuration. The bot will be deployed as a .NET Core application into WebApps (on App Service).

For each region where we deploy a bot we also use the LUIS service in the same region to get a good latency. For storing the state of the conversations we are using CosmosDB in MultiMaster mode, so that even in case of failover the conversation can continue from the point where it was.

To ease out additional complexity overhead we introduced a healthcheck API within the bot which checks for availability of LUIS and CosmosDB. In case of one failure of one component the whole region will be failed-over which is maybe a bit harsh. You can extend each individual service to provide more regional failover and high availability, but as introduced we have to draw a line somewhere.

We are not using any other global or reginal services but for a better visualization they are displayed in the architecture picture.

### Design decisions

- Using TrafficManager with Performance profile in order to "dispatch" to the nearest available region/bot.
- Using KeyVault as central configuration store even for non-secret config (App Configuration Services can be used also but is still in preview and to keep the amount of services low)
- Using MultiMaster CosmosDB as state store, maybe you won't need a global MultiMaster CosmosDB, maybe for a bigger geographical region like North America or Europe separate CosmosDB MultiMaster clusters would be just fine.
- Placing all global services (management pane - Traffic Manager, Bot Registration) into a separate Azure region
- Putting the Healthcheck API within the bot (to reduce complexity/additional code and services)

## Try it yourself

Please report any problems you face under issues!

### Prerequisites for all tasks

- PowerShell Core >6.2.3
- Terraform >0.12.17
- Azure CLI >2.0.71
- Be logged into Azure CLI and having Subscription Level Owner or Contributor rights on the "isDefault" marked subscription

### Summary of steps

1. Creation of AAD AppId and Secret (Bot Framework requires the App to be available for AAD all tenants)
2. Issuing a SSL certificate for the `yourbotname`.trafficmanager.net domain, or your custom domain (WIP)
3. Deploying the Infrastructure & Sample Bot
4. Testing Bot and Failover
5. Destroying the Infrastructure
6. Deploy it again

### 1. Creation of AAD AppId

Your bot will need a AAD Application registered as a prerequisite for Bot Framework.

```bash
# Create AAD application
az ad app create --display-name <YourBotName> --available-to-other-tenants --reply-urls 'https://token.botframework.com/.auth/web/redirect'

# Retrieve Application Id
$appId=$(az ad app list --display-name <YourBotName> --query '[0].appId' -o tsv)

# Create Application Password
$appPassword=$(az ad app credential reset --id $appId --query 'password' -o tsv)

# Echo AppId and Password/Secret
echo "Your Bot's`nApp ID: $appId`nSecret: $appPassword"
```

### 2. Issuing a SSL Certificate

You can use the script provided [here](LetsEncrypt\Archive). Searching another/better pattern to do it.

For testing/demoing `Let's Encrypt` is a good way but it has rate limitations (top level domain 50 per week more info [here](https://letsencrypt.org/docs/rate-limits/)).

So use it wisely and try to reuse the SSL certificate. Even this architecture is capable of handling and be easily scaled out for production environments we strongly recommend a Custom Domain Name and to use certificate issuing via [AppServices](https://docs.microsoft.com/en-us/azure/app-service/configure-ssl-certificate) or your preferred CA (Certificate Authority).

Known issues/drawbacks:

- __the BotName has to be unique__ since several Azure services will use it as prefix. Stick to lowercase no dashes and special chars and less than 20char. e.g. **myfirstname1234**
- due to a bug in the current setup a complex password with special characters **may not work** as expected
- the Terraform script in [Step 3](#3-deploy-the-solution) was created before realizing the need of creating a trusted SSL certificate, we will already deploy the TrafficManager in this step. In order to match with the default values of the current Terraform script, the resource group `rg-geobot-global` and location `japaneast` are correct. If you modify these values of the Terraform script either delete it (the resource group) after Step 2 before running Step 3 or match the values accordingly

```bash
cd LetsEncrypt\Archive

az group create -name rg-geobot-global -location japaneast

.\IssueSSLCertificate.ps1 -YOUR_CERTIFICATE_EMAIL <YOUR_EMAIL> -YOUR_DOMAIN <BOT_NAME>.trafficmanager.net -BOT_NAME <BOT_NAME> -PFX_EXPORT_PASSWORD <PFX_EXPORT_PASSWORD>
```

### 3. Deploy the Solution

The solution will deploy to three Azure regions:

- Global/central artifacts: __japaneast__
- Bot: __koreacentral__ and __southeastasia__

You can easily expand the amount of regions by adding regions to the terraform variable [file](Deploy/IaC/variables.tf).
The only requirement is that in that region both LUIS and AppService are available.

Things to keep in mind:

- __The BotName has to be the same as in Step 2.__
- __The PFX password has to be the same as in Step 2.__
```bash
cd ..\..\Deploy

.\OneClickDeploy.ps1 -BOT_NAME <bot> -MICROSOFT_APP_ID <appid> -MICROSOFT_APP_SECRET <appsecret> -PFX_FILE_LOCATION ..\LetsEncrypt\Archive\letsencrypt.pfx -PFX_FILE_PASSWORD <pfxpassword>
```

### 4. Testing Bot and Failover

Grab your Directline key from the [Bot Channel Registration pane](https://docs.microsoft.com/en-us/azure/bot-service/bot-service-channel-connect-directline?view=azure-bot-service-4.0). 

Use the provided Test Webchat static [index.html](WebChat\index.html) and paste following query arguments
`?bot=<BOT_NAME>&key=<DIRECT_LINE_KEY>`

Break something (removing LUIS Endpoint Key in luis.ai, Stop the WebApp your bot responds from)

### 5. Destroying everything

There are currently 2 dependency issues between how Azure works and how Terraform resolves dependencies while destroying an environment. In order to get a clean destroy we need to delete first the TrafficManager and the KeyVault and then going through the Terraform destroy phase. For Terraform, it needs the same parameters as in the __apply__ step, that is why you have to provide these details again.

```bash
.\OneClickDestroy.ps1 -BOT_NAME <bot> -MICROSOFT_APP_ID <appid> -MICROSOFT_APP_SECRET <appsecret> -PFX_FILE_LOCATION ..\LetsEncrypt\Archive\letsencrypt.pfx -PFX_FILE_PASSWORD <pfxpassword>
```

__Remark: the AAD Application does not get deleted__

### 6. Deploying again

Please reuse your AppID/Password and the Let's Encrypt certificate (it is valid for 3 months). So just skip [Step 1](#1-creation-of-aad-appid) and [Step 2](#2-issuing-a-ssl-certificate).

## Learnings

There is no __one fits it all__ Infrastructure as Code tool

- While Terraform is good for the loop over each region, it is not very good in multi step scenarios including waiting for a resource/artifact to be created
- Terraform also is less optimal if you want to introduce architecture choices
- For waiting I used script loops together with Azure CLI commands
- Terraform AzureRM provider still lacks some update features. E.g. there is a need to update only the Bot's endpoint in a subsequent Terraform execution, but this is not possible because there is no data source for Bot, so we would have to keep track of all parameters. In such cases we used Azure CLI for updating.
- Terraform is very convenient if you want to destroy the environment again (demos, non frequent reoccurring tasks)

## Open points and next steps

Listing up various things from different domain/view angles:

- Refactoring Deployment process to better include reuse of created SSL certificates and custom domain names, improve security aspects (no local download of PFX file) and some issues with resource naming in the current version
- Extend Bot with Geo distributed Speech service
- Include scripts to simulate different type of failures
- Create a containerized version where AppService will be replaced with Azure Kubernetes Service or Azure Container Instances
- Create a version where LUIS and Speech service runs on the same AKS as the bot