data "azurerm_private_dns_zone" "fpsql_poc_dns_zone" {
  name                = var.fpsql_conf.private_dns_zone_name
  resource_group_name = azurerm_resource_group.fpsql_poc.name
}

data "azapi_resource_list" "fpsql_poc_a_record" {
  type      = "Microsoft.Network/privateDnsZones/A@2024-06-01"
  parent_id = data.azurerm_private_dns_zone.fpsql_poc_dns_zone.id

  response_export_values = {
    fpsql_poc_ip_address = "value[?contains(properties.fqdn, 'postgres.database.azure.com')].properties.aRecords[0].ipv4Address"
  }
}
