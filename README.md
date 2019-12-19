# Azure Bot Framework based Geo Distributed Bot with failover capability 

## EXPLAIN WHY THIS IS NEEDED
## INCLUDE HIGH LEVEL ARCHITECTURE

## INCLUDE OPEN POINTS
## INCLUDE NEXT STEPS

## Tasks and order of execution

Prerequisites for all tasks:
- PowerShell Core >6.2.3
- Terraform >0.12.17
- Azure CLI >2.0.71
- Be logged into Azure CLI and having Subscription Level Owner or Contributor rights on the "isDefault" marked subscription

1. Creation of AAD AppId and Secret (All AAD Tenants and Microsoft Personal Accounts) including a Service Principal (Enterprise App)
2. Issuing a SSL certificate for the <yourbotname>.trafficmanager.net domain
3. Deploying the Infrastructure & Sample Bot
4. Testing Bot and Failover
5. Destroying the Infrastructure

---

1. Creation of AAD AppId

```pwsh

```

2. Issuing a SSL Certificate

You can use the script provided [here](LetsEncrypt\Archive\). Searching another/better pattern to do it.

For testing/demoing `Let's Encrypt` is a good way but it has rate limitations (top level domain 50 per week).
So use it wisely and try to reuse the SSL certificate. For `Production` environments we strongly recommend a Custom Domain Name and to use certificate issuing via [AppServices](https://docs.microsoft.com/en-us/azure/app-service/configure-ssl-certificate) or your preferred CA (Certificate Authority).

For testing/demoing - 
__The BotName has to be unique since several Azure services will use it as prefix. Stick to lowercase no dashes and special chars and less than 20char. e.g. myfirstname1234__

__due to a bug in the current setup a complex password with special characters may not work as expected__
```pwsh
cd LetsEncrypt\Archive

az group create -name rg-geobot-global -location japaneast

.\IssueSSLCertificate.ps1 -YOUR_CERTIFICATE_EMAIL <YOUR_EMAIL> -YOUR_DOMAIN <BOT_NAME>.trafficmanager.net -BOT_NAME <BOT_NAME> -PFX_EXPORT_PASSWORD <PFX_EXPORT_PASSWORD>
```

3. Deploy the Solution

__The BotName has to be the same as in Step 2.__

__The PFX password has to be the same as in Step 2.__
```pwsh
cd ..\..\Deploy

.\OneClickDeploy.ps1 -BOT_NAME <bot> -MICROSOFT_APP_ID <appid> -MICROSOFT_APP_SECRET <appsecret> -PFX_FILE_LOCATION ..\LetsEncrypt\Archive\letsencrypt.pfx -PFX_FILE_PASSWORD <pfxpassword>
```

4. Testing Bot and Failover

Grab your Directline key from the [Bot Channel Registration pane](https://docs.microsoft.com/en-us/azure/bot-service/bot-service-channel-connect-directline?view=azure-bot-service-4.0). 

Use the provided Test Webchat static [index.html](WebChat\index.html) and paste following query arguments
`?bot=<BOT_NAME>&key=<DIRECT_LINE_KEY>`

Break something (removing LUIS Endpoint Key in luis.ai, Stop the WebApp your bot responds from)

5. Destroying everything

```pwsh
.\OneClickDestroy.ps1 -BOT_NAME <bot> -MICROSOFT_APP_ID <appid> -MICROSOFT_APP_SECRET <appsecret> -PFX_FILE_LOCATION ..\LetsEncrypt\Archive\letsencrypt.pfx -PFX_FILE_PASSWORD <pfxpassword>
```