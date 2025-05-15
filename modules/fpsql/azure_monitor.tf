resource "azurerm_monitor_metric_alert" "fpsql_storage" {
  count = var.fpsql_storage_alert.create ? 1 : 0

  enabled             = var.fpsql_storage_alert.enable
  name                = "${azurerm_postgresql_flexible_server.fpsql.name}-storage"
  resource_group_name = var.resource_group
  scopes = [
    azurerm_postgresql_flexible_server.fpsql.id,
  ]
  description = format("%s has consumed %.1f%% of its storage.", azurerm_postgresql_flexible_server.fpsql.name, 100 * var.fpsql_storage_alert.threshold)
  frequency   = var.fpsql_storage_alert.frequency
  window_size = var.fpsql_storage_alert.window_size
  severity    = 2

  criteria {
    aggregation            = "Average"
    metric_name            = "storage_percent"
    metric_namespace       = "Microsoft.DBforPostgreSQL/flexibleServers"
    operator               = "GreaterThan"
    skip_metric_validation = false
    threshold              = 100 * var.fpsql_storage_alert.threshold
  }

  action {
    action_group_id = var.action_group_id
  }

  depends_on = [azurerm_postgresql_flexible_server.fpsql]
}

resource "azurerm_monitor_metric_alert" "fpsql_replication_lag" {
  count = var.fpsql_lag_alert.create ? 1 : 0

  enabled             = var.fpsql_lag_alert.enable
  name                = "${azurerm_postgresql_flexible_server.fpsql.name}-replication-lag"
  resource_group_name = var.resource_group
  scopes = [
    azurerm_postgresql_flexible_server.fpsql.id,
  ]
  description = "Dynamic rule: maximum lag across all logical replication slots"
  frequency   = var.fpsql_lag_alert.frequency
  window_size = var.fpsql_lag_alert.window_size
  severity    = var.fpsql_lag_alert.severity

  dynamic_criteria {
    aggregation            = "Average"
    metric_name            = "logical_replication_delay_in_bytes"
    metric_namespace       = "Microsoft.DBforPostgreSQL/flexibleServers"
    operator               = "GreaterThan"
    alert_sensitivity      = var.fpsql_lag_alert.sensitivity
    skip_metric_validation = false
  }

  action {
    action_group_id = var.action_group_id
  }

  depends_on = [azurerm_postgresql_flexible_server.fpsql]
}
