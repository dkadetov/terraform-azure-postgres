resource "azurerm_public_ip" "fpsql_poc_pip" {
  name                = var.fpsql_pip.name
  location            = var.fpsql_pip.location
  resource_group_name = var.fpsql_pip.resource_group_name
  allocation_method   = "Static"
  domain_name_label   = var.fpsql_pip.domain_name_label
  sku                 = var.fpsql_pip.sku
  zones               = ["1", "2", "3"]

  lifecycle {
    ignore_changes = [
      tags["kubernetes-dns-label-service"],
    ]
  }
}

resource "kubernetes_service" "fpsql_poc_svc" {
  metadata {
    name      = var.fpsql_svc.name
    namespace = var.fpsql_svc.namespace

    labels = {
      "app.kubernetes.io/name"       = module.fpsql.server_name
      "app.kubernetes.io/part-of"    = module.fpsql.server_fqdn
      "app.kubernetes.io/managed-by" = "Terraform"
    }

    annotations = {
      "service.beta.kubernetes.io/azure-load-balancer-disable-tcp-reset"     = "true"
      "service.beta.kubernetes.io/azure-load-balancer-floating-ip"           = "false"
      "service.beta.kubernetes.io/azure-load-balancer-tcp-idle-timeout"      = "60"
      "service.beta.kubernetes.io/azure-load-balancer-health-probe-protocol" = "tcp"
      "service.beta.kubernetes.io/azure-load-balancer-health-probe-interval" = "5"
      "service.beta.kubernetes.io/azure-load-balancer-health-probe-number"   = "2"
    }
  }

  spec {
    type                    = "LoadBalancer"
    load_balancer_ip        = azurerm_public_ip.fpsql_poc_pip.ip_address
    session_affinity        = "None"
    external_traffic_policy = "Cluster"
    internal_traffic_policy = "Cluster"

    port {
      name        = "postgresql"
      protocol    = "TCP"
      port        = var.fpsql_svc.port
      target_port = 5432
    }
  }
}

resource "kubernetes_endpoint_slice_v1" "fpsql_poc_slice" {
  metadata {
    name      = kubernetes_service.fpsql_poc_svc.metadata[0].name
    namespace = kubernetes_service.fpsql_poc_svc.metadata[0].namespace

    labels = {
      "app.kubernetes.io/name"                 = module.fpsql.server_name
      "app.kubernetes.io/part-of"              = module.fpsql.server_fqdn
      "app.kubernetes.io/managed-by"           = "Terraform"
      "endpointslice.kubernetes.io/managed-by" = "terraform"
      "kubernetes.io/service-name"             = kubernetes_service.fpsql_poc_svc.metadata[0].name
    }
  }

  endpoint {
    addresses = data.azapi_resource_list.fpsql_poc_a_record.output.fpsql_poc_ip_address

    condition {
      ready = true
    }
  }

  port {
    name         = "postgresql"
    port         = tostring(var.fpsql_svc.port)
    protocol     = "TCP"
    app_protocol = "TCP"
  }

  address_type = "IPv4"
}
