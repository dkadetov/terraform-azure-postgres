resource "azurerm_postgresql_flexible_server" "fpsql" {
  name                = "${var.name_prefix}-fpsql"
  location            = var.location
  resource_group_name = var.resource_group

  administrator_login    = var.administrator_login
  administrator_password = local.administrator_password

  create_mode      = var.postgresql_create_mode
  source_server_id = var.postgresql_source_id
  sku_name         = var.sku_name
  version          = var.postgresql_version
  storage_mb       = var.storage_mb
  storage_tier     = var.storage_tier

  backup_retention_days        = var.storage_retention_days
  geo_redundant_backup_enabled = var.storage_geo_redundant_backup
  auto_grow_enabled            = var.auto_grow_enabled

  zone = tostring(var.zone)

  dynamic "high_availability" {
    for_each = contains(["SameZone", "ZoneRedundant"], var.high_availability_mode) ? var.high_availability_mode[*] : []
    content {
      mode = var.high_availability_mode
    }
  }

  public_network_access_enabled = var.public_network_access_enabled
  delegated_subnet_id           = var.fpsql_server_network.subnet_create ? azurerm_subnet.fpsql_sn[0].id : null
  private_dns_zone_id           = var.fpsql_server_network.subnet_create ? var.fpsql_server_network.private_dns_zone_create ? azurerm_private_dns_zone.fpsql_dns_zone[0].id : data.azurerm_private_dns_zone.fpsql_dns_zone[0].id : null

  authentication {
    active_directory_auth_enabled = var.aad_auth
    password_auth_enabled         = var.password_auth
    tenant_id                     = var.aad_auth ? data.azurerm_subscription.current.tenant_id : null
  }

  lifecycle {
    ignore_changes = [
      create_mode,
      zone,
      tags,
    ]
  }
}

resource "azurerm_postgresql_flexible_server_configuration" "server_configuration" {
  for_each = merge(var.fpsql_server_configuration, var.fpsql_extra_server_configuration)

  name      = each.key
  value     = each.value
  server_id = azurerm_postgresql_flexible_server.fpsql.id

  depends_on = [azurerm_postgresql_flexible_server.fpsql]
}
