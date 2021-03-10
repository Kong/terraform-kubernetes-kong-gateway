variable "cp_ns" {}
variable "dp_ns" {}
variable "cm_ns" {}

variable "cert_manager_chart" {
  default = {
    version    = "1.2.0"
    name       = "cert-manager-release"
    repository = "https://charts.jetstack.io"
    chart      = "cert-manager"
    values = {
      "installCRDs" = {
        value = "true"
        type  = null
      }
    }
  }
}
