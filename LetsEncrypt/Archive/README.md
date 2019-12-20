# CAUTION: IMMEDIATE DANGER - ONLY FOR USE OVER 18 YEARS AND WITHOUT ANY WARRANTY OR WHATSOEVER

## This is a dirty workaround to export a Let's Encrypt certificate in pfx format to your client

It contains some interesting workarounds how to extract a file from ACI which is not officially supported but a bad hack.

I convert the private and public key to a PFX file, then I transform them to BASE64 for reading on the console. 

This console output is redirected to a file via ACI Azure CLI exec command. Because this was not designed to transport files (binary didn't work) you will see a lot of additional newlines. These are removed and encoded back to bytes and finally saved in a local file.

I tested this approach and while it is working fine (also for Custom DNS Name if you create a CNAME to your Traffic Manager DNS) I do not recommend it for following reasons:

- No control flow for timing of certbot and copy action, I just hope that everything is completed on the container side within 60 seconds
- Bad Hack to get the file back to the client (but maybe interesting in some ACI troubleshooting hacks, that is why I save this work here)
- Overall maybe a not so ideal solution from a security perspective to save the SSL certificate locally and chain it back to the Terraform script.

I will come up with a better more reproducible solution. But until then:

```bash
cd LetsEncrypt\Archive

az group create -name rg-geobot-global -location japaneast

.\IssueSSLCertificate.ps1 -YOUR_CERTIFICATE_EMAIL <YOUR_EMAIL> -YOUR_DOMAIN <BOT_NAME>.trafficmanager.net -BOT_NAME <BOT_NAME> -PFX_EXPORT_PASSWORD <PFX_EXPORT_PASSWORD>
```

Known issues/drawbacks/things to be reminded of for this script:

- __the BotName has to be unique__ since several Azure services will use it as prefix. Stick to lowercase no dashes and special chars and less than 20char. e.g. **myfirstname1234**
- due to a bug in the current setup a complex password with special characters **may not work** as expected
- the Terraform script in [Step 3](#3-deploy-the-solution) was created before realizing the need of creating a trusted SSL certificate, we will already deploy the TrafficManager in this step. In order to match with the default values of the current Terraform script, the resource group `rg-geobot-global` and location `japaneast` are correct. If you modify these values of the Terraform script either delete it (the resource group) after Step 2 before running Step 3 or match the values accordingly
