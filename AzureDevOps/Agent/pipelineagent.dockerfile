FROM ubuntu:16.04

# CREATE and SET WORKDIR
RUN mkdir /prep
WORKDIR /prep

# Update the list of products
RUN apt-get update

# Install wget
RUN apt-get -y install wget

# Install nslookup
RUN apt-get -y install dnsutils

# Prerequisite for several installations
RUN apt-get -y install apt-transport-https

# Install PowerShell Core
RUN wget -q https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb
RUN apt-get update
RUN apt-get -y install powershell

# Install cURL
RUN apt-get -y install curl

# Install Azure CLI with one command
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash -

# Install Terraform 
RUN wget -q https://releases.hashicorp.com/terraform/0.12.18/terraform_0.12.18_linux_amd64.zip
RUN apt-get -y install unzip
RUN unzip terraform_0.12.18_linux_amd64.zip
RUN mv terraform /usr/local/bin

# Install .NET Core SDK
RUN apt-get -y install dotnet-sdk-3.1

# Install NodeJS
RUN curl -sL https://deb.nodesource.com/setup_13.x | bash -
RUN apt-get -y install nodejs

# Install LUIS CLI
RUN npm install -g luis-apis

# Last Update & upgrade
RUN apt-get -y update
RUN apt-get -y upgrade

# SET WORKDIR & REMOVE PREP folder
WORKDIR /
RUN rm /prep -r