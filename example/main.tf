#terraform {
#  backend "azurerm" {
#    subscription_id      = "SUBSCRIPTION_ID"
#    resource_group_name  = "RESOURCE_GROUP_NAME"
#    storage_account_name = "UNIQ_SA_NAME"
#    container_name       = "CONTAINER_NAME"
#    key                  = "KEY.tfstate"
#  }
#}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

provider "azapi" {
  subscription_id = var.subscription_id
}

provider "kubernetes" {
  config_context = "K8S_CONTEXT"
  config_path    = "~/.kube/config"
}

provider "postgresql" {
  alias             = "pg-main"
  host              = azurerm_public_ip.fpsql_poc_pip.fqdn
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
  host              = azurerm_public_ip.fpsql_poc_pip.fqdn
  port              = 5432
  sslmode           = "require"
  connect_timeout   = 60
  max_connections   = 10
  username          = module.fpsql.aad_administrator_login[0]
  password          = var.postgresql_aad_administrator_password
  superuser         = false
  expected_version  = module.fpsql.postgresql_version
}

resource "azurerm_resource_group" "fpsql_poc" {
  name     = var.resource_group.name
  location = var.resource_group.location
}

module "fpsql" {
#  source = "git::https://github.com/dkadetov/terraform-azure-postgres.git//modules/fpsql?ref=main"
  source = "../modules/fpsql"

  name_prefix                   = var.fpsql_conf.name_prefix
  location                      = azurerm_resource_group.fpsql_poc.location
  resource_group                = azurerm_resource_group.fpsql_poc.name
  sku_name                      = var.fpsql_conf.sku_name
  storage_mb                    = var.fpsql_conf.storage_mb
  storage_tier                  = var.fpsql_conf.storage_tier
  storage_retention_days        = var.fpsql_conf.storage_retention_days
  storage_geo_redundant_backup  = false
  auto_grow_enabled             = false
  aad_auth                      = var.fpsql_conf.aad_auth
  aad_admin                     = var.fpsql_conf.aad_admin
  administrator_login           = var.fpsql_conf.administrator_login
  administrator_password        = var.administrator_password
  public_network_access_enabled = false

  fpsql_server_configuration = {}

  fpsql_server_network = {
    private_dns_zone_create = true
    private_dns_zone_name   = var.fpsql_conf.private_dns_zone_name
    private_endpoint_create = false
    vnet_name               = var.fpsql_conf.vnet_name
    vnet_resource_group     = var.fpsql_conf.vnet_resource_group
    subnet_create           = true
  }

  fpsql_storage_alert = {
    create = false
  }

  fpsql_lag_alert = {
    create = false
  }

  key_vault = {
    name           = var.key_vault.name
    resource_group = var.key_vault.resource_group
    secrets_create = false
  }

}

module "databases" {
#  source = "git::https://github.com/dkadetov/terraform-azure-postgres.git//modules/databases?ref=main"
  source = "../modules/databases"

  providers = {
    postgresql.main = postgresql.pg-main
    postgresql.aad  = postgresql.pg-aad
  }

  key_vault = {
    name                = var.key_vault.name
    resource_group      = var.key_vault.resource_group
    secrets_create      = false
    secrets_name_prefix = "${var.fpsql_conf.name_prefix}-"
  }

  postgresql_server_host             = azurerm_public_ip.fpsql_poc_pip.fqdn
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
      roles = [var.fpsql_conf.administrator_login]
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
  }

  postgresql_inherited_roles = {
    readonly_beta   = ["generic_reader_beta", "generic_reader_cloud", "readonly_foo_keycloak"]
    readonly_common = ["generic_reader_shared", "generic_reader_cloud"]
  }

  postgresql_aad_role_mapping = {
    Common_Group = {
      role_name   = "readonly_foo_keycloak"
      object_id   = "9ec55850-0364-4e74-9484-6d4ba56jrvp7"
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
      grant_roles = ["generic_reader_all"]
      privileges  = {}
    }
    developers = {
      role_name   = "Dev_Group"
      grant_roles = ["generic_reader_alpha", "generic_reader_beta", "generic_reader_shared"]
      privileges  = {
        apicurio = [{}]
      }
    }
    ops = {
      role_name   = "OPS_Group"
      grant_roles = ["connect"]
      privileges  = {}
    }
  }
}