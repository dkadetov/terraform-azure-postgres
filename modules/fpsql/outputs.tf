output "server_id" {
  value = azurerm_postgresql_flexible_server.fpsql.id
}

output "server_name" {
  value = azurerm_postgresql_flexible_server.fpsql.name
}

output "resource_group_name" {
  value = var.resource_group
}

output "postgresql_version" {
  value = var.postgresql_version
}

output "server_fqdn" {
  value = azurerm_postgresql_flexible_server.fpsql.fqdn
}

output "administrator_login" {
  value = var.administrator_login
}

output "administrator_password" {
  value     = local.administrator_password
  sensitive = true
}

output "aad_administrator_login" {
  value = var.aad_admin
}
