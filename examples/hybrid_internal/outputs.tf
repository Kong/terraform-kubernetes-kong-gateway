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

output "kong-super-admin-token" {
  value = var.super_admin_password
}
