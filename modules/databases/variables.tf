variable "key_vault" {
  description = "Azure Key Vault configuration for storing database secrets."

  type = object({
    name                    = optional(string)
    resource_group          = optional(string)
    secrets_create          = optional(bool, true)
    secrets_name_prefix     = optional(string, "")
    secrets_expiration_date = optional(string, "2028-10-04T00:00:00Z")
  })
  default = {}

  validation {
    condition     = var.key_vault.secrets_create ? var.key_vault.name != null : true
    error_message = "The value of key_vault.name is missing. You need to specify the correct value."
  }

  validation {
    condition     = var.key_vault.secrets_create ? var.key_vault.resource_group != null : true
    error_message = "The value of key_vault.resource_group is missing. You need to specify the correct value."
  }
}

variable "administrator_login" {
  description = "PostgreSQL server administrator username."
  type        = string
}

variable "administrator_password" {
  description = "PostgreSQL server administrator password."
  type        = string
}

variable "tenants" {
  description = "List of tenants with settings for database and role creation."

  type = list(object({
    name          = string
    db_suffix     = optional(string, "")
    db_admin_role = optional(bool, true)
  }))
  default = []
}

variable "dedicated_databases" {
  description = "List of all dedicated databases without suffixes. The tenant db_suffix will be used as a suffix for each database in this list."

  type    = list(string)
  default = []
}

variable "shared_databases" {
  description = "Map of all shared databases (shared between tenants) without suffixes. The map key is used as a suffix."

  type    = map(list(string))
  default = {}
}

variable "extra_databases" {
  description = "List of full names of all extra databases."

  type    = list(string)
  default = []
}

variable "postgresql_inherited_roles" {
  description = "Map of PostgreSQL roles with inherited privileges from other roles."

  type    = map(list(string))
  default = {}
}

variable "postgresql_extra_roles" {
  description = "Map of additional PostgreSQL roles with detailed privilege configuration."

  type = map(object({
    superuser       = optional(bool, false)
    create_database = optional(bool, false)
    create_role     = optional(bool, false)
    inherit         = optional(bool, true)
    login           = optional(bool, true)
    replication     = optional(bool, false)
    roles           = optional(list(string), [])
    privileges      = map(list(object({
      schema      = optional(string, "public")
      object_type = optional(string, "table")
      objects     = optional(list(string), [])
      privileges  = optional(list(string), ["SELECT"])
    })))
  }))
  default = {}
}

variable "postgresql_aad_roles" {
  description = "Map of Azure Active Directory roles for PostgreSQL with privilege settings."

  type = map(object({
    role_name   = optional(string, "")
    grant_roles = optional(list(string), [])
    is_admin    = optional(bool, false)
    is_mfa      = optional(bool, true)
    privileges  = map(list(object({
      schema      = optional(string, "public")
      object_type = optional(string, "table")
      objects     = optional(list(string), [])
      privileges  = optional(list(string), ["SELECT"])
    })))
  }))
  default = {}
}

variable "postgresql_aad_role_mapping" {
  description = "Map of PostgreSQL role mappings to Azure AD objects."

  type = map(object({
    role_name   = optional(string, "")
    object_id   = string
    object_type = string
  }))
  default = {}
}

variable "postgresql_aad_administrator_login" {
  description = "Azure AD administrator username for PostgreSQL."

  type     = string
  default  = null
  nullable = true

  validation {
    condition     = length(var.postgresql_aad_roles) > 0 ? var.postgresql_aad_administrator_login != null : true
    error_message = "The value of postgresql_aad_administrator_login is missing. You need to specify the correct value."
  }
}

variable "postgresql_server_host" {
  description = "PostgreSQL server hostname for Azure AD connection."

  type     = string
  default  = null
  nullable = true

  validation {
    condition     = length(var.postgresql_aad_roles) > 0 ? var.postgresql_server_host != null : true
    error_message = "The value of postgresql_server_host is missing. You need to specify the correct value."
  }
}
