#----- aad role privileges -----#

resource "postgresql_grant" "aad_role_privileges" {
  for_each = merge([
    for name, role in var.postgresql_aad_roles :
      merge([
        for database, privileges in role.privileges : {
          for privilege in privileges : "${name}/${database}/${privilege.schema}/${privilege.object_type}" => {
            role        = length(role.role_name) > 0 ? role.role_name : name,
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

  depends_on = [terraform_data.pg_aad_role]
}

#----- default schema privilege for aad roles -----#

resource "postgresql_grant" "aad_role_default_schema_privilege" {
  for_each = merge([
    for name, role in var.postgresql_aad_roles :
      merge([
        for database, privileges in role.privileges : {
          for privilege in privileges : "${name}/${database}/${privilege.schema}/schema" => {
            role        = length(role.role_name) > 0 ? role.role_name : name,
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

  depends_on = [terraform_data.pg_aad_role]
}
