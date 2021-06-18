# the following outputs are used in the test suite

output "kong-api-endpoint-ip" {
  value = "http://${module.kong-cp.admin_http_endpoint}"
}

output "kong-manager-endpoint-ip" {
  value = "http://${module.kong-cp.manager_http_endpoint}"
}

output "kong-proxy-endpoint-ip" {
  value = "http://${module.kong-dp.proxy_http_endpoint}"
}

output "kong-super-admin-token" {
  value = var.super_admin_password
}
