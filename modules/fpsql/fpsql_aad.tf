data "azuread_group" "fpsql_aad_admin" {
  for_each = var.aad_auth ? toset(var.aad_admin) : []

  display_name = each.key
}

resource "azurerm_postgresql_flexible_server_active_directory_administrator" "aad_admin" {
  for_each = var.aad_auth ? data.azuread_group.fpsql_aad_admin : {}

  server_name         = azurerm_postgresql_flexible_server.fpsql.name
  resource_group_name = var.resource_group
  tenant_id           = data.azurerm_subscription.current.tenant_id
  object_id           = each.value.object_id
  principal_name      = each.value.display_name
  principal_type      = "Group"

  depends_on = [azurerm_postgresql_flexible_server.fpsql]
}
