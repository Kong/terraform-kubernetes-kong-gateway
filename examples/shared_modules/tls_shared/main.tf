resource "tls_private_key" "ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm     = tls_private_key.ca.algorithm
  private_key_pem   = tls_private_key.ca.private_key_pem
  is_ca_certificate = true

  validity_period_hours = "12"
  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature",
  ]

  subject {
    common_name = "kong_clustering"
  }

}

resource "tls_private_key" "cert" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_cert_request" "cert" {
  key_algorithm   = tls_private_key.cert.algorithm
  private_key_pem = tls_private_key.cert.private_key_pem

  subject {
    common_name = "kong_clustering"
  }
}

resource "tls_locally_signed_cert" "cert" {
  cert_request_pem = tls_cert_request.cert.cert_request_pem

  ca_key_algorithm   = tls_private_key.ca.algorithm
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = "12"
  allowed_uses = [
  ]

}


resource "kubernetes_secret" "cluster-tls-cp" {
  metadata {
    name      = "kong-cluster-cert"
    namespace = var.cp_namespace
  }

  data = {
    "tls.crt" = tls_locally_signed_cert.cert.cert_pem
    "tls.key" = tls_private_key.cert.private_key_pem
  }

  type = "kubernetes.io/tls"
}

resource "kubernetes_secret" "cluster-tls-dp" {
  metadata {
    name      = "kong-cluster-cert"
    namespace = var.dp_namespace
  }

  data = {
    "tls.crt" = tls_locally_signed_cert.cert.cert_pem
    "tls.key" = tls_private_key.cert.private_key_pem
  }

  type = "kubernetes.io/tls"
}

resource "kubernetes_secret" "ca-tls-dp" {
  metadata {
    name      = "cluster-ca-cert"
    namespace = var.dp_namespace
  }

  data = {
    "tls.crt" = tls_self_signed_cert.ca.cert_pem
    "tls.key" = tls_self_signed_cert.ca.private_key_pem
  }

  type = "kubernetes.io/tls"
}

variable "dp_namespace" {}
variable "cp_namespace" {}

output "namespace_name_map" {
  value = {
    "kong-hybrid-cp" = ["kong-cluster-cert"],
    "kong-hybrid-dp" = ["kong-cluster-cert", "cluster-ca-cert"]
  }
}
