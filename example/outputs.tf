output "server_id" {
  value = module.fpsql.server_id
}

output "server_name" {
  value = module.fpsql.server_name
}

output "resource_group_name" {
  value = module.fpsql.resource_group_name
}

output "postgresql_version" {
  value = module.fpsql.postgresql_version
}

output "server_fqdn" {
  value = module.fpsql.server_fqdn
}

output "administrator_login" {
  value = module.fpsql.administrator_login
}

output "administrator_password" {
  value     = module.fpsql.administrator_password
  sensitive = true
}

output "aad_administrator_login" {
  value = module.fpsql.aad_administrator_login
}

output "dedicated_databases" {
  value = module.databases.dedicated_databases
}

output "shared_databases" {
  value = module.databases.shared_databases
}

output "extra_databases" {
  value = module.databases.extra_databases
}

output "all_databases" {
  value = module.databases.all_databases
}

output "generic_reader" {
  value = module.databases.generic_reader
}

output "inherited_reader" {
  value = module.databases.inherited_role
}

output "dedicated_role" {
  value = module.databases.dedicated_role
}

output "advanced_role" {
  value = module.databases.advanced_role
}

output "generic_role_db_map" {
  value = module.databases.generic_role_db_map
}

output "advanced_role_db_map" {
  value = module.databases.advanced_role_db_map
}
