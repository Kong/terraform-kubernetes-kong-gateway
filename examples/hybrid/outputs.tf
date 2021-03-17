# the following outputs are used in the test suite

output "kong-admin-endpoint" {
  value = local.admin
}

output "kong-manager-endpoint" {
  value = local.manager
}

output "kong-portal-admin-endpoint" {
  value = local.portal_admin
}

output "kong-portal-gui-endpoint" {
  value = local.portal_gui
}

output "kong-proxy-endpoint" {
  value = local.proxy
}

output "kong-super-admin-token" {
  value = var.super_admin_password
}
