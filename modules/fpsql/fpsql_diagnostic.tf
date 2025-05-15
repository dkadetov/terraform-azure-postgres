resource "azurerm_monitor_diagnostic_setting" "fqsql_diags" {
  count = var.fpsql_server_diagnostic.enable ? 1 : 0

  name                       = var.fpsql_server_diagnostic.name
  target_resource_id         = azurerm_postgresql_flexible_server.fpsql.id
  log_analytics_workspace_id = var.fpsql_server_diagnostic.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = toset(var.fpsql_server_diagnostic.log_categories)
    content {
      category = enabled_log.value
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = var.fpsql_server_diagnostic.metric_enable
  }

  depends_on = [azurerm_postgresql_flexible_server.fpsql]
}
