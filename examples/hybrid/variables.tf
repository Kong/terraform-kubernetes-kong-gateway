variable "kong_image" {
  description = "The kong container image file to use"
  type        = string
  default     = "kong-docker-kong-enterprise-edition-docker.bintray.io/kong-enterprise-edition:2.3.2.0-alpine"
}

variable "kube_config_file" {
  description = "Path to the kubernetes configuration file. Used by the terraform provider"
  type        = string
  default     = "~/.kube/config"
}

variable "docker_config_file" {
  description = "Path to the docker configuration file. Used as a kubernetes secret for accessing restricted repos"
  type        = string
  default     = "~/.docker/config.json"
}

variable "kong_license_file" {
  description = "Path to the kong license file. Used as a kubernetes secret and pass to the kong instance at run time"
  type        = string
  default     = "~/.kong_license"
}

variable "kong_control_plane_config" {
  description = "A map of strings used to define the kong control plane configuration"
  type        = map(string)
  default     = {}
}

variable "kong_data_plane_config" {
  description = "A map of strings used to define the kong data plane configuration"
  type        = map(string)
  default     = {}
}

variable "super_admin_password" {
  description = "The super user password to set"
  type        = string
}

variable "kong_database_password" {
  description = "The kong database password. used in the postgres module to set the password, and accessed via a kubernetes secret for the kong congfig"
  type        = string
}

variable "namespaces" {
  default = {
    kong-hybrid-cp = {
      name = "kong-hybrid-cp"
    },
    kong-hybrid-dp = {
      name = "kong-hybrid-dp"
    }
  }
}

variable "tls_cluster" {
  default = {
    private_key_algorithm = "ECDSA"
    ca_common_name        = "kong-cluster-ca"
    override_common_name  = "kong_clustering"
    namespaces            = ["kong-hybrid-dp"]
    certificates = {
      "kong-cluster" = {
        common_name  = null
        namespaces   = ["kong-hybrid-cp", "kong-hybrid-dp"]
        allowed_uses = null
        dns_names    = null
      }
    }
  }
}

variable "tls_services" {
  default = {
    ca_common_name = "kong-services-ca"
    namespaces     = ["kong-hybrid-cp"]
    certificates = {
      "kong-admin-api" = {
        common_name = null
        namespaces  = ["kong-hybrid-cp"]
        allowed_uses = [
          "key_encipherment",
          "digital_signature",
        ]
        dns_names = null
      },
      "kong-admin-gui" = {
        common_name = null
        namespaces  = ["kong-hybrid-cp"]
        allowed_uses = [
          "key_encipherment",
          "digital_signature",
        ]
        dns_names = null
      },
      "kong-portal-gui" = {
        common_name = null
        namespaces  = ["kong-hybrid-cp"]
        allowed_uses = [
          "key_encipherment",
          "digital_signature",
        ]
        dns_names = null
      }
      "kong-portal-api" = {
        common_name = null
        namespaces  = ["kong-hybrid-cp"]
        allowed_uses = [
          "key_encipherment",
          "digital_signature",
        ]
        dns_names = null
      },
      "kong-proxy" = {
        common_name = null
        namespaces  = ["kong-hybrid-dp"]
        allowed_uses = [
          "key_encipherment",
          "digital_signature",
        ]
        dns_names = null
      }
    }
  }
}

variable "tls_ingress" {
  default = {
    ca_common_name = null
    namespaces     = []
    certificates   = {}
  }
}


