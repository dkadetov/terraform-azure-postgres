output "dedicated_databases" {
  value = local.dedicated_databases[*].suffixed_db_name
}

output "shared_databases" {
  value = local.shared_databases
}

output "extra_databases" {
  value = var.extra_databases
}

output "all_databases" {
  value = local.all_databases
}

output "generic_reader" {
  value = [for k, v in postgresql_role.generic_reader : v.name]
}

output "inherited_role" {
  value = [for k, v in postgresql_role.inherited_role : k]
}

output "dedicated_role" {
  value = [for k, v in postgresql_role.pg_dedicated_role : k]
}

output "advanced_role" {
  value = [for k, v in postgresql_role.pg_advanced_role : k]
}

output "generic_role_db_map" {
  value = local.generic_role_db_map
}

output "advanced_role_db_map" {
  value = merge({
    for name, role in var.postgresql_extra_roles :
    name => [for database, privileges in role.privileges : database]
  })
}

output "inherited_role_credentials" {
  value     = [for value in postgresql_role.inherited_role : "${value.name} : ${value.password}"]
  sensitive = true
}

output "pg_dedicated_role_credentials" {
  value     = [for value in postgresql_role.pg_dedicated_role : "${value.name} : ${value.password}"]
  sensitive = true
}

output "pg_advanced_role_credentials" {
  value     = [for value in postgresql_role.pg_advanced_role : "${value.name} : ${value.password}"]
  sensitive = true
}
