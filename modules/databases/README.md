# Databases Terraform module

> **Disclaimer**: This README was generated with the assistance of an AI agent and may contain inaccuracies or errors. Please review and validate the information before implementation.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Providers](#providers)
- [Usage](#usage)
  - [Provider Configuration](#provider-configuration)
  - [Module Configuration](#module-configuration)
  - [Database Types](#database-types)
  - [Role Management](#role-management)
- [Inputs](#inputs)
- [Outputs](#outputs)
- [Examples](#examples)
  - [Main Configuration Example](#maintf-example)
  - [Variables Example](#variablestf-example)
- [Troubleshooting](#troubleshooting)
- [Changelog](#changelog)

## Overview

This Terraform module manages PostgreSQL resources in Azure environments, including database creation, role management, and privilege assignment. It supports both standard PostgreSQL authentication and Azure Active Directory (AAD) integration.

## Features

Creates PostgreSQL resources for infrastructure:
- **Database Management**:
  - Dedicated databases (specific to tenants with customizable suffixes)
  - Shared databases (shared between tenants)
  - Extra databases (standalone databases)
- **Role Management**:
  - Tenant-specific roles
  - Generic reader roles for different database groups
  - Advanced roles with detailed privilege configuration
  - Inherited roles with privilege inheritance
  - Azure AD integrated roles with MFA support
- **Security**:
  - Automatic password generation with secure parameters
  - Key Vault integration for storing credentials
  - Fine-grained privilege control at schema/table/object level
  - Azure AD authentication and authorization
- **Multi-tenant Support**:
  - Database and role segregation based on tenants
  - Customizable database naming with tenant suffixes

## Requirements

| Name       | Version   |
|------------|-----------|
| terraform  | >= 1.9.0  |
| azuread    | ~> 3.3.0  |
| azurerm    | ~> 4.27.0 |
| postgresql | ~> 1.25.0 |
| random     | ~> 3.7.2  |

## Usage

This module requires two PostgreSQL providers to be configured:

### Provider Configuration

This module requires two PostgreSQL providers:
- `postgresql.main` - Used for standard PostgreSQL operations
- `postgresql.aad` - Used for Azure AD integration with PostgreSQL

Both providers should be configured with appropriate parameters for connecting to your PostgreSQL server, including host, port, SSL mode, credentials, and connection parameters.

### Module Configuration

The module accepts configuration for:
1. Key Vault integration for storing secrets
2. Tenant configurations with custom database suffixes
3. Database definitions (dedicated, shared, and extra)
4. Various role types with different privileges

### Database Types

- **Dedicated Databases**: Created for each tenant with tenant's suffix. For example, with `dedicated_databases = ["main", "audit"]` and tenant suffix _`alpha`, databases `main_alpha` and `audit_alpha` will be created.

- **Shared Databases**: Shared between tenants with custom suffixes. For example, with shared databases named `foo` and `bar` using suffix `shared`, databases `foo_shared` and `bar_shared` will be created.

- **Extra Databases**: Standalone databases with exact names as specified, with no additional suffixes.

### Role Management

- **Regular Roles**: Create standard PostgreSQL roles with privileges
- **AAD Roles**: Integrate with Azure AD for authentication and authorization
- **Inherited Roles**: Create roles that inherit privileges from other roles

See the [Examples](#examples) section for detailed usage.

## Inputs

| Name                               | Description                                                                                                                     | Type                | Default |
|------------------------------------|---------------------------------------------------------------------------------------------------------------------------------|---------------------|:-------:|
| administrator_login                | PostgreSQL server administrator username.                                                                                       | `string`            |    —    |
| administrator_password             | PostgreSQL server administrator password.                                                                                       | `string`            |    —    |
| key_vault                          | Azure Key Vault configuration for storing database secrets.                                                                     | `object`            |  `{}`   |
| tenants                            | List of tenants with settings for database and role creation.                                                                   | `list(object)`      |  `[]`   |
| dedicated_databases                | List of all dedicated databases without suffixes. The tenant db_suffix will be used as a suffix for each database in this list. | `list(string)`      |  `[]`   |
| shared_databases                   | Map of all shared databases (shared between tenants) without suffixes. The map key is used as a suffix.                         | `map(list(string))` |  `{}`   |
| extra_databases                    | List of full names of all extra databases.                                                                                      | `list(string)`      |  `[]`   |
| postgresql_inherited_roles         | Map of PostgreSQL roles with inherited privileges from other roles.                                                             | `map(list(string))` |  `{}`   |
| postgresql_extra_roles             | Map of additional PostgreSQL roles with detailed privilege configuration.                                                       | `map(object)`       |  `{}`   |
| postgresql_aad_roles               | Map of Azure Active Directory roles for PostgreSQL with privilege settings.                                                     | `map(object)`       |  `{}`   |
| postgresql_aad_role_mapping        | Map of PostgreSQL role mappings to Azure AD objects.                                                                            | `map(object)`       |  `{}`   |
| postgresql_aad_administrator_login | Azure AD administrator username for PostgreSQL.                                                                                 | `string`            | `null`  |
| postgresql_server_host             | PostgreSQL server hostname for Azure AD connection.                                                                             | `string`            | `null`  |

## Outputs

| Name                          | Description                                            |
|-------------------------------|--------------------------------------------------------|
| dedicated_databases           | List of created dedicated database names with suffixes |
| shared_databases              | List of created shared database names                  |
| extra_databases               | List of created extra database names                   |
| all_databases                 | List of all created database names                     |
| generic_reader                | List of all generic reader role names                  |
| inherited_role                | List of all inherited role names                       |
| dedicated_role                | List of all dedicated role names                       |
| advanced_role                 | List of all advanced role names                        |
| generic_role_db_map           | Map of generic roles to databases                      |
| advanced_role_db_map          | Map of advanced roles to databases                     |
| inherited_role_credentials    | Credentials for inherited roles (sensitive)            |
| pg_dedicated_role_credentials | Credentials for dedicated roles (sensitive)            |
| pg_advanced_role_credentials  | Credentials for advanced roles (sensitive)             |

## Troubleshooting

When using this module, be aware of the following:

1. **Parallelism Settings**: Due to the large number of resources created by this module:
   - For `terraform plan`, it's recommended to increase parallelism to speed up planning:
     ```
     terraform plan -parallelism=25
     ```
   - For `terraform apply`, it's recommended to reduce parallelism to avoid concurrent update errors:
     ```
     terraform apply -parallelism=5
     ```
   - Adjust these values based on your specific environment and resource count

2. **Concurrent Updates**: The following error may occur due to multiple concurrent changes to the same PostgreSQL resources. If you encounter it, simply re-run `terraform plan` and `terraform apply`:
   ```
   Error: could not execute revoke query: pq: tuple concurrently updated
   ```

3. **Provider Configuration**: Ensure both `postgresql.main` and `postgresql.aad` providers are properly configured.

4. **Azure AD Integration**: For AAD integration to work properly:
   - The `postgresql_aad_administrator_login` and `postgresql_server_host` variables must be set
   - The executing account must have proper permissions to create AAD roles
   - The Azure CLI must be installed and logged in with appropriate permissions

5. **Key Vault**: If using Key Vault integration for storing secrets:
   - Set `key_vault.name` and `key_vault.resource_group` appropriately
   - Ensure the executing account has access to manage secrets in the specified Key Vault

## Examples

### `main.tf` example

```hcl
provider "azurerm" {
  subscription_id = "32e1ba25-a697-4ea2-b19f-1b35869d1b11" # ExampleSubsciption
  features {}
}

provider "postgresql" {
  alias             = "pg-main"
  host              = module.fpsql.server_fqdn
  port              = 5432
  sslmode           = "require"
  connect_timeout   = 60
  max_connections   = 50
  username          = module.fpsql.administrator_login
  password          = module.fpsql.administrator_password
  superuser         = false
  expected_version  = module.fpsql.postgresql_version
}

provider "postgresql" {
  alias             = "pg-aad"
  host              = module.fpsql.server_fqdn
  port              = 5432
  sslmode           = "require"
  connect_timeout   = 60
  max_connections   = 10
  username          = module.fpsql.aad_administrator_login[0]
  password          = var.postgresql_aad_administrator_password
  superuser         = false
  expected_version  = module.fpsql.postgresql_version
}

module "databases" {
  source = "git::https://github.com/dkadetov/terraform-azure-postgres.git//modules/databases?ref=main"

  providers = {
    postgresql.main = postgresql.pg-main
    postgresql.aad  = postgresql.pg-aad
  }

  key_vault = {
    secrets_name_prefix = "fpsql-"
  }

  postgresql_server_host             = module.fpsql.server_fqdn
  postgresql_aad_administrator_login = module.fpsql.aad_administrator_login[0]

  administrator_login     = module.fpsql.administrator_login
  administrator_password  = module.fpsql.administrator_password
  
  tenants = [
    {
      name              = "alpha"
      db_suffix         = "_alpha"
    },
    {
      name              = "beta"
      db_suffix         = "_beta"
    },
  ]
  
  dedicated_databases = [
    "main",
    "audit",
  ]
  
  shared_databases = {
    shared = [
      "foo",
      "bar"
    ]
    cloud = [
      "foo",
      "bar"
    ]
  }

  extra_databases = [
    "keycloak",
    "gitea",
    "superset",
    "apicurio",
    "analytics"
  ]

  postgresql_extra_roles = {
    connect = {
      roles = ["fpsqladmin"]
      replication = true
      privileges = {}
    }
    readwrite_superset = {
      privileges = {
        superset = [
          {
            schema = "public"
            object_type = "table"
            privileges = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE", "REFERENCES"]
          },
          {
            schema = "public"
            object_type = "sequence"
            privileges = ["SELECT", "UPDATE"]
          },
          {
            schema = "public"
            object_type = "schema"
            privileges = ["CREATE", "USAGE"]
          },
        ]
      }
    }
    readonly_foo_keycloak = {
      privileges = {
        foo_shared = [{}]
        foo_cloud  = [{}]
        keycloak   = [{}]
      }
    }
    readonly_support = {
      roles      = ["generic_reader_all"]
      privileges = {
        analytics = [
          {
            schema      = "query_store"
            object_type = "schema"
            privileges  = ["USAGE"]
          },
          {
            schema      = "query_store"
            object_type = "table"
            objects     = [
              "stats",
              "entries",
            ]
            privileges  = ["SELECT"]
          },
        ]
      }
    }
  }

  postgresql_inherited_roles = {
    readonly_beta   = ["generic_reader_beta", "generic_reader_cloud", "readonly_foo_keycloak"]
    readonly_common = ["generic_reader_shared", "generic_reader_cloud"]
  }

  postgresql_aad_role_mapping = {
    Common_Group = {
      role_name   = "readonly_common"
      object_id   = "8gh21650-0322-4e45-9484-4e4ba67ecyz7"
      object_type = "group"
    }
  }

  postgresql_aad_roles = {
    john_smith = {
      role_name = "john.smith@example.com"
      privileges = {
        keycloak = [{}]
        superset = [{}]
      }
    }
    support = {
      role_name   = "Support_Group"
      grant_roles = ["readonly_support"]
      privileges  = {}
    }
    developers = {
      role_name   = "Dev_Group"
      grant_roles = ["generic_reader_alpha", "generic_reader_beta", "generic_reader_shared"]
      privileges  = {
        apicurio = [{}]
      }
    }
    sre = {
      role_name   = "SRE_Group"
      grant_roles = ["generic_reader_all"]
      privileges  = {}
    }
    ops = {
      role_name   = "OPS_Group"
      grant_roles = ["connect"]
      privileges  = {}
    }
  }
}
```

### `variables.tf` example

If you are using `postgresql_aad_role_mapping`, you need to pass an access token as a password to the `pg-aad` provider.

This can be done using a standard environment variable:

```bash
PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms --query accessToken -o tsv)
```

Or by using a specialized variable as shown in this example:

```hcl
variable "postgresql_aad_administrator_password" {
  description = "Microsoft Entra ID token."
  type        = string
  sensitive   = true
}
```

Corresponding shell command:

```bash
export TF_VAR_postgresql_aad_administrator_password=$(az account get-access-token --resource-type oss-rdbms --query accessToken -o tsv)
```
