locals {
  cluster_ip_services = {
    for name, svc in kubernetes_service.this-service :
    name => {
      for port in svc.spec.0.port :
      port.name => {
        endpoint = "${svc.spec.0.cluster_ip}:${port.port}"
        port     = svc.spec.0.port.0.port
        ip       = svc.spec.0.cluster_ip
        name     = port.name
      }
    }
  }

  load_balancer_services = {
    for name, svc in kubernetes_service.this-load-balancer-service :
    name => {
      for port in svc.spec.0.port :
      port.name => {
        endpoint = svc.status.0.load_balancer.0.ingress.0.hostname != "" ? "${svc.status.0.load_balancer.0.ingress.0.hostname}:${port.port}" : "${svc.status.0.load_balancer.0.ingress.0.ip}:${port.port}"
        port     = port.port
        ip       = svc.status.0.load_balancer.0.ingress.0.hostname != "" ? svc.status.0.load_balancer.0.ingress.0.hostname : svc.status.0.load_balancer.0.ingress.0.ip
        name     = port.name
      }
    }
  }
  tmp_services = merge(local.cluster_ip_services, local.load_balancer_services)
  services = flatten([
    for k, v in local.tmp_services :
    [
      for x, y in v :
      y
    ]
  ])

  proxy_endpoint = flatten([
    for item in local.services :
    lookup(item, "endpoint", "") if lookup(item, "name", "") == var.service_name_map.kong_proxy
  ])

  proxy_ssl_endpoint = flatten([
    for item in local.services :
    lookup(item, "endpoint", "") if lookup(item, "name", "") == var.service_name_map.kong_proxy_ssl
  ])

  admin_endpoint = flatten([
    for item in local.services :
    lookup(item, "endpoint", "") if lookup(item, "name", "") == var.service_name_map.kong_admin
  ])

  admin_ssl_endpoint = flatten([
    for item in local.services :
    lookup(item, "endpoint", "") if lookup(item, "name", "") == var.service_name_map.kong_admin_ssl
  ])

  manager_endpoint = flatten([
    for item in local.services :
    lookup(item, "endpoint", "") if lookup(item, "name", "") == var.service_name_map.kong_manager
  ])

  manager_ssl_endpoint = flatten([
    for item in local.services :
    lookup(item, "endpoint", "") if lookup(item, "name", "") == var.service_name_map.kong_manager_ssl
  ])

  portal_admin_endpoint = flatten([
    for item in local.services :
    lookup(item, "endpoint", "") if lookup(item, "name", "") == var.service_name_map.kong_portal_admin
  ])

  portal_admin_ssl_endpoint = flatten([
    for item in local.services :
    lookup(item, "endpoint", "") if lookup(item, "name", "") == var.service_name_map.kong_portal_admin_ssl
  ])

  portal_gui_endpoint = flatten([
    for item in local.services :
    lookup(item, "endpoint", "") if lookup(item, "name", "") == var.service_name_map.kong_portal_gui
  ])

  portal_gui_ssl_endpoint = flatten([
    for item in local.services :
    lookup(item, "endpoint", "") if lookup(item, "name", "") == var.service_name_map.kong_portal_gui_ssl
  ])

  cluster_endpoint = flatten([
    for item in local.services :
    lookup(item, "endpoint", "") if lookup(item, "name", "") == var.service_name_map.kong_cluster
  ])

  telemetry_endpoint = flatten([
    for item in local.services :
    lookup(item, "endpoint", "") if lookup(item, "name", "") == var.service_name_map.kong_telemetry
  ])

  proxy_http        = length(local.proxy_endpoint) > 0 ? tolist(local.proxy_endpoint).0 : ""
  proxy_ssl         = length(local.proxy_ssl_endpoint) > 0 ? tolist(local.proxy_ssl_endpoint).0 : ""
  admin_http        = length(local.admin_endpoint) > 0 ? tolist(local.admin_endpoint).0 : ""
  admin_ssl         = length(local.admin_ssl_endpoint) > 0 ? tolist(local.admin_ssl_endpoint).0 : ""
  manager_http      = length(local.manager_endpoint) > 0 ? tolist(local.manager_endpoint).0 : ""
  manager_ssl       = length(local.manager_ssl_endpoint) > 0 ? tolist(local.manager_ssl_endpoint).0 : ""
  portal_admin_http = length(local.portal_admin_endpoint) > 0 ? tolist(local.portal_admin_endpoint).0 : ""
  portal_admin_ssl  = length(local.portal_admin_ssl_endpoint) > 0 ? tolist(local.portal_admin_ssl_endpoint).0 : ""
  portal_gui_http   = length(local.portal_gui_endpoint) > 0 ? tolist(local.portal_gui_endpoint).0 : ""
  portal_gui_ssl    = length(local.portal_gui_ssl_endpoint) > 0 ? tolist(local.portal_gui_ssl_endpoint).0 : ""
  cluster_ws        = length(local.cluster_endpoint) > 0 ? tolist(local.cluster_endpoint).0 : ""
  telemetry_ws      = length(local.telemetry_endpoint) > 0 ? tolist(local.telemetry_endpoint).0 : ""


  proxy        = lookup(var.config, "KONG_PROXY_URL", "") != "" ? lookup(var.config, "KONG_PROXY_URL", "") : local.proxy_ssl != "" ? "https://${local.proxy_ssl}" : "http://${local.proxy_http}"
  admin        = lookup(var.config, "KONG_ADMIN_API_URL", "") != "" ? lookup(var.config, "KONG_ADMIN_API_URL", "") : local.admin_ssl != "" ? "https://${local.admin_ssl}" : "http://${local.admin_http}"
  manager      = lookup(var.config, "KONG_ADMIN_GUI_URL", "") != "" ? lookup(var.config, "KONG_ADMIN_GUI_URL", "") : local.manager_ssl != "" ? "https://${local.manager_ssl}" : "http://${local.manager_http}"
  portal_admin = lookup(var.config, "KONG_PORTAL_API_URL", "") != "" ? lookup(var.config, "KONG_PORTAL_API_URL", "") : local.portal_admin_ssl != "" ? "https://${local.portal_admin_ssl}" : "http://${local.portal_admin_http}"
  portal_gui   = lookup(var.config, "KONG_PORTAL_GUI_HOST", "") != "" ? lookup(var.config, "KONG_PORTAL_GUI_HOST", "") : local.portal_gui_ssl != "" ? local.portal_gui_ssl : local.portal_gui_http

  cluster   = local.cluster_ws
  telemetry = local.telemetry_ws

}

