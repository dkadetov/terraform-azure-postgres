#----- generic role privileges -----#
locals {
  dedicated_role_db_map = {
    for tenant in var.tenants : "generic_reader${tenant.db_suffix}" => formatlist("%s${tenant.db_suffix}", var.dedicated_databases) if length(tenant.db_suffix) > 0
  }

  generic_role_db_map = merge(
    local.dedicated_role_db_map,
    {
      for suffix, db_list in var.shared_databases :
      "generic_reader_${suffix}" => distinct(concat(formatlist("%s_${suffix}", db_list), lookup(local.dedicated_role_db_map, "generic_reader_${suffix}", [])))
    },
    tomap({
      "generic_reader_extra" = var.extra_databases,
      "generic_reader_all"   = local.all_databases
    })
  )
}

resource "postgresql_grant" "generic_reader_table_privileges" {
  for_each = merge([
    for role, db_list in local.generic_role_db_map : {
      for db in db_list : "${role}/${db}" => {
        role     = role,
        database = db
      }
    }
  ]...)

  provider = postgresql.main

  role              = each.value.role
  database          = each.value.database
  schema            = "public"
  object_type       = "table"
  privileges        = ["SELECT"]
  with_grant_option = true

  depends_on = [
    postgresql_role.generic_reader,
    postgresql_database.dedicated_db,
    postgresql_database.shared_db,
    postgresql_database.extra_db
  ]
}

resource "postgresql_grant" "generic_reader_schema_privileges" {
  for_each = merge([
    for role, db_list in local.generic_role_db_map : {
      for db in db_list : "${role}/${db}" => {
        role     = role,
        database = db
      }
    }
  ]...)

  provider = postgresql.main

  role              = each.value.role
  database          = each.value.database
  schema            = "public"
  object_type       = "schema"
  privileges        = ["USAGE"]
  with_grant_option = true

  depends_on = [
    postgresql_role.generic_reader,
    postgresql_database.dedicated_db,
    postgresql_database.shared_db,
    postgresql_database.extra_db
  ]
}

#----- advanced extra role privileges -----#

resource "postgresql_grant" "advanced_role_privileges" {
  for_each = merge([
    for name, role in var.postgresql_extra_roles :
      merge([
        for database, privileges in role.privileges : {
          for privilege in privileges : "${name}/${database}/${privilege.schema}/${privilege.object_type}" => {
            role        = name,
            database    = database,
            schema      = privilege.schema,
            object_type = privilege.object_type,
            objects     = privilege.objects,
            privileges  = privilege.privileges
          }
        }
      ]...)
  ]...)

  provider = postgresql.main

  role        = each.value.role
  database    = each.value.database
  schema      = each.value.schema
  object_type = each.value.object_type
  objects     = each.value.objects
  privileges  = each.value.privileges

  depends_on = [
    postgresql_role.pg_advanced_role,
    postgresql_database.dedicated_db,
    postgresql_database.shared_db,
    postgresql_database.extra_db
  ]
}

#----- default schema privilege for extra roles -----#

resource "postgresql_grant" "advanced_role_default_schema_privilege" {
  for_each = merge([
    for name, role in var.postgresql_extra_roles :
      merge([
        for database, privileges in role.privileges : {
          for privilege in privileges : "${name}/${database}/${privilege.schema}/schema" => {
            role        = name,
            database    = database,
            schema      = privilege.schema,
            object_type = "schema",
            privileges  = ["USAGE"]
          }
        } if !contains(privileges[*].object_type, "schema")
      ]...)
  ]...)

  provider = postgresql.main

  role        = each.value.role
  database    = each.value.database
  schema      = each.value.schema
  object_type = each.value.object_type
  privileges  = each.value.privileges

  depends_on = [
    postgresql_role.pg_advanced_role,
    postgresql_database.dedicated_db,
    postgresql_database.shared_db,
    postgresql_database.extra_db
  ]
}
