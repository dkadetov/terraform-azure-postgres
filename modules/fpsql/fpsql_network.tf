locals {
  private_dns_zone_resource_group = coalesce(var.fpsql_server_network.private_dns_zone_resource_group, var.resource_group)
  private_endpoint_resource_group = coalesce(var.fpsql_server_network.private_endpoint_resource_group, var.resource_group)
  private_endpoint_location       = coalesce(var.fpsql_server_network.private_endpoint_location, var.location)
  vnet_resource_group             = coalesce(var.fpsql_server_network.vnet_resource_group, var.resource_group)
}

data "azurerm_virtual_network" "vnet" {
  count = var.fpsql_server_network.private_dns_zone_create ? 1 : 0

  name                = var.fpsql_server_network.vnet_name
  resource_group_name = local.vnet_resource_group

}

data "azurerm_private_dns_zone" "fpsql_dns_zone" {
  count = var.fpsql_server_network.private_endpoint_create || var.fpsql_server_network.subnet_create && !var.fpsql_server_network.private_dns_zone_create ? 1 : 0

  name                = var.fpsql_server_network.private_dns_zone_name
  resource_group_name = local.private_dns_zone_resource_group
}

resource "azurerm_private_dns_zone" "fpsql_dns_zone" {
  count = var.fpsql_server_network.private_dns_zone_create ? 1 : 0

  name                = var.fpsql_server_network.private_dns_zone_name
  resource_group_name = local.private_dns_zone_resource_group
}

resource "azurerm_private_dns_zone_virtual_network_link" "fpsql_dns_vnl" {
  count = var.fpsql_server_network.private_dns_zone_create ? 1 : 0

  name                  = var.fpsql_server_network.vnet_name
  resource_group_name   = local.private_dns_zone_resource_group
  private_dns_zone_name = azurerm_private_dns_zone.fpsql_dns_zone[0].name
  virtual_network_id    = data.azurerm_virtual_network.vnet[0].id

  depends_on = [azurerm_private_dns_zone.fpsql_dns_zone]
}

resource "azurerm_private_endpoint" "fpsql_pe" {
  count = var.fpsql_server_network.private_endpoint_create ? 1 : 0

  name                          = "${var.name_prefix}-fpsql-pe"
  location                      = local.private_endpoint_location
  resource_group_name           = local.private_endpoint_resource_group
  subnet_id                     = var.fpsql_server_network.subnet_id
  custom_network_interface_name = "${var.name_prefix}-fpsql-nic"

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = var.fpsql_server_network.private_dns_zone_create ? [azurerm_private_dns_zone.fpsql_dns_zone[0].id] : [data.azurerm_private_dns_zone.fpsql_dns_zone[0].id]
  }

  private_service_connection {
    name                           = coalesce(var.fpsql_server_network.vnet_name, "${var.name_prefix}-fpsql-pe")
    is_manual_connection           = false
    private_connection_resource_id = azurerm_postgresql_flexible_server.fpsql.id
    subresource_names              = ["postgresqlServer"]
  }

  depends_on = [azurerm_postgresql_flexible_server.fpsql]
}

resource "azurerm_subnet" "fpsql_sn" {
  count = var.fpsql_server_network.subnet_create ? 1 : 0

  name                 = "${var.name_prefix}-fpsql-subnet"
  resource_group_name  = local.vnet_resource_group
  virtual_network_name = var.fpsql_server_network.vnet_name
  address_prefixes     = var.fpsql_server_network.subnet_address_prefixes
  service_endpoints    = var.fpsql_server_network.subnet_service_endpoints

  private_link_service_network_policies_enabled = var.fpsql_server_network.subnet_policies_enabled

  delegation {
    name = "${var.name_prefix}-fpsql"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}
