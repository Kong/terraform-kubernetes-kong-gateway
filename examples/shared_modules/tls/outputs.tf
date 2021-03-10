output "ca_cert" {
  value = tls_self_signed_cert.this-ca.cert_pem
}

output "ca_key" {
  value = tls_private_key.this-ca.private_key_pem
}

output "cert" {
  value = tls_locally_signed_cert.this-cert
}

output "key" {
  value = tls_private_key.this-key
}

output "namespace_name_map" {
  value = local.ns_map
}
