data "azurerm_key_vault" "key_vault" {
  count = var.key_vault.secrets_create ? 1 : 0

  name                = var.key_vault.name
  resource_group_name = var.key_vault.resource_group
}

#----- inherited roles -----#

## save inherited db role passwords in the key vault
resource "azurerm_key_vault_secret" "pg_inherited_role_password" {
  for_each = var.key_vault.secrets_create ? random_password.inherited_role_password : {}

  name            = format("${var.key_vault.secrets_name_prefix}fpsql-role-password-%s", replace(each.key, "_", "-"))
  value           = random_password.inherited_role_password[each.key].result
  key_vault_id    = data.azurerm_key_vault.key_vault[0].id
  expiration_date = var.key_vault.secrets_expiration_date

  tags = {
    "managedBy" = "terraform"
  }
}

## save inherited db role name in the key vault
resource "azurerm_key_vault_secret" "pg_inherited_role_name" {
  for_each = var.key_vault.secrets_create ? toset(keys(var.postgresql_inherited_roles)) : []

  name            = format("${var.key_vault.secrets_name_prefix}fpsql-role-name-%s", replace(each.value, "_", "-"))
  value           = each.value
  key_vault_id    = data.azurerm_key_vault.key_vault[0].id
  expiration_date = var.key_vault.secrets_expiration_date

  tags = {
    "managedBy" = "terraform"
  }
}

#----- dedicated roles -----#

## save the fpsql users passwords to the env key vault
resource "azurerm_key_vault_secret" "pg_dedicated_role_password" {
  for_each = var.key_vault.secrets_create ? {
    for tenant in var.tenants : tenant.name => tenant if !tenant.db_admin_role && length(tenant.db_suffix) > 0
  } : {}

  name            = format("${var.key_vault.secrets_name_prefix}fpsql-role-password-%s", replace(each.key, "_", "-"))
  value           = each.value.db_admin_role ? var.administrator_password : random_password.pg_dedicated_role_password[each.key].result
  key_vault_id    = data.azurerm_key_vault.key_vault[0].id
  expiration_date = var.key_vault.secrets_expiration_date

  tags = {
    "managedBy" = "terraform"
  }
}

## save the fpsql users name to the env key vault
resource "azurerm_key_vault_secret" "pg_dedicated_role_name" {
  for_each = var.key_vault.secrets_create ? {
    for tenant in var.tenants : tenant.name => tenant if !tenant.db_admin_role && length(tenant.db_suffix) > 0
  } : {}

  name            = format("${var.key_vault.secrets_name_prefix}fpsql-role-name-%s", replace(each.key, "_", "-"))
  value           = each.value.db_admin_role ? var.administrator_login : each.key
  key_vault_id    = data.azurerm_key_vault.key_vault[0].id
  expiration_date = var.key_vault.secrets_expiration_date

  tags = {
    "managedBy" = "terraform"
  }
}

#----- advanced extra roles -----#

## save additional db role passwords in the key vault
resource "azurerm_key_vault_secret" "pg_advanced_role_password" {
  for_each = var.key_vault.secrets_create ? random_password.pg_advanced_role_password : {}

  name            = format("${var.key_vault.secrets_name_prefix}fpsql-role-password-%s", replace(each.key, "_", "-"))
  value           = random_password.pg_advanced_role_password[each.key].result
  key_vault_id    = data.azurerm_key_vault.key_vault[0].id
  expiration_date = var.key_vault.secrets_expiration_date

  tags = {
    "managedBy" = "terraform"
  }
}

## save additional db role names in the key vault
resource "azurerm_key_vault_secret" "pg_advanced_role_name" {
  for_each = var.key_vault.secrets_create ? postgresql_role.pg_advanced_role : {}

  name            = format("${var.key_vault.secrets_name_prefix}fpsql-role-name-%s", replace(each.key, "_", "-"))
  value           = each.key
  key_vault_id    = data.azurerm_key_vault.key_vault[0].id
  expiration_date = var.key_vault.secrets_expiration_date

  tags = {
    "managedBy" = "terraform"
  }
}
