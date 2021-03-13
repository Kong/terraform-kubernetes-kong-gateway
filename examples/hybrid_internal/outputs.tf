# the following outputs are used in the test suite

output "kong-api-endpoint-ssl" {
  value = "https://kong-api-man.kong-hybrid-cp.svc.cluster.local:8444"
}

output "kong-manager-endpoint-ssl" {
  value = "https://kong-api-man.kong-hybrid-cp.svc.cluster.local:8445"
}

output "kong-proxy-endpoint-ssl" {
  value = "https://kong-proxy.kong-hybrid-dp.svc.cluster.local:8443"
}

output "kong-api-endpoint" {
  value = "http://kong-api-man.kong-hybrid-cp.svc.cluster.local:8001"
}

output "kong-manager-endpoint" {
  value = "http://kong-api-man.kong-hybrid-cp.svc.cluster.local:8002"
}

output "kong-proxy-endpoint" {
  value = "http://kong-proxy.kong-hybrid-dp.svc.cluster.local:8000"
}

output "kong-api-endpoint-ip-ssl" {
  value = "https://${local.api_ssl}"
}

output "kong-manager-endpoint-ip-ssl" {
  value = "https://${local.manager_ssl}"
}

output "kong-proxy-endpoint-ip-ssl" {
  value = "https://${local.proxy_ssl}"
}

output "kong-api-endpoint-ip" {
  value = "http://${local.api}"
}

output "kong-manager-endpoint-ip" {
  value = "http://${local.manager}"
}

output "kong-proxy-endpoint-ip" {
  value = "http://${local.proxy}"
}

output "kong-super-admin-token" {
  value = var.super_admin_password
}
