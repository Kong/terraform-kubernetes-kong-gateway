# the following outputs are used in the test suite

output "kong-api-endpoint-ssl" {
  value = "https://${local.api_ssl}"
}

output "kong-manager-endpoint-ssl" {
  value = "https://${local.manager_ssl}"
}

output "kong-proxy-endpoint-ssl" {
  value = "https://${local.proxy_ssl}"
}

output "kong-api-endpoint" {
  value = "http://${local.api}"
}

output "kong-manager-endpoint" {
  value = "http://${local.manager}"
}

output "kong-proxy-endpoint" {
  value = "http://${local.proxy}"
}
output "kong-super-admin-token" {
  value = var.super_admin_password
}
