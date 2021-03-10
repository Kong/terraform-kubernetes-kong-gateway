variable "namespace" {
  description = "The name of the namespace to use for the deployment"
  type        = string
  default     = "default"
}

variable "deployment_replicas" {
  description = "How many replicas of Kong should be requested"
  type        = number
  default     = 1
}

variable "config" {
  description = "The items in this object list will be set as the environment variables to the Kong container. This is how kong is configured"
  type        = map(string)
}

variable "secret_config" {
  description = "The items in this object list will be set as the environment variables to the Kong container, However these items will take their value from a kubernetes secret. This is how kong is configured"
  type = list(object({
    name        = string
    secret_name = string
    key         = string
  }))
}

variable "kong_image" {
  description = "The name of the container image to use for the kong deployment"
  type        = string
  default     = "kong-docker-kong-enterprise-edition-docker.bintray.io/kong-enterprise-edition:2.2.0.0-alpine"
}

variable "deployment_name" {
  description = "The name to use for the container, and deployment metadata and labels"
  type        = string
  default     = "kong-enterprise"
}

variable "image_pull_secrets" {
  description = "ImagePullSecrets is an optional list of references to secrets in the same namespace to use for pulling any of the images used by this PodSpec"
  type = list(object({
    name = string
  }))
  default = [
    {
      name = "kong-enterprise-edition-docker"
    }
  ]
}

variable "load_balancer_services" {
  description = "A map that represent the kong services to expose as a LoadBalancer service in the cluster"
  type = map(object({
    namespace                   = string
    load_balancer_source_ranges = list(string)
    ports = map(object({
      port        = number
      protocol    = string
      target_port = number
    }))
  }))
  default = {}
}

variable "services" {
  description = "A map that represent the kong services to create in the cluster"
  type = map(object({
    namespace = string
    ports = map(object({
      port        = number
      protocol    = string
      target_port = number
    }))
  }))
  default = {}
}

variable "volume_mounts" {
  description = "Pod volumes to mount into the container's filesystem. Cannot be updated"
  type = list(object({
    mount_path = string
    name       = string
    read_only  = bool
  }))
  default = [
    {
      mount_path = "/etc/secrets/kong-cluster-cert"
      name       = "kong-cluster-cert"
      read_only  = true
    }
  ]
}

variable "volume_secrets" {
  description = "List of secrets to be mounted as data volumes"
  type = list(object({
    name        = string
    secret_name = string
  }))
  default = [
    {
      name        = "kong-cluster-cert"
      secret_name = "kong-cluster-cert"
    }
  ]
}

variable "service_selector" {
  description = "The label to use for our selector value"
  type        = string
  default     = "kong"
}
