resource "terraform_data" "pg_aad_role" {
  for_each = var.postgresql_aad_roles

  input = {
    server_host = var.postgresql_server_host,
    server_user = var.postgresql_aad_administrator_login,
    role_name   = length(each.value.role_name) > 0 ? each.value.role_name : each.key,
    is_admin    = each.value.is_admin,
    is_mfa      = each.value.is_mfa
  }

  provisioner "local-exec" {
    quiet       = false
    on_failure  = fail # continue
    environment = {
      PGHOST     = self.input.server_host
      PGPORT     = "5432"
      PGSSLMODE  = "require"
      PGDATABASE = "postgres"
      PGUSER     = self.input.server_user
      ROLENAME   = self.input.role_name
      ISADMIN    = self.input.is_admin
      ISMFA      = self.input.is_mfa
    }
    command = <<-EOT
      if [ -z $PGPASSWORD ]; then
        export PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms --query "[accessToken]" -o tsv)
      fi

      if $ISADMIN; then
        aadRoleList=$(psql -tAq -c "SELECT rolname FROM pg_catalog.pgaadauth_list_principals(true);")
      else
        aadRoleList=$(psql -tAq -c "SELECT rolname FROM pg_catalog.pgaadauth_list_principals(false);")
      fi

      if grep -q $ROLENAME <<< $aadRoleList; then
        echo "ERROR: rolname = \"$ROLENAME\" already exist"
        exit 1
      else
        psql -tAq -c "SELECT * FROM pg_catalog.pgaadauth_create_principal('$ROLENAME', $ISADMIN, $ISMFA)"
      fi
    EOT
  }

  provisioner "local-exec" {
    quiet       = false
    on_failure  = fail # continue
    when        = destroy
    environment = {
      PGHOST     = self.input.server_host
      PGPORT     = "5432"
      PGSSLMODE  = "require"
      PGDATABASE = "postgres"
      PGUSER     = self.input.server_user
      ROLENAME   = self.input.role_name
    }
    command = <<-EOT
      if [ -z $PGPASSWORD ]; then
        export PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms --query "[accessToken]" -o tsv)
      fi

      psql -c "DROP ROLE IF EXISTS \"$ROLENAME\";"
    EOT
  }
}

resource "postgresql_grant_role" "pg_aad_grant_role" {
  for_each = merge([
    for name, role in var.postgresql_aad_roles : {
      for grant_role in role.grant_roles : "${name}/${grant_role}" => length(role.role_name) > 0 ? merge(role, { grant_role = "${grant_role}" }) : merge(role, { role_name = "${name}", grant_role = "${grant_role}" })
    }
  ]...)

  provider = postgresql.main

  role              = each.value.role_name
  grant_role        = each.value.grant_role
  with_admin_option = each.value.is_admin

  depends_on = [terraform_data.pg_aad_role]
}

resource "postgresql_security_label" "pg_aad_role_mapping" {
  for_each = var.postgresql_aad_role_mapping

  provider = postgresql.aad

  object_type    = "role"
  object_name    = length(each.value.role_name) > 0 ? each.value.role_name : each.key
  label_provider = "pgaadauth"
  label          = "aadauth,oid=${each.value.object_id},type=${each.value.object_type}"
}
