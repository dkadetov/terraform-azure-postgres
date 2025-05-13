subscription_id = "SUBSCRIPTION_ID"

resource_group = {
  name     = "postgresPOC"
  location = "westeurope"
}

key_vault = {
  name           = "KEY_VAULT_NAME"
  resource_group = "RESOURCE_GROUP_NAME"
}

fpsql_conf = {
  name_prefix            = "poc"
  sku_name               = "B_Standard_B1ms"
  storage_mb             = 32768
  storage_tier           = "P4"
  storage_retention_days = 7
  aad_auth               = true
  aad_admin              = ["AAD_ADMIN_GROUP"]
  administrator_login    = "fpsqladmin"
  private_dns_zone_name  = "poc.postgres.database.azure.com"
  vnet_name              = "AKS_VNET_NAME"
  vnet_resource_group    = "RESOURCE_GROUP_NAME"
}

administrator_password = "ADMINISTRATOR_PASSWORD"

fpsql_pip = {
  name                = "fpsql-pip"
  location            = "westeurope"
  resource_group_name = "RESOURCE_GROUP_NAME"
  domain_name_label   = "fpsql-poc-pip"
  sku                 = "Standard"
}

fpsql_svc = {
  name      = "fpsql-poc"
  namespace = "K8S_NAMESPACE"
  port      = 5432
}
