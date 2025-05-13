variable "subscription_id" {
  description = "Azure subscription ID where resources will be deployed."

  type = string
}

variable "resource_group" {
  description = "Azure Resource Group configuration where PostgreSQL Flexible Server and related resources will be deployed, containing name and region/location properties."

  type = object({
    name     = string
    location = string
  })
}

variable "key_vault" {
  description = "Azure Key Vault configuration for storing PostgreSQL secrets."

  type = object({
    name           = string
    resource_group = string
  })
}

variable "fpsql_conf" {
  description = "Configuration object for PostgreSQL Flexible Server."

  type = object({
    name_prefix            = string
    sku_name               = string
    storage_mb             = number
    storage_tier           = string
    storage_retention_days = number
    aad_auth               = bool
    aad_admin              = list(string)
    administrator_login    = string
    private_dns_zone_name  = string
    vnet_name              = string
    vnet_resource_group    = string
  })
}

variable "administrator_password" {
  description = "Enter the password for the database. Make sure it meets the security requirements."

  type      = string
  sensitive = true
}

variable "postgresql_aad_administrator_password" {
  description = "Microsoft Entra ID token."

  type      = string
  sensitive = true
}

variable "fpsql_pip" {
  description = "Public IP configuration for PostgreSQL Flexible Server."

  type = object({
    name                = string
    location            = string
    resource_group_name = string
    domain_name_label   = string
    sku                 = string
  })
}

variable "fpsql_svc" {
  description = "Kubernetes service configuration for PostgreSQL Flexible Server."

  type = object({
    name      = string
    namespace = string
    port      = number
  })
}
