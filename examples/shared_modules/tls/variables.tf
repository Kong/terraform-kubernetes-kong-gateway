variable "private_key_algorithm" {
  default = "RSA"
}

variable "private_key_ecdsa_curve" {
  default = "P384"
}

variable "private_key_rsa_bits" {
  default = "2048"
}

variable "validity_period_hours" {
  default = "24"
}

variable "ca_allowed_uses" {
  default = [
    "cert_signing",
    "key_encipherment",
    "digital_signature",
  ]
}

variable "ca_common_name" {
  default = "Kong CA"
}

variable "override_common_name" {
  default = null
}

variable "namespaces" {
  default = []
}

variable "organization" {
  default = "Kong"
}

variable "certificates" {
  type = map(object({
    namespaces   = list(string)
    common_name  = string
    allowed_uses = list(string)
  }))
}
