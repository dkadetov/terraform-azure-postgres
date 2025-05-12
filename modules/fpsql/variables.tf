variable "name_prefix" {
  description = "Prefix for naming PostgreSQL resources."
  type        = string
}

variable "location" {
  description = "Azure location where resources will be deployed."
  type        = string
}

variable "resource_group" {
  description = "Name of the Azure resource group where resources will be created."
  type        = string
}

variable "aad_admin" {
  description = "Object defining Azure Active Directory administrator settings for PostgreSQL server."

  type    = list(string)
  default = []
}

variable "aad_auth" {
  description = "Flag enabling Azure Active Directory authentication."

  type    = bool
  default = true
}

variable "password_auth" {
  description = "Flag enabling password authentication."

  type    = bool
  default = true
}

variable "key_vault" {
  description = "Object with Key Vault settings for storing PostgreSQL secrets."

  type = object({
    name                    = optional(string)
    resource_group          = optional(string)
    secrets_create          = optional(bool, true)
    secrets_expiration_date = optional(string, "2028-10-04T00:00:00Z")
  })
  default = {}
}

variable "administrator_login" {
  description = "Administrator username for PostgreSQL server."

  type    = string
  default = "fpsqladmin"
}

variable "administrator_password" {
  description = "Administrator password for PostgreSQL server."

  type      = string
  default   = null
  nullable  = true
  sensitive = true
}

variable "postgresql_version" {
  description = "PostgreSQL server version."

  type    = string
  default = "14"
}

variable "postgresql_create_mode" {
  description = "PostgreSQL server creation mode (Default, PointInTimeRestore, GeoRestore)."

  type    = string
  default = "Default"
}

variable "postgresql_source_id" {
  description = "Source server ID for PostgreSQL server restoration."

  type     = string
  default  = null
  nullable = true
}

variable "sku_name" {
  description = "SKU name for PostgreSQL server, defining computing resources."

  type    = string
  default = "GP_Standard_D2ds_v5"
}

variable "storage_mb" {
  description = "PostgreSQL storage size in megabytes."

  type    = number
  default = 262144
}

variable "storage_tier" {
  description = "PostgreSQL storage tier."

  type    = string
  default = "P15"
}

variable "storage_retention_days" {
  description = "Number of days for backup retention."

  type    = number
  default = 14
}

variable "storage_geo_redundant_backup" {
  description = "Flag enabling geo-redundant backup."

  type    = bool
  default = true
}

variable "auto_grow_enabled" {
  description = "Flag enabling automatic storage growth."

  type    = bool
  default = true
}

variable "zone" {
  description = "Azure availability zone for PostgreSQL server."

  type     = string
  default  = null
  nullable = true
}

variable "high_availability_mode" {
  description = "High availability mode for PostgreSQL server."

  type    = string
  default = "Disabled"
  validation {
    condition     = contains(["Disabled", "SameZone", "ZoneRedundant"], var.high_availability_mode)
    error_message = "The only supported values for `high_availability_mode` are: Disabled, SameZone, ZoneRedundant"
  }
}

variable "public_network_access_enabled" {
  description = "Flag allowing public network access to PostgreSQL server."

  type    = bool
  default = true
}

variable "fpsql_firewall_rules" {
  description = "List of firewall rules for PostgreSQL server."

  type = list(object({
    name     = string
    start_ip = string
    end_ip   = string
  }))
  default = []
}

variable "fpsql_server_network" {
  description = "Object with network settings for PostgreSQL server."

  type = object({
    private_dns_zone_create         = optional(bool, true)
    private_dns_zone_name           = optional(string, "privatelink.postgres.database.azure.com")
    private_dns_zone_resource_group = optional(string)
    private_endpoint_create         = optional(bool, true)
    private_endpoint_location       = optional(string)
    private_endpoint_resource_group = optional(string)
    vnet_name                       = optional(string)
    vnet_resource_group             = optional(string)
    subnet_create                   = optional(bool, false)
    subnet_id                       = optional(string)
    subnet_address_prefixes         = optional(list(string), ["10.3.255.0/29"])
    subnet_service_endpoints        = optional(list(string), ["Microsoft.Storage"])
    subnet_policies_enabled         = optional(bool, true)
  })
  default = {}

  validation {
    condition     = var.fpsql_server_network.private_dns_zone_create || var.fpsql_server_network.subnet_create ? var.fpsql_server_network.vnet_name != null : true
    error_message = "The value of fpsql_server_network.vnet_name is missing. You need to specify the correct value."
  }

  validation {
    condition     = var.fpsql_server_network.private_endpoint_create ? var.fpsql_server_network.subnet_id != null : true
    error_message = "The value of fpsql_server_network.subnet_id is missing. You need to specify the correct value."
  }
}

variable "fpsql_server_configuration" {
  description = "Map of PostgreSQL server configuration parameters."

  type    = map(string)
  default = {
    "logfiles.download_enable"              = "ON"
    "logfiles.retention_days"               = "7"
    "azure.extensions"                      = "PG_CRON,PG_STAT_STATEMENTS,PGCRYPTO,UUID-OSSP,PG_BUFFERCACHE"
    shared_preload_libraries                = "pg_cron,pg_stat_statements"
    wal_level                               = "LOGICAL"
    max_wal_senders                         = "50"
    max_replication_slots                   = "25"
    track_io_timing                         = "ON"
    "pg_qs.query_capture_mode"              = "ALL"
    "pgms_wait_sampling.query_capture_mode" = "ALL"
  }
}

variable "fpsql_extra_server_configuration" {
  description = "Additional PostgreSQL server configuration parameters."

  type    = map(string)
  default = {}
}

variable "fpsql_server_diagnostic" {
  description = "PostgreSQL server diagnostic settings."

  type = object({
    enable                     = optional(bool, false)
    name                       = optional(string, "fpsql-diagnostic-settings")
    log_analytics_workspace_id = optional(string)
    metric_enable              = optional(bool, false)
    log_categories             = optional(list(string), [
      "PostgreSQLFlexSessions",
      "PostgreSQLFlexQueryStoreRuntime",
      "PostgreSQLFlexQueryStoreWaitStats",
    ])
  })
  default = {}

  validation {
    condition     = var.fpsql_server_diagnostic.enable ? var.fpsql_server_diagnostic.log_analytics_workspace_id != null : true
    error_message = "The value of fpsql_server_diagnostic.log_analytics_workspace_id is missing. You need to specify the correct value."
  }
}

variable "action_group_id" {
  description = "Action group ID for alerts."

  type     = string
  default  = null
  nullable = true

  validation {
    condition     = var.fpsql_storage_alert.create || var.fpsql_lag_alert.create ? var.action_group_id != null : true
    error_message = "The value of action_group_id is missing. You need to specify the correct value."
  }
}

variable "fpsql_storage_alert" {
  description = "Settings for PostgreSQL storage usage alerts."

  type = object({
    create      = optional(bool, false)
    enable      = optional(bool, true)
    threshold   = optional(number, 0.90)
    frequency   = optional(string, "PT15M")
    window_size = optional(string, "PT30M")
  })
  default = {}
}

variable "fpsql_lag_alert" {
  description = "Settings for PostgreSQL replication lag alerts."

  type = object({
    create      = optional(bool, false)
    enable      = optional(bool, true)
    severity    = optional(number, 2)
    sensitivity = optional(string, "Low")
    frequency   = optional(string, "PT30M")
    window_size = optional(string, "PT1H")
  })
  default = {}
}
