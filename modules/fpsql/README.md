# FPSQL Terraform module

> **Disclaimer**: This README was generated with the assistance of an AI agent and may contain inaccuracies or errors. Please review and validate the information before implementation.

## Table of Contents

- [Overview](#fpsql-terraform-module)
- [Core Resource](#core-resource)
- [Network Resources (Optional)](#network-resources-optional)
- [Security Resources (Optional)](#security-resources-optional)
- [Monitoring Resources (Optional)](#monitoring-resources-optional)
- [Resource Deployment Logic](#resource-deployment-logic)
  - [PostgreSQL Server](#postgresql-server)
  - [Networking](#networking)
  - [Authentication](#authentication)
  - [Security and Storage](#security-and-storage)
  - [Monitoring](#monitoring)
- [Network Resource Decision Logic](#network-resource-decision-logic)
  - [Private DNS Zone](#private-dns-zone)
  - [Data Source for Existing Private DNS Zone](#data-source-for-existing-private-dns-zone)
  - [Private DNS Zone VNet Link](#private-dns-zone-vnet-link)
  - [Private Endpoint](#private-endpoint)
  - [PostgreSQL Subnet](#postgresql-subnet)
  - [PostgreSQL Server Network Configuration](#postgresql-server-network-configuration)
  - [Networking Decision Flow Chart](#networking-decision-flow-chart)
- [Requirements](#requirements)
- [Inputs](#inputs)
- [Outputs](#outputs)
- [Examples](#examples)
  - [Main Configuration Example](#maintf-example)
  - [Variables Example](#variablestf-example)

Creates Azure Flexible PostgreSQL resources for infrastructure. The module deploys a PostgreSQL server and a set of optional resources based on configuration:

## Core Resource
- PostgreSQL Flexible Server

## Network Resources (Optional)
- Private DNS zone (`privatelink.postgres.database.azure.com`)
- Private endpoint (`*-fpsql-pe`)
- Network interface (`*-fpsql-nic`)
- Subnet with PostgreSQL delegation
- Firewall rules (when public network access is enabled)

## Security Resources (Optional)
- Key Vault secrets for PostgreSQL credentials (`*-fpsql-admin-password`, `*-fpsql-admin-name`)
- Azure Active Directory authentication and administrators

## Monitoring Resources (Optional)
- Diagnostic settings
- Storage and replication lag alerts

## Resource Deployment Logic

The module creates resources based on the following logic:

### PostgreSQL Server
- Always creates a PostgreSQL Flexible Server with the specified configuration
- High availability is configured only when `high_availability_mode` is set to "SameZone" or "ZoneRedundant"
- Server configuration parameters are applied from both `fpsql_server_configuration` and `fpsql_extra_server_configuration`

### Networking
- Private connectivity uses either an existing subnet or creates a new subnet with PostgreSQL delegation
- Network resources creation is controlled by the `fpsql_server_network` object:
  - If `subnet_create = true`, a dedicated subnet with PostgreSQL delegation is created
  - If `private_dns_zone_create = true`, a new Private DNS zone is created
  - If `private_endpoint_create = true`, a Private Endpoint is created to connect to the PostgreSQL server
- Firewall rules are created only when `public_network_access_enabled = true`

### Authentication
- Password authentication is enabled by default but can be disabled
- Azure AD authentication can be enabled with `aad_auth = true`
- Administrator password is either user-provided or auto-generated

### Security and Storage
- Key Vault secrets are created only when `key_vault.secrets_create = true`
- Database storage configuration uses the settings from `storage_mb`, `storage_tier`, and related variables

### Monitoring
- Diagnostic settings are created only when `fpsql_server_diagnostic.enable = true`
- Storage and replication lag alerts are created when their respective `create` flags are set to `true`
- Alerts require an `action_group_id` to be specified

## Network Resource Decision Logic

The module implements complex conditional resource creation to support various networking scenarios. Here's a detailed explanation of how network resources are created:

### Private DNS Zone
- **Creation Condition**: Created when `private_dns_zone_create = true`
- **Usage**: Used for private DNS resolution of the PostgreSQL server

### Data Source for Existing Private DNS Zone
- **Lookup Condition**: Used when either:
  - `private_endpoint_create = true` OR 
  - (`subnet_create = true` AND `private_dns_zone_create = false`)
- **Purpose**: References an existing DNS zone when not creating a new one

### Private DNS Zone VNet Link
- **Creation Condition**: Created when `private_dns_zone_create = true`
- **Purpose**: Links the Private DNS Zone to the specified virtual network
- **Requirement**: Requires `vnet_name` to be specified (validated with precondition)

### Private Endpoint
- **Creation Condition**: Created when `private_endpoint_create = true`
- **Requirement**: Requires `subnet_id` to be specified (validated with precondition)
- **DNS Zone Selection**: Uses either the created or existing Private DNS Zone based on `private_dns_zone_create`

### PostgreSQL Subnet
- **Creation Condition**: Created when `subnet_create = true`
- **Purpose**: Creates a subnet with PostgreSQL service delegation
- **Requirement**: Requires `vnet_name` to be specified

### PostgreSQL Server Network Configuration
- **Delegated Subnet**: Set to the created subnet ID when `subnet_create = true`, otherwise `null`
- **Private DNS Zone ID**: Complex conditional logic:
  - Only set when `subnet_create = true`
  - If also `private_dns_zone_create = true`, uses the created DNS zone
  - Otherwise, uses the data source for an existing DNS zone

### Networking Decision Flow Chart
1. **For Private Connectivity**:
   - Either use an existing subnet (set `subnet_id`) or create a new one (set `subnet_create = true`)
   - Either use an existing DNS zone (set `private_dns_zone_create = false`) or create a new one (set `private_dns_zone_create = true`)
   - For Private Endpoint: set `private_endpoint_create = true` and ensure `subnet_id` is provided

2. **For Public Access**:
   - Set `public_network_access_enabled = true`
   - Configure firewall rules in `fpsql_firewall_rules` if needed

## Requirements

| Name      | Version   |
|-----------|-----------|
| terraform | >= 1.9.0  |
| azurerm   | ~> 4.27.0 |
| azuread   | ~> 3.3.0  |
| random    | ~> 3.7.2  |

## Inputs

| Name                             | Description                                                                          | Type           | Default                                            |
|----------------------------------|--------------------------------------------------------------------------------------|----------------|----------------------------------------------------|
| name_prefix                      | Prefix for naming PostgreSQL resources.                                              | `string`       | —                                                  |
| location                         | Azure location where resources will be deployed.                                     | `string`       | —                                                  |
| resource_group                   | Name of the Azure resource group where resources will be created.                    | `string`       | —                                                  |
| aad_admin                        | Object defining Azure Active Directory administrator settings for PostgreSQL server. | `list(string)` | `[]`                                               |
| aad_auth                         | Flag enabling Azure Active Directory authentication.                                 | `bool`         | `true`                                             |
| password_auth                    | Flag enabling password authentication.                                               | `bool`         | `true`                                             |
| key_vault                        | Object with Key Vault settings for storing PostgreSQL secrets.                       | `object`       | `{}`                                               |
| administrator_login              | Administrator username for PostgreSQL server.                                        | `string`       | `"fpsqladmin"`                                     |
| administrator_password           | Administrator password for PostgreSQL server.                                        | `string`       | `null`                                             |
| postgresql_version               | PostgreSQL server version.                                                           | `string`       | `"14"`                                             |
| postgresql_create_mode           | PostgreSQL server creation mode (Default, PointInTimeRestore, GeoRestore).           | `string`       | `"Default"`                                        |
| postgresql_source_id             | Source server ID for PostgreSQL server restoration.                                  | `string`       | `null`                                             |
| sku_name                         | SKU name for PostgreSQL server, defining computing resources.                        | `string`       | `"GP_Standard_D2ds_v5"`                            |
| storage_mb                       | PostgreSQL storage size in megabytes.                                                | `number`       | `262144`                                           |
| storage_tier                     | PostgreSQL storage tier.                                                             | `string`       | `"P15"`                                            |
| storage_retention_days           | Number of days for backup retention.                                                 | `number`       | `14`                                               |
| storage_geo_redundant_backup     | Flag enabling geo-redundant backup.                                                  | `bool`         | `true`                                             |
| auto_grow_enabled                | Flag enabling automatic storage growth.                                              | `bool`         | `true`                                             |
| zone                             | Azure availability zone for PostgreSQL server.                                       | `string`       | `null`                                             |
| high_availability_mode           | High availability mode for PostgreSQL server.                                        | `string`       | `"Disabled"`                                       |
| public_network_access_enabled    | Flag allowing public network access to PostgreSQL server.                            | `bool`         | `true`                                             |
| fpsql_firewall_rules             | List of firewall rules for PostgreSQL server.                                        | `list(object)` | `[]`                                               |
| fpsql_server_network             | Object with network settings for PostgreSQL server.                                  | `object`       | Predefined complex object with networking settings |
| fpsql_server_configuration       | Map of PostgreSQL server configuration parameters.                                   | `map(string)`  | Predefined configuration parameters                |
| fpsql_extra_server_configuration | Additional PostgreSQL server configuration parameters.                               | `map(string)`  | `{}`                                               |
| fpsql_server_diagnostic          | PostgreSQL server diagnostic settings.                                               | `object`       | Predefined complex object with diagnostic settings |
| action_group_id                  | Action group ID for alerts.                                                          | `string`       | `null`                                             |
| fpsql_storage_alert              | Settings for PostgreSQL storage usage alerts.                                        | `object`       | Predefined complex object with alert settings      |
| fpsql_lag_alert                  | Settings for PostgreSQL replication lag alerts.                                      | `object`       | Predefined complex object with alert settings      |

## Outputs

| Name                    | Description                                              |
|-------------------------|----------------------------------------------------------|
| server_id               | The ID of the PostgreSQL Flexible Server                 |
| server_name             | The name of the PostgreSQL Flexible Server               |
| resource_group_name     | The name of the resource group                           |
| postgresql_version      | The PostgreSQL version used                              |
| server_fqdn             | The fully qualified domain name of the PostgreSQL server |
| administrator_login     | The administrator username                               |
| administrator_password  | The administrator password (sensitive)                   |
| aad_administrator_login | The Azure AD administrator login                         |

## Examples

### `main.tf` example

```hcl
provider "azurerm" {
  subscription_id = "32e1ba25-a697-4ea2-b19f-1b35869d1b11" # ExampleSubsciption
  features {}
}

module "fpsql" {
  source = "git::https://github.com/dkadetov/terraform-azure-postgres.git//modules/fpsql?ref=main"

  name_prefix                   = "poc"
  location                      = "westeurope"
  resource_group                = "fpsql-rg"
  sku_name                      = "B_Standard_B1ms"
  storage_mb                    = 32768
  storage_tier                  = "P4"
  storage_retention_days        = 7
  storage_geo_redundant_backup  = false
  auto_grow_enabled             = false
  aad_auth                      = false
  aad_admin                     = ["Azure_ExampleSubsciption_Admin", "Azure_ExampleSubsciption_SuperAdmin"]
  administrator_login           = "fpsqladmin"
  administrator_password        = var.administrator_password
  public_network_access_enabled = false

  fpsql_server_configuration = {}

  fpsql_server_network = {
    private_dns_zone_create = true
    private_dns_zone_name   = "poc.postgres.database.azure.com"
    private_endpoint_create = false
    vnet_name               = "aks-vnet"
    vnet_resource_group     = "aks-rg"
    subnet_create           = true
  }

  fpsql_storage_alert = {
    create = false
  }

  fpsql_lag_alert = {
    create = false
  }

  key_vault = {
    secrets_create = false
  }

}
```

### `variables.tf` example

```hcl
variable "administrator_password" {
  description = "Enter the password for the PostgreSQL server. Make sure it meets the security requirements."
  type        = string
  sensitive   = true
}
```