variable "dp_svcs" {
  description = "A map of objects that are used to create clusterIP services to expose Kong endpoints"
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

variable "dp_lb_svcs" {
  description = "A map of objects that are used to create LoadBalancer services to expose Kong endpoints to outside of the cluster"
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
  default = {
    "kong-proxy" = {
      namespace                   = "kong-hybrid-dp"
      load_balancer_source_ranges = ["0.0.0.0/0"]
      annotations                 = {}
      external_traffic_policy     = "Cluster"
      health_check_node_port      = null
      ports = {
        "kong-proxy" = {
          port        = 8000
          protocol    = "TCP"
          target_port = 8000
        },
        "kong-proxy-ssl" = {
          port        = 8443
          protocol    = "TCP"
          target_port = 8443
        }
      }
    }
  }
}

variable "cp_lb_svcs" {
  description = "A map of objects that are used to create LoadBalancer services to expose Kong endpoints to outside of the cluster"
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
  default = {
    "kong-api-man" = {
      namespace                   = "kong-hybrid-cp"
      load_balancer_source_ranges = ["0.0.0.0/0"]
      annotations                 = {}
      external_traffic_policy     = "Cluster"
      health_check_node_port      = null
      ports = {
        "kong-admin" = {
          port        = 8001
          protocol    = "TCP"
          target_port = 8001
        },
        "kong-manager" = {
          port        = 8002
          protocol    = "TCP"
          target_port = 8002
        },
        "kong-admin-ssl" = {
          port        = 8444
          protocol    = "TCP"
          target_port = 8444
        },
        "kong-manager-ssl" = {
          port        = 8445
          protocol    = "TCP"
          target_port = 8445
        }
      }
    }
    "kong-portal" = {
      namespace                   = "kong-hybrid-cp"
      load_balancer_source_ranges = ["0.0.0.0/0"]
      annotations                 = {}
      external_traffic_policy     = "Cluster"
      health_check_node_port      = null
      ports = {
        "kong-portal-admin" = {
          port        = 8004
          protocol    = "TCP"
          target_port = 8004
        },
        "kong-portal-gui" = {
          port        = 8003
          protocol    = "TCP"
          target_port = 8003
        },
        "kong-portal-admin-ssl" = {
          port        = 8447
          protocol    = "TCP"
          target_port = 8447
        },
        "kong-portal-gui-ssl" = {
          port        = 8446
          protocol    = "TCP"
          target_port = 8446
        }
      }
    }
  }
}

variable "cp_svcs" {
  description = "A map of objects that are used to create clusterIP services to expose Kong endpoints"
  type = map(object({
    namespace   = string
    annotations = map(string)
    ports = map(object({
      port        = number
      protocol    = string
      target_port = number
    }))
  }))
  default = {
    "kong-cluster" = {
      namespace   = "kong-hybrid-cp"
      annotations = {}
      ports = {
        "kong-cluster" = {
          port        = 8005
          protocol    = "TCP"
          target_port = 8005
        },
        "kong-telemetry" = {
          port        = 8006
          protocol    = "TCP"
          target_port = 8006
        }
      }
    }
  }
}

variable "control_plane_replicas" {
  description = "The number of control plane replicas to create"
  type        = number
  default     = 1
}

variable "data_plane_replicas" {
  description = "The number of data plane replicas to create"
  type        = number
  default     = 1
}

variable "kong_database_secret_name" {
  description = "A string used as the name of the database password kubernetes secret"
  type        = string
  default     = "kong-database-password"
}

variable "image_pull_secret_name" {
  description = "A string used as the name of the image pull kubernetes secret"
  type        = string
  default     = "kong-enterprise-edition-docker"
}

variable "kong_license_secret_name" {
  description = "A string used as the name of the kong license kubernetes secret"
  type        = string
  default     = "kong-enterprise-license"
}

variable "session_conf_secret_name" {
  description = "A string used as the name of the session conf kubernetes secret"
  type        = string
  default     = "kong-session-conf"
}

variable "gui_config_secret_key" {
  description = "A string used as the name of the gui conf kubernetes secret"
  type        = string
  default     = "admin_gui_session_conf"
}

variable "portal_config_secret_key" {
  description = "A string used as the name of the portal conf kubernetes secret"
  type        = string
  default     = "portal_session_conf"
}

variable "kong_superuser_secret_name" {
  description = "A string used as the name of the image pull kubernetes secret"
  default     = "kong-enterprise-superuser-password"
}
