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
    annotations = map(string)
    labels      = map(string)
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

variable "services" {
  description = "A map that represent the kong services to create in the cluster"
  type = map(object({
    annotations = map(string)
    labels      = map(string)
    type        = string
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

variable "volume_kong_mounts" {
  description = "Pod volumes to mount into the container's filesystem. These allow kong to run with a read only root"
  type = list(object({
    mount_path = string
    name       = string
    read_only  = bool
  }))
  default = [
    {
      mount_path = "/tmp"
      name       = "kong-tmp"
      read_only  = false
    },
    {
      mount_path = "/kong_prefix"
      name       = "kong-prefix"
      read_only  = false
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

variable "deployment_annotations" {
  description = "A map of annotation to apply to this deployment"
  type        = map(string)
  default     = {}
}

variable "cpu_limit" {
  description = "The pod cpu limit to set"
  type        = string
  default     = "250m"
}

variable "memory_limit" {
  description = "The pod memory limit to set"
  type        = string
  default     = "500Mi"
}

variable "cpu_request" {
  description = "The pod cpu request to set"
  type        = string
  default     = "250m"
}

variable "memory_request" {
  description = "The pod memory request to set"
  type        = string
  default     = "500Mi"
}

variable "status_path" {
  description = "The path to use on the status endpoint"
  type        = string
  default     = "/status"
}

variable "liveness_initial_delay_seconds" {
  description = "Number of seconds after the container has started before liveness probes are initiated"
  type        = number
  default     = 5
}

variable "liveness_timeout_seconds" {
  description = "Number of seconds after which the probe times out. For more info see"
  type        = number
  default     = 5
}

variable "liveness_period_seconds" {
  description = "How often (in seconds) to perform the probe"
  type        = number
  default     = 10
}

variable "liveness_success_threshold" {
  description = "Minimum consecutive successes for the probe to be considered successful after having failed"
  type        = number
  default     = 1
}

variable "liveness_failure_threshold" {
  description = "Minimum consecutive failures for the probe to be considered failed after having succeeded"
  type        = number
  default     = 3
}

variable "readiness_initial_delay_seconds" {
  description = "Number of seconds after the container has started before readiness probes are initiated"
  type        = number
  default     = 5
}

variable "readiness_timeout_seconds" {
  description = "Number of seconds after which the probe times out. For more info see"
  type        = number
  default     = 5
}

variable "readiness_period_seconds" {
  description = "How often (in seconds) to perform the probe"
  type        = number
  default     = 10
}

variable "readiness_success_threshold" {
  description = "Minimum consecutive successes for the probe to be considered successful after having failed"
  type        = number
  default     = 1
}

variable "readiness_failure_threshold" {
  description = "Minimum consecutive failures for the probe to be considered failed after having succeeded"
  type        = number
  default     = 3
}

########### Autoscaling settings #################

variable "enable_autoscaler" {
  description = "Should we enable horizontal pod autoscaling"
  type        = bool
  default     = false
}

variable "autoscaler_min_replicas" {
  description = "Minimum number of replicas to run"
  type        = number
  default     = 2
}

variable "autoscaler_max_replicas" {
  description = "Maximum number of replicas to run"
  type        = number
  default     = 5
}

variable "average_cpu_utilization" {
  description = "The threashold of cpu utilization at which we trigger auto scaling"
  type        = number
  default     = 80
}

########### Termination settings #################

variable "termination_grace_period_seconds" {
  description = "The number of secods to wait before terminating the pod"
  type        = number
  default     = 40
}

variable "pre_stop_command" {
  description = "The command to run just before terminating kong"
  type        = list(string)
  default     = ["/bin/sh", "-c", "/bin/sleep 15 && kong quit"]
}

########### Labels ###############################

variable "use_global_labels" {
  description = "If set to true the content from global_labels will be set as labels on all resources"
  type        = bool
  default     = true
}

variable "global_labels" {
  description = "Labels to apply to all resources if use_global_labels is set to true"
  type        = map(string)
  default     = {}
}

variable "deployment_labels" {
  description = "Labels to apply to the deployment"
  type        = map(string)
  default     = {}
}

variable "pod_labels" {
  description = "Labels to apply to the pods deployed by this deployment"
  type        = map(string)
  default     = {}
}

variable "autoscaler_labels" {
  description = "Labels to apply to the autoscale used by this deployment (if enabled)"
  type        = map(string)
  default     = {}
}

########### Security Context #####################

variable "pod_security_context" {
  description = "The security contexts to set for this deployments pods"
  type = object({
    fs_group            = string
    run_as_group        = string
    run_as_non_root     = bool
    run_as_user         = string
    supplemental_groups = list(string)
  })
  default = {
    fs_group            = null
    run_as_group        = 65533
    run_as_non_root     = true
    run_as_user         = 100
    supplemental_groups = null
  }
}

variable "container_security_context" {
  description = "The security contexts to set for this deployments containers"
  type = object({
    allow_privilege_escalation = bool
    capabilities = object({
      add  = list(string)
      drop = list(string)
    })
    privileged                = bool
    read_only_root_filesystem = bool
    run_as_group              = string
    run_as_non_root           = bool
    run_as_user               = string
  })
  default = {
    allow_privilege_escalation = null
    capabilities = {
      add  = []
      drop = ["all"]
    }
    privileged                = false
    read_only_root_filesystem = true
    run_as_group              = 65533
    run_as_non_root           = true
    run_as_user               = 100
  }
}

########### Filesystem ###########################

variable "kong_prefix" {
  description = "The path on the filesystem to use for the kong prefix"
  type        = string
  default     = "/kong_prefix"
}

########### Config Maps ##########################

variable "config_map_env" {
  description = "Map of config maps to use as env vars"
  type        = map(string)
  default     = {}
}
