#----- generic roles -----#
locals {
  generic_role_suffixes = concat(
    [for tenant in var.tenants : tenant.db_suffix if length(tenant.db_suffix) > 0],
    formatlist("_%s", keys(var.shared_databases)),
    ["_extra", "_all"]
  )
}

resource "postgresql_role" "generic_reader" {
  for_each = toset(local.generic_role_suffixes)

  provider = postgresql.main

  name      = "generic_reader${each.value}"
  login     = false
  superuser = false
  inherit   = false
}

#----- inherited roles -----#

resource "random_password" "inherited_role_password" {
  for_each = toset(keys(var.postgresql_inherited_roles))

  length           = 20
  special          = true
  override_special = "!#%*()-_=+[]{}<>:?"
}

resource "postgresql_role" "inherited_role" {
  for_each = var.postgresql_inherited_roles

  provider = postgresql.main

  name     = each.key
  password = random_password.inherited_role_password[each.key].result
  login    = true
  roles    = each.value
  inherit  = true

  depends_on = [
    random_password.inherited_role_password,
    postgresql_role.generic_reader,
    postgresql_role.pg_dedicated_role,
    postgresql_role.pg_advanced_role
  ]
}

#----- dedicated roles -----#

## generate passwords for non-admin roles
resource "random_password" "pg_dedicated_role_password" {
  for_each = toset([
    for tenant in var.tenants : tenant.name if !tenant.db_admin_role && length(tenant.db_suffix) > 0
  ])

  length           = 20
  special          = true
  override_special = "!#%*()-_=+[]{}<>:?"
}

## generate dedicated non-admin roles for each tenant depending on tenant.db_admin_role
resource "postgresql_role" "pg_dedicated_role" {
  for_each = toset([
    for tenant in var.tenants : tenant.name if !tenant.db_admin_role && length(tenant.db_suffix) > 0
  ])

  provider = postgresql.main

  name            = each.value
  superuser       = false
  create_database = false
  create_role     = false
  inherit         = false
  login           = true
  replication     = false
  skip_drop_role  = true # Set skip_drop_role to true when there are multiple databases in a PostgreSQL cluster using the same PostgreSQL ROLE for object ownership
  password        = random_password.pg_dedicated_role_password[each.value].result

  depends_on = [random_password.pg_dedicated_role_password]
}

#----- advanced extra roles -----#
resource "random_password" "pg_advanced_role_password" {
  for_each = var.postgresql_extra_roles

  length           = 20
  special          = true
  override_special = "!#%*()-_=+[]{}<>:?"
}

resource "postgresql_role" "pg_advanced_role" {
  for_each = var.postgresql_extra_roles

  provider = postgresql.main

  name            = each.key
  superuser       = each.value.superuser
  create_database = each.value.create_database
  create_role     = each.value.create_role
  inherit         = each.value.inherit
  login           = each.value.login
  replication     = each.value.replication
  roles           = each.value.roles
  password        = random_password.pg_advanced_role_password[each.key].result

  depends_on = [random_password.pg_advanced_role_password]
}
