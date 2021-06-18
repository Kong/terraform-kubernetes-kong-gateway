locals {
  # Data structure for all services
  s_map = {
    for name, svc in kubernetes_service.this-service :
    name => {
      for port in svc.spec.0.port :
      port.name => {
        endpoint = "${svc.spec.0.cluster_ip}:${port.port}"
        port     = port.port
        ip       = svc.spec.0.cluster_ip
        name     = port.name
      }
    }
  }

  # Data structure for all ingress based services
  i_map = {
    for name, svc in kubernetes_ingress.this-ingress :
    name => {
      for rule in svc.spec.0.rule :
      rule.http.0.path.0.backend.0.service_name => {
        endpoint = svc.status.0.load_balancer.0.ingress.0.hostname != "" ? svc.status.0.load_balancer.0.ingress.0.hostname : svc.status.0.load_balancer.0.ingress.0.ip
        port     = length(svc.spec.0.tls) > 0 ? 443 : 80
        ip       = svc.status.0.load_balancer.0.ingress.0.hostname != "" ? svc.status.0.load_balancer.0.ingress.0.hostname : svc.status.0.load_balancer.0.ingress.0.ip
        name     = length(svc.spec.0.tls) > 0 ? "${rule.http.0.path.0.backend.0.service_name}-ssl" : rule.http.0.path.0.backend.0.service_name
      }
    }
  }

  services = flatten([
    for k, v in local.s_map :
    [
      for x, y in v :
      y
    ]
  ])

  # We also flatten the Ingress nested hash and
  # create a new hash keyed off rule name
  ingress = flatten([
    for k, v in local.i_map :
    [
      for x, y in v :
      y
    ]
  ])


  # The flattened lists hashes keyed off port name and rule name
  # are used to look up the correct service and use it as an output
  # from this module, The names of the ports / rules need to follow
  # the structure in the variable service_name_map in variables.tf

  ########## Look up ingress endpoints #############

  proxy_ingress_endpoint = flatten([
    for item in local.ingress :
    lookup(item, "endpoint", "") if lookup(item, "name", "") == var.service_name_map.kong_proxy
  ])

  proxy_ssl_ingress_endpoint = flatten([
    for item in local.ingress :
    lookup(item, "endpoint", "") if lookup(item, "name", "") == var.service_name_map.kong_proxy_ssl
  ])

  admin_ingress_endpoint = flatten([
    for item in local.ingress :
    lookup(item, "endpoint", "") if lookup(item, "name", "") == var.service_name_map.kong_admin
  ])

  admin_ssl_ingress_endpoint = flatten([
    for item in local.ingress :
    lookup(item, "endpoint", "") if lookup(item, "name", "") == var.service_name_map.kong_admin_ssl
  ])

  manager_ingress_endpoint = flatten([
    for item in local.ingress :
    lookup(item, "endpoint", "") if lookup(item, "name", "") == var.service_name_map.kong_manager
  ])

  manager_ssl_ingress_endpoint = flatten([
    for item in local.ingress :
    lookup(item, "endpoint", "") if lookup(item, "name", "") == var.service_name_map.kong_manager_ssl
  ])

  portal_admin_ingress_endpoint = flatten([
    for item in local.ingress :
    lookup(item, "endpoint", "") if lookup(item, "name", "") == var.service_name_map.kong_portal_admin
  ])

  portal_admin_ssl_ingress_endpoint = flatten([
    for item in local.ingress :
    lookup(item, "endpoint", "") if lookup(item, "name", "") == var.service_name_map.kong_portal_admin_ssl
  ])

  portal_gui_ingress_endpoint = flatten([
    for item in local.ingress :
    lookup(item, "endpoint", "") if lookup(item, "name", "") == var.service_name_map.kong_portal_gui
  ])

  portal_gui_ssl_ingress_endpoint = flatten([
    for item in local.ingress :
    lookup(item, "endpoint", "") if lookup(item, "name", "") == var.service_name_map.kong_portal_gui_ssl
  ])

  cluster_ingress_endpoint = flatten([
    for item in local.ingress :
    lookup(item, "endpoint", "") if lookup(item, "name", "") == var.service_name_map.kong_cluster
  ])

  telemetry_ingress_endpoint = flatten([
    for item in local.ingress :
    lookup(item, "endpoint", "") if lookup(item, "name", "") == var.service_name_map.kong_telemetry
  ])

  ########## Look up service endpoints #############

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


  # Once we have local variables for all endpoint types
  # we create a further set of variables, that represents the final state
  # of our endpoints, there is a hierarchy to the way we decide which endpoint to
  # return. If a service has ingress defined we favour that before either
  # ClusterIP or LoadBalancer services.

  proxy_http        = length(local.proxy_ingress_endpoint) > 0 ? tolist(local.proxy_ingress_endpoint).0 : length(local.proxy_endpoint) > 0 ? tolist(local.proxy_endpoint).0 : ""
  proxy_ssl         = length(local.proxy_ssl_ingress_endpoint) > 0 ? tolist(local.proxy_ssl_ingress_endpoint).0 : length(local.proxy_ssl_endpoint) > 0 ? tolist(local.proxy_ssl_endpoint).0 : ""
  admin_http        = length(local.admin_ingress_endpoint) > 0 ? tolist(local.admin_ingress_endpoint).0 : length(local.admin_endpoint) > 0 ? tolist(local.admin_endpoint).0 : ""
  admin_ssl         = length(local.admin_ssl_ingress_endpoint) > 0 ? tolist(local.admin_ssl_ingress_endpoint).0 : length(local.admin_ssl_endpoint) > 0 ? tolist(local.admin_ssl_endpoint).0 : ""
  manager_http      = length(local.manager_ingress_endpoint) > 0 ? tolist(local.manager_ingress_endpoint).0 : length(local.manager_endpoint) > 0 ? tolist(local.manager_endpoint).0 : ""
  manager_ssl       = length(local.manager_ssl_ingress_endpoint) > 0 ? tolist(local.manager_ssl_ingress_endpoint).0 : length(local.manager_ssl_endpoint) > 0 ? tolist(local.manager_ssl_endpoint).0 : ""
  portal_admin_http = length(local.portal_admin_ingress_endpoint) > 0 ? tolist(local.portal_admin_ingress_endpoint).0 : length(local.portal_admin_endpoint) > 0 ? tolist(local.portal_admin_endpoint).0 : ""
  portal_admin_ssl  = length(local.portal_admin_ssl_ingress_endpoint) > 0 ? tolist(local.portal_admin_ssl_ingress_endpoint).0 : length(local.portal_admin_ssl_endpoint) > 0 ? tolist(local.portal_admin_ssl_endpoint).0 : ""
  portal_gui_http   = length(local.portal_gui_ingress_endpoint) > 0 ? tolist(local.portal_gui_ingress_endpoint).0 : length(local.portal_gui_endpoint) > 0 ? tolist(local.portal_gui_endpoint).0 : ""
  portal_gui_ssl    = length(local.portal_gui_ssl_ingress_endpoint) > 0 ? tolist(local.portal_gui_ssl_ingress_endpoint).0 : length(local.portal_gui_ssl_endpoint) > 0 ? tolist(local.portal_gui_ssl_endpoint).0 : ""
  cluster_ws        = length(local.cluster_endpoint) > 0 ? tolist(local.cluster_endpoint).0 : length(local.cluster_endpoint) > 0 ? tolist(local.cluster_endpoint).0 : ""
  telemetry_ws      = length(local.telemetry_endpoint) > 0 ? tolist(local.telemetry_endpoint).0 : length(local.telemetry_endpoint) > 0 ? tolist(local.telemetry_endpoint).0 : ""

  # This set of variables also returns the different services endpoints, only this time
  # it takes into account if the configuration contains any URL or URI overrides for the
  # service. Once again there is a hierarchy, if found we return fist the config URL or URI
  # override, if there is no URL or URI override we check to see if the service endpoint has an ssl
  # endpoint defined. If it does we return that as a https url, if not then we return the http version
  # of the endpoint as a http url. This should always give the user of the module a sensible value

  proxy               = lookup(var.config, "KONG_PROXY_URL", "") != "" ? lookup(var.config, "KONG_PROXY_URL", "") : local.proxy_ssl != "" ? "https://${local.proxy_ssl}" : "http://${local.proxy_http}"
  admin               = lookup(var.config, "KONG_ADMIN_API_URI", "") != "" ? lookup(var.config, "KONG_ADMIN_API_URI", "") : local.admin_ssl != "" ? "https://${local.admin_ssl}" : "http://${local.admin_http}"
  manager             = lookup(var.config, "KONG_ADMIN_GUI_URL", "") != "" ? lookup(var.config, "KONG_ADMIN_GUI_URL", "") : local.manager_ssl != "" ? "https://${local.manager_ssl}" : "http://${local.manager_http}"
  portal_admin        = lookup(var.config, "KONG_PORTAL_API_URL", "") != "" ? lookup(var.config, "KONG_PORTAL_API_URL", "") : local.portal_admin_ssl != "" ? "https://${local.portal_admin_ssl}" : "http://${local.portal_admin_http}"
  portal_gui          = lookup(var.config, "KONG_PORTAL_GUI_HOST", "") != "" ? lookup(var.config, "KONG_PORTAL_GUI_HOST", "") : local.portal_gui_ssl != "" ? local.portal_gui_ssl : local.portal_gui_http
  portal_gui_url      = lookup(var.config, "KONG_PORTAL_GUI_HOST", "") != "" ? lookup(var.config, "KONG_PORTAL_GUI_HOST", "") : local.portal_gui_ssl != "" ? "https://${local.portal_gui_ssl}" : "http://${local.portal_gui_http}"
  portal_gui_protocol = lookup(var.config, "KONG_PORTAL_GUI_PROTOCOL", "") != "" ? lookup(var.config, "KONG_PORTAL_GUI_PROTOCOL", "") : local.portal_gui_ssl != "" ? "https" : "http"

  cluster   = local.cluster_ws
  telemetry = local.telemetry_ws
}


