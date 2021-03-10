locals {
  kong_ns = [local.cp_ns, local.dp_ns]
  cp_ns   = var.cp_ns
  dp_ns   = var.dp_ns
  cm_ns   = var.cm_ns
}

resource "helm_release" "cert-manager" {
  name       = var.cert_manager_chart.name
  repository = var.cert_manager_chart.repository
  chart      = var.cert_manager_chart.chart
  version    = var.cert_manager_chart.version

  namespace = local.cm_ns
  values    = []

  dynamic "set" {
    for_each = var.cert_manager_chart.values
    content {
      name  = set.key
      value = set.value.value
      type  = set.value.type != null ? set.value.type : "auto"
    }
  }
  provisioner "local-exec" {
    command = "sleep 30"
  }
}

resource "kubernetes_manifest" "selfsigned-root-issuer" {
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "cert-manager.io/v1alpha2"
    "kind"       = "Issuer"
    "metadata" = {
      "name"      = "selfsigned-issuer"
      "namespace" = local.cm_ns
    }
    "spec" = {
      "selfSigned" = {}
    }
  }
}

resource "kubernetes_manifest" "selfsigned-root-ca" {
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "cert-manager.io/v1alpha2"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "selfsigned-root-ca"
      "namespace" = local.cm_ns
    }
    "spec" = {
      "secretName" = "selfsigned-root-ca"
      "commonName" = "selfsigned root ca"
      "isCA"       = true
      "issuerRef" = {
        "name" = "selfsigned-issuer"
      }
    }
  }
}

resource "kubernetes_manifest" "root-ca-issuer" {
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "cert-manager.io/v1alpha2"
    "kind"       = "Issuer"
    "metadata" = {
      "name"      = "ca-issuer"
      "namespace" = local.cm_ns
    }
    "spec" = {
      "ca" = {
        "secretName" = "selfsigned-root-ca"
      }
    }
  }
}

resource "kubernetes_manifest" "intermediate1" {
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "cert-manager.io/v1alpha2"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "int1"
      "namespace" = local.cm_ns
    }
    "spec" = {
      "secretName" = "intermediate1"
      "commonName" = "Intermediate 1"
      "isCA"       = true
      "issuerRef" = {
        "name" = "ca-issuer"
      }
    }
  }
}

resource "kubernetes_manifest" "intermediate1-issuer" {
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "cert-manager.io/v1alpha2"
    "kind"       = "Issuer"
    "metadata" = {
      "name"      = "intermediate1-issuer"
      "namespace" = local.cm_ns
    }
    "spec" = {
      "ca" = {
        "secretName" = "intermediate1"
      }
    }
  }
}

resource "kubernetes_manifest" "intermediate2" {
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "cert-manager.io/v1alpha2"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "int2"
      "namespace" = local.cm_ns
    }
    "spec" = {
      "secretName" = "intermediate2"
      "commonName" = "Intermediate 2"
      "isCA"       = true
      "issuerRef" = {
        "name" = "intermediate1-issuer"
      }
    }
  }
}

resource "kubernetes_manifest" "intermediate2-issuer" {
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "cert-manager.io/v1alpha2"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name"      = "intermediate2-issuer"
      "namespace" = local.cm_ns
    }
    "spec" = {
      "ca" = {
        "secretName" = "intermediate2"
      }
    }
  }
}

resource "kubernetes_manifest" "kong-cluster-cp" {
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "kong-cluster-cp-inter"
      "namespace" = local.cp_ns
    }
    "spec" = {
      "dnsNames" = [
        "kong-cluster.kong-hybrid-cp.svc.cluster.local",
      ]
      "duration"    = "240h"
      "renewBefore" = "48h"
      "isCA"        = false
      "issuerRef" = {
        "name" = "intermediate2-issuer"
        "kind" = "ClusterIssuer"
      }
      "secretName" = "kong-cluster-cp"
      "subject" = {
        "organizations" = [
          "kong-cp",
        ]
      }
      "usages" = [
        "server auth",
      ]
    }
  }
}

resource "kubernetes_manifest" "kong-cluster-dp" {
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "kong-cluster-dp"
      "namespace" = local.dp_ns
    }
    "spec" = {
      "dnsNames" = [
        "kong-cluster.kong-hybrid-cp.svc.cluster.local",
      ]
      "duration" = "240h"
      "isCA"     = false
      "issuerRef" = {
        "name" = "intermediate2-issuer"
        "kind" = "ClusterIssuer"
      }
      "privateKey" = {
        "algorithm" = "RSA"
        "encoding"  = "PKCS1"
        "size"      = 2048
      }
      "renewBefore" = "48h"
      "secretName"  = "kong-cluster-dp"
      "subject" = {
        "organizations" = [
          "kong-dp",
        ]
      }
      "usages" = [
        "client auth",
      ]
    }
  }
}

data "kubernetes_secret" "selfsigned-root-ca" {
  metadata {
    name      = "selfsigned-root-ca"
    namespace = local.cm_ns
  }
}

data "kubernetes_secret" "int2-ca" {
  metadata {
    name      = "intermediate2"
    namespace = local.cm_ns
  }
}

data "kubernetes_secret" "ca-bundle" {
  metadata {
    name      = "ca-bundle"
    namespace = local.cp_ns
  }
}

output "ca-bundle" {
  value = data.kubernetes_secret.selfsigned-root-ca.data
}

output "int2-ca" {
  value = data.kubernetes_secret.int2-ca.data
}
