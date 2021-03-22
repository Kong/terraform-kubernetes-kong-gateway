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

variable "service_name_map" {
  description = "A map of service to serivce names, used to construct the endpoint output for each service"
  type = object({
    kong_proxy            = string
    kong_proxy_ssl        = string
    kong_admin            = string
    kong_admin_ssl        = string
    kong_manager          = string
    kong_manager_ssl      = string
    kong_portal_admin     = string
    kong_portal_admin_ssl = string
    kong_portal_gui       = string
    kong_portal_gui_ssl   = string
    kong_cluster          = string
    kong_telemetry        = string
  })
  default = {
    kong_proxy            = "kong-proxy"
    kong_proxy_ssl        = "kong-proxy-ssl"
    kong_admin            = "kong-admin"
    kong_admin_ssl        = "kong-admin-ssl"
    kong_manager          = "kong-manager"
    kong_manager_ssl      = "kong-manager-ssl"
    kong_portal_admin     = "kong-portal-admin"
    kong_portal_admin_ssl = "kong-portal-admin-ssl"
    kong_portal_gui       = "kong-portal-gui"
    kong_portal_gui_ssl   = "kong-portal-gui-ssl"
    kong_cluster          = "kong-cluster"
    kong_telemetry        = "kong-telemetry"
  }
}

variable "ingress" {
  description = "A map that represents kubernetes ingress resources"
  type = map(object({
    namespace   = string
    annotations = map(string)
    tls = object({
      hosts       = list(string)
      secret_name = string
    })
    rules = map(object({
      host = string
      paths = map(object({
        service_name = string
        service_port = number
      }))
    }))
  }))
  default = {}
}

variable "load_balancer_services" {
  description = "A map that represent the kong services to expose as a LoadBalancer service in the cluster"
  type = map(object({
    namespace                   = string
    load_balancer_source_ranges = list(string)
    annotations                 = map(string)
    external_traffic_policy     = string
    health_check_node_port      = number
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
    namespace   = string
    annotations = map(string)
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