# After getting the service endpoint variables in
# the right shape we present them as outputs to this
# module

########### URL outputs ##########################

# This set of outputs presents the service endpoint as
# a URL. HTTP or HTTPS is worked out automatically

output "proxy_endpoint" {
  value = local.proxy
}

output "admin_endpoint" {
  value = local.admin
}

output "manager_endpoint" {
  value = local.manager
}

output "portal_admin_endpoint" {
  value = local.portal_admin
}

output "portal_gui_endpoint" {
  value = local.portal_gui
}

output "cluster_endpoint" {
  value = local.cluster
}

output "telemetry_endpoint" {
  value = local.telemetry
}

########### HTTP outputs #########################

# This set of variables presents the service endpoint
# dedicated for http traffic, if one is defined

output "proxy_http_endpoint" {
  value = local.proxy_http
}

output "admin_http_endpoint" {
  value = local.admin_http
}

output "manager_http_endpoint" {
  value = local.manager_http
}

output "portal_admin_http_endpoint" {
  value = local.portal_admin_http
}

output "portal_gui_http_endpoint" {
  value = local.portal_gui_http
}

########### HTTPS outputs ########################

# This set of variables presents the service endpoint
# dedicated for https traffic, if one is defined

output "proxy_ssl_endpoint" {
  value = local.proxy_ssl
}

output "admin_ssl_endpoint" {
  value = local.admin_ssl
}

output "manager_ssl_endpoint" {
  value = local.manager_ssl
}

output "portal_admin_ssl_endpoint" {
  value = local.portal_admin_ssl
}

output "portal_gui_ssl_endpoint" {
  value = local.portal_gui_ssl
}

# These outputs are just for debugging
# if needed

output "ingress" {
  value = local.ingress
}

output "services" {
  value = local.services
}

output "svc_raw" {
  value = kubernetes_service.this-service
}
