// Bot name has to be unique (services account and dns names will be determined by this setting)
variable "bot_name" {
}

// Creation of AAD Application and Service Principal has to be done apriori
variable "microsoft_app_id" {
}

variable "microsoft_app_secret" {
}

variable "azure_bot_regions" {
  type = list
  default = [ 
    { 
      name = "southeastasia"
      priority = 0 // For CosmosDB MultiMaster, bot regions will be selected by traffic manager
    }, 
    { 
      name = "koreacentral"
      priority = 1 // For CosmosDB MultiMaster, bot regions will be selected by traffic manager
    }
    ]
}

// "Global Region" - Management Region for Global Services
variable "global_region" {
  default = "japaneast"
}

variable "environment" {
  default = "geobotpoc"
}

variable "bot_sku" {
  default = "S1"
}