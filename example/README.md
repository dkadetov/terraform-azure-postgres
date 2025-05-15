# Azure PostgreSQL Flexible Server: Terraform Example

> **Disclaimer**: This README was generated with the assistance of an AI agent and may contain inaccuracies or errors. Please review and validate the information before implementation.

## Table of Contents

- [Overview](#azure-postgresql-flexible-server-terraform-example)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
- [Configuration Structure](#configuration-structure)
- [Variables](#variables)
- [Multi-Tenant Database Structure](#multi-tenant-database-structure)
- [Security Features](#security-features)
- [Notes](#notes)

This example demonstrates how to use the `terraform-azure-postgres` modules to deploy a complete PostgreSQL Flexible Server solution in Azure with the following features:

- PostgreSQL Flexible Server deployment with private network configuration
- Database and role management with both standard and AAD authentication
- Load balancer integration with Kubernetes
- Multi-tenant database structure

> **Important:** This implementation requires an existing AKS cluster with a VNet. The example does not create these resources but integrates with them.

## Architecture

This example deploys:

1. An Azure PostgreSQL Flexible Server
2. Private networking configuration with VNet integration (uses existing VNet)
3. Kubernetes service with LoadBalancer type and Public IP
4. Multiple databases for multi-tenant architecture:
   - Tenant-specific databases (alpha, beta)
   - Shared databases (foo, bar)
   - System databases (keycloak, gitea, superset, etc.)
5. Complex role-based access control with:
   - Standard PostgreSQL roles
   - Azure AD integrated roles and groups
   - Inherited role hierarchies

## Prerequisites

- An Azure subscription
- Terraform v1.9.0 or newer
- Azure CLI configured with appropriate permissions
- **Existing AKS cluster with a VNet** (this example integrates with an existing AKS cluster)
- An existing Azure Key Vault for secret storage

## Usage

1. Clone the repository:
   ```
   git clone https://github.com/dkadetov/terraform-azure-postgres.git
   cd terraform-azure-postgres/example
   ```

2. Update both `terraform.tfvars` and `main.tf` with your specific configuration:
   - In `terraform.tfvars`:
     - Azure subscription ID
     - Resource group and location
     - Key Vault details
     - PostgreSQL configuration
     - Password for the PostgreSQL administrator
     - Public IP configuration for PostgreSQL LoadBalancer
     - Kubernetes service configuration
   - In `main.tf`:
     - Update the Kubernetes provider configuration with your cluster context
     - Modify any other settings specific to your environment

3. Initialize Terraform with provider upgrades:
   ```
   terraform init -upgrade
   ```

4. Set the AAD administrator token environment variable:
   ```
   export TF_VAR_postgresql_aad_administrator_password=$(az account get-access-token --resource-type oss-rdbms --query accessToken -o tsv)
   ```

5. Create an execution plan:
   ```
   terraform plan -parallelism=50 -out plan.out
   ```

6. Apply the configuration with lower parallelism to avoid concurrent update errors:
   ```
   terraform apply -parallelism=1 plan.out
   ```

## Configuration Structure

- `main.tf` - Main configuration file defining providers and modules
- `variables.tf` - Variable definitions
- `terraform.tfvars` - Variable values (update with your own values)
- `aks.tf` - Kubernetes service and public IP configuration
- `data-sources.tf` - Data sources for existing Azure resources
- `outputs.tf` - Outputs for important resource information
- `versions.tf` - Provider version constraints

## Variables

Key variables to configure:

| Name                                    | Description                                                  |
|-----------------------------------------|--------------------------------------------------------------|
| `subscription_id`                       | Azure subscription ID where resources will be deployed       |
| `resource_group`                        | Azure Resource Group configuration with name and location    |
| `key_vault`                             | Azure Key Vault configuration for storing PostgreSQL secrets |
| `fpsql_conf`                            | Configuration object for PostgreSQL Flexible Server          |
| `administrator_password`                | Password for the PostgreSQL administrator                    |
| `postgresql_aad_administrator_password` | Microsoft Entra ID token for AAD admin                       |
| `fpsql_pip`                             | Public IP configuration for PostgreSQL LoadBalancer          |
| `fpsql_svc`                             | Kubernetes service configuration                             |

## Multi-Tenant Database Structure

This example demonstrates a multi-tenant database architecture with:

- **Tenant-specific databases**: Each tenant (alpha, beta) gets dedicated databases with the tenant's suffix
- **Shared databases**: Common databases shared between tenants
- **System databases**: For supporting services (keycloak, gitea, etc.)

## Security Features

- Azure AD integration for role-based access
- Hierarchical role inheritance
- Group-based permissions
- Private networking with VNet integration
- Key Vault integration for secret management

## Notes

- In production environments, ensure you manage secrets securely
- Review the public IP and network security settings for your specific security requirements
- For production, consider enabling storage alerts and high availability 
- For team collaboration and production use, it's strongly recommended to use the "azurerm" backend instead of the local backend to store state files securely in Azure Storage
- When using the `databases` module, you should ensure proper deployment sequence of resources. The order of resource creation is critical, and you should manually verify and control this sequence to avoid dependency issues