output "services" {
  value = local.services
}

output "load_balancer_services" {
  value = local.load_balancer_services
}

output "lb_raw" {
  value = kubernetes_service.this-load-balancer-service
}

output "svc_raw" {
  value = kubernetes_service.this-service
}

output "proxy_endpoint" {
  value = local.proxy
}

output "proxy_http_endpoint" {
  value = local.proxy_http
}

output "proxy_ssl_endpoint" {
  value = local.proxy_ssl
}

output "admin_endpoint" {
  value = local.admin
}

output "admin_http_endpoint" {
  value = local.admin_http
}

output "admin_ssl_endpoint" {
  value = local.admin_ssl
}

output "manager_endpoint" {
  value = local.manager
}

output "manager_http_endpoint" {
  value = local.manager_http
}

output "manager_ssl_endpoint" {
  value = local.manager_ssl
}

output "portal_admin_endpoint" {
  value = local.portal_admin
}

output "portal_admin_http_endpoint" {
  value = local.portal_admin_http
}

output "portal_admin_ssl_endpoint" {
  value = local.portal_admin_ssl
}

output "portal_gui_endpoint" {
  value = local.portal_gui
}

output "portal_gui_http_endpoint" {
  value = local.portal_gui_http
}

output "portal_gui_ssl_endpoint" {
  value = local.portal_gui_ssl
}

output "cluster_endpoint" {
  value = local.cluster
}

output "telemetry_endpoint" {
  value = local.telemetry
}
