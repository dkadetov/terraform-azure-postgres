locals {
  administrator_password = coalesce(var.administrator_password, try(random_password.fpsql_admin_password[0].result, ""))
}
