resource "azurerm_postgresql_flexible_server_firewall_rule" "firewall_rule" {
  for_each = var.public_network_access_enabled ? {
    for firewall_rule in var.fpsql_firewall_rules :
      firewall_rule.name => firewall_rule
  } : {}

  name             = "firewall-${each.key}"
  server_id        = azurerm_postgresql_flexible_server.fpsql.id
  start_ip_address = each.value.start_ip
  end_ip_address   = each.value.end_ip

  depends_on = [azurerm_postgresql_flexible_server.fpsql]
}
