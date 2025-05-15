data "azurerm_key_vault" "key_vault" {
  count = var.key_vault.secrets_create ? 1 : 0

  name                = var.key_vault.name
  resource_group_name = coalesce(var.key_vault.resource_group, var.resource_group)
}

resource "random_password" "fpsql_admin_password" {
  count = var.administrator_password != null ? 0 : 1

  length           = 20
  special          = true
  override_special = "!#%*()-_=+[]{}<>:?"
}

# copy the fpsql admin password to the env key vault
resource "azurerm_key_vault_secret" "kv_fpsql_admin_password" {
  count = var.key_vault.secrets_create ? 1 : 0

  name         = "${var.name_prefix}-fpsql-admin-password"
  value        = local.administrator_password
  key_vault_id = data.azurerm_key_vault.key_vault[0].id

  expiration_date = var.key_vault.secrets_expiration_date

  tags = {
    "managedBy" = "terraform"
  }
}

# copy the fpsql admin name to the env key vault
resource "azurerm_key_vault_secret" "kv_fpsql_admin_name" {
  count = var.key_vault.secrets_create ? 1 : 0

  name         = "${var.name_prefix}-fpsql-admin-name"
  value        = var.administrator_login
  key_vault_id = data.azurerm_key_vault.key_vault[0].id

  expiration_date = var.key_vault.secrets_expiration_date

  tags = {
    "managedBy" = "terraform"
  }
}
