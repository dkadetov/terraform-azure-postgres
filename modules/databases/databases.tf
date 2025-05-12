locals {
  dedicated_databases = flatten([
    for tenant in var.tenants : [
      for db in var.dedicated_databases : {
        suffixed_db_name = "${db}${tenant.db_suffix}"
        db_owner         = tenant.db_admin_role ? var.administrator_login : tenant.name
      }
    ] if length(tenant.db_suffix) > 0
  ])

  shared_databases = flatten([
    for suffix, db_list in var.shared_databases : [
      formatlist("%s_${suffix}", db_list)
    ]
  ])

  all_databases = distinct(concat(local.dedicated_databases[*].suffixed_db_name, local.shared_databases, var.extra_databases))
}

resource "postgresql_database" "dedicated_db" {
  for_each = {
    for tenant_db in local.dedicated_databases :
      tenant_db.suffixed_db_name => tenant_db
  }

  provider = postgresql.main

  name       = each.key
  owner      = each.value.db_owner
  template   = "template0"
  encoding   = "UTF8"
  lc_collate = "en_US.utf8"
  lc_ctype   = "en_US.utf8"
}

resource "postgresql_database" "shared_db" {
  for_each = toset(local.shared_databases)

  provider = postgresql.main

  name       = each.value
  owner      = var.administrator_login
  template   = "template0"
  encoding   = "UTF8"
  lc_collate = "en_US.utf8"
  lc_ctype   = "en_US.utf8"
}

resource "postgresql_database" "extra_db" {
  for_each = toset(var.extra_databases)

  provider = postgresql.main

  name       = each.value
  owner      = var.administrator_login
  template   = "template0"
  encoding   = "UTF8"
  lc_collate = "en_US.utf8"
  lc_ctype   = "en_US.utf8"
}
