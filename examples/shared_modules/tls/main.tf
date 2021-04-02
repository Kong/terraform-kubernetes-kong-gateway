resource "tls_private_key" "this-ca" {
  algorithm   = var.private_key_algorithm
  ecdsa_curve = var.private_key_ecdsa_curve
  rsa_bits    = var.private_key_rsa_bits
}

resource "tls_self_signed_cert" "this-ca" {
  key_algorithm     = tls_private_key.this-ca.algorithm
  private_key_pem   = tls_private_key.this-ca.private_key_pem
  is_ca_certificate = true

  validity_period_hours = var.validity_period_hours
  allowed_uses          = var.ca_allowed_uses

  subject {
    common_name  = var.override_common_name != null ? var.override_common_name : var.ca_common_name
    organization = var.organization
  }

}

resource "kubernetes_secret" "this-ca-secret" {
  count = length(var.namespaces)
  metadata {
    name      = var.ca_common_name
    namespace = var.namespace_map[var.namespaces[count.index]]
  }

  data = {
    "tls.crt" = tls_self_signed_cert.this-ca.cert_pem
    "tls.key" = tls_private_key.this-ca.private_key_pem
  }

  type = "kubernetes.io/tls"
}

resource "tls_private_key" "this-key" {
  for_each    = var.certificates
  algorithm   = var.private_key_algorithm
  ecdsa_curve = var.private_key_ecdsa_curve
  rsa_bits    = var.private_key_rsa_bits
}

resource "tls_cert_request" "this-cert-request" {
  for_each = var.certificates

  key_algorithm   = tls_private_key.this-key[each.key].algorithm
  private_key_pem = tls_private_key.this-key[each.key].private_key_pem

  subject {
    common_name  = lookup(each.value, "common_name", null) != null ? each.value.common_name : var.override_common_name != null ? var.override_common_name : each.key
    organization = var.organization
  }
}

resource "tls_locally_signed_cert" "this-cert" {
  for_each         = var.certificates
  cert_request_pem = tls_cert_request.this-cert-request[each.key].cert_request_pem

  ca_key_algorithm   = tls_private_key.this-ca.algorithm
  ca_private_key_pem = tls_private_key.this-ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.this-ca.cert_pem

  validity_period_hours = var.validity_period_hours
  allowed_uses = each.value.allowed_uses != null ? each.value.allowed_uses : [
  ]
}

locals {
  ca_ns_map = { for k in var.namespaces :
    (k) => [var.ca_common_name]
  }

  # create a list of the namespaces in the certificates hash
  cert_ns_list = distinct(flatten([for k, v in var.certificates :
    [
      for x in v.namespaces : x
    ]
  ]))

  # map the certificate namespaces to the certificate name if the name
  # is included in the namespace array
  cert_ns_map = { for k in local.cert_ns_list :
    (k) => [for x, y in var.certificates : x if contains(y.namespaces, k)]...
  }

  # create a list of certificate names concated with namespace
  cert_ns_name = flatten([for k, v in var.certificates :
    [
      for x in v.namespaces :
      [
        "${var.namespace_map[x]},${k}"
      ]
    ]
  ])


  # collect the information of secretes mapped to namespace
  # for both ca and certs combined

  map_tmp_1 = { for x, y in local.ca_ns_map :
    x => distinct(flatten(concat(y, lookup(local.cert_ns_map, x, []))))
  }

  map_tmp_2 = { for x, y in local.cert_ns_map :
    x => distinct(flatten(concat(y, lookup(local.map_tmp_1, x, []))))
  }

  ns_map = merge(local.map_tmp_1, local.map_tmp_2)

  #  ns = { for x, y in loca.ns_map :
  #    x => y
  #  }

}

resource "kubernetes_secret" "this-cert-secret" {
  count = length(local.cert_ns_name)
  metadata {
    name      = split(",", local.cert_ns_name[count.index])[1]
    namespace = split(",", local.cert_ns_name[count.index])[0]
  }

  data = {
    "tls.crt" = tls_locally_signed_cert.this-cert[split(",", local.cert_ns_name[count.index])[1]].cert_pem
    "tls.key" = tls_private_key.this-key[split(",", local.cert_ns_name[count.index])[1]].private_key_pem
  }

  type = "kubernetes.io/tls"
}
