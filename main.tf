locals {

  # If the module user has not specified the URL or URI config
  # options we can fill them in at this point. The Kubernetes
  # Services and ingress resources are created before the deployment.
  # So we can use there values to populate the Kong deployment configuration.
  admin_gui_map           = lookup(var.config, "KONG_ADMIN_GUI_URL", "") == "" ? { "KONG_ADMIN_GUI_URL" = local.manager } : {}
  admin_api_map           = lookup(var.config, "KONG_ADMIN_API_URI", "") == "" ? { "KONG_ADMIN_API_URI" = local.admin } : {}
  portal_api_map          = lookup(var.config, "KONG_PORTAL_API_URL", "") == "" ? { "KONG_PORTAL_API_URL" = local.portal_admin } : {}
  portal_gui_map          = lookup(var.config, "KONG_PORTAL_GUI_HOST", "") == "" ? { "KONG_PORTAL_GUI_HOST" = local.portal_gui } : {}
  portal_gui_url_map      = lookup(var.config, "KONG_PORTAL_GUI_URL", "") == "" ? { "KONG_PORTAL_GUI_URL" = local.portal_gui_url } : {}
  portal_gui_protocol_map = lookup(var.config, "KONG_PORTAL_GUI_PROTOCOL", "") == "" ? { "KONG_PORTAL_GUI_PROTOCOL" = local.portal_gui_protocol } : {}
  proxy_map               = lookup(var.config, "KONG_PROXY_URL", "") == "" ? { "KONG_PROXY_URL" = local.proxy } : {}
  kong_prefix             = lookup(var.config, "KONG_PREFIX", "") == "" ? { "KONG_PREFIX" = var.kong_prefix } : {}

  # If the module user has specified these values then we return an empty hash
  # so the config merge below is a no-op
  config = merge(
    var.config,
    local.admin_gui_map,
    local.admin_api_map,
    local.portal_api_map,
    local.portal_gui_map,
    local.portal_gui_url_map,
    local.portal_gui_protocol_map,
    local.proxy_map,
    local.kong_prefix
  )

  # Get the status enpoint details, used for the readiness and liveness
  # probes
  # TODO: return these as module outputs maybe?
  status_port   = split(" ", split(":", lookup(var.config, "KONG_STATUS_LISTEN", "0.0.0.0:8100"))[1])[0]
  status_scheme = length(split(" ", lookup(var.config, "KONG_STATUS_LISTEN", "0.0.0.0:8100"))) > 1 ? "HTTPS" : "HTTP"

  std_labels        = { "kong-app" = var.deployment_name, "kong-deployment-name" = var.deployment_name }
  append_labels     = var.use_global_labels ? merge(var.global_labels, local.std_labels) : local.std_labels
  deployment_labels = merge(var.deployment_labels, local.append_labels)
  pod_labels        = merge(var.pod_labels, local.append_labels)
  autoscaler_labels = merge(var.autoscaler_labels, local.append_labels)
}

# optional: this module can create cluster services for you
# if you pass it a list of service objects. see variables for
# details
resource "kubernetes_ingress" "this-ingress" {
  for_each               = var.ingress
  wait_for_load_balancer = true
  metadata {
    name        = each.key
    namespace   = var.namespace
    annotations = each.value.annotations
    labels      = each.value.labels
  }
  spec {
    tls {
      hosts       = each.value.tls.hosts
      secret_name = each.value.tls.secret_name
    }
    dynamic "rule" {
      for_each = each.value.rules
      content {
        host = rule.value.host
        http {
          dynamic "path" {
            for_each = rule.value.paths
            content {
              path = path.key
              backend {
                service_name = path.value.service_name
                service_port = path.value.service_port
              }
            }
          }
        }
      }
    }
  }
}

# optional: this module can create cluster services for you
# if you pass it a list of service objects. see variables for
# details
resource "kubernetes_service" "this-service" {
  for_each = var.services
  metadata {
    name        = each.key
    namespace   = var.namespace
    annotations = each.value.annotations
    labels      = each.value.labels
  }
  spec {
    type = each.value.type
    dynamic "port" {
      for_each = each.value.ports
      content {
        name        = port.key
        port        = port.value.port
        protocol    = port.value.protocol
        target_port = port.value.target_port
      }
    }
    selector = {
      kong-app = var.deployment_name
    }
  }
}

# Autoscaling settings
resource "kubernetes_horizontal_pod_autoscaler" "this-autoscaler" {
  count = var.enable_autoscaler ? 1 : 0
  metadata {
    name      = var.deployment_name
    namespace = var.namespace
    labels    = local.autoscaler_labels
  }

  spec {
    min_replicas = var.autoscaler_min_replicas
    max_replicas = var.autoscaler_max_replicas

    scale_target_ref {
      api_version = "apps/v2beta2"
      kind        = "Deployment"
      name        = var.deployment_name
    }

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.average_cpu_utilization
        }
      }
    }
  }
}

# standard kong kubernetes deployment.
resource "kubernetes_deployment" "this-kong-deployment" {
  metadata {
    name      = var.deployment_name
    namespace = var.namespace
    labels    = local.deployment_labels
  }
  spec {
    selector {
      match_labels = {
        kong-app = var.deployment_name
      }
    }
    replicas = var.enable_autoscaler ? null : var.deployment_replicas
    template {
      metadata {
        annotations = var.deployment_annotations
        labels      = local.pod_labels
      }

      spec {
        # if a list is specified for image pull secrets we will create them here.
        # only one item is expected in the list
        dynamic "image_pull_secrets" {
          for_each = var.image_pull_secrets
          content {
            name = image_pull_secrets.value.name
          }
        }

        # A list of volumes to be created form k8
        # secrets can be passed to this module
        # This block will dynamically add the volumes in that
        # list to the volumes avaiable to each pod. These
        # volumes will then need to be specifed in the
        # volume mounts to make them accessible to
        # the pod
        dynamic "volume" {
          for_each = toset(var.volume_secrets)
          content {
            name = volume.value.name
            secret {
              secret_name = volume.value.secret_name
            }
          }
        }

        # In order to run with a read only root
        # filesystem we need to mount some external
        # volumes
        dynamic "volume" {
          for_each = toset(var.volume_kong_mounts)
          content {
            name = volume.value.name
            empty_dir {}
          }
        }

        termination_grace_period_seconds = var.termination_grace_period_seconds
        security_context {
          fs_group            = var.pod_security_context.fs_group
          run_as_group        = var.pod_security_context.run_as_group
          run_as_non_root     = var.pod_security_context.run_as_non_root
          run_as_user         = var.pod_security_context.run_as_user
          supplemental_groups = var.pod_security_context.supplemental_groups
        }
        container {
          security_context {
            allow_privilege_escalation = var.container_security_context.allow_privilege_escalation
            capabilities {
              add  = var.container_security_context.capabilities.add
              drop = var.container_security_context.capabilities.drop
            }
            privileged                = var.container_security_context.privileged
            read_only_root_filesystem = var.container_security_context.read_only_root_filesystem
            run_as_group              = var.container_security_context.run_as_group
            run_as_non_root           = var.container_security_context.run_as_non_root
            run_as_user               = var.container_security_context.run_as_user
          }

          name  = var.deployment_name
          image = var.kong_image
          # The module takes a list of config
          # maps as var.config. This dynamic
          # block will iterate over that list and
          # add the items as environment variables
          # to each pod
          dynamic "env" {
            for_each = local.config
            content {
              name  = env.key
              value = env.value
            }
          }
          # The module takes a list of secret config
          # objects as var.secret_config. This dynamic
          # block will iterate over that list and
          # add the items as environment variables
          # to each pod. The values will be pulled from
          # kubernetes secrets
          dynamic "env" {
            for_each = var.secret_config
            content {
              name = env.value.name
              value_from {
                secret_key_ref {
                  name = env.value.secret_name
                  key  = env.value.key
                }
              }
            }
          }
          # The module takes a list of config map
          # objects as var.config_map_env. This dynamic
          # block will iterate over that list and
          # add the items as environment variables
          # to each pod. The values will be pulled from
          # kubernetes config maps
          dynamic "env" {
            for_each = var.config_map_env
            content {
              name = env.value.name
              value_from {
                config_map_key_ref {
                  name = env.key
                  key  = env.value
                }
              }
            }
          }
          # A list of volumes can be passed to this module
          # This block will dynamically add the volumes in that
          # list to each pod
          dynamic "volume_mount" {
            for_each = toset(var.volume_mounts)
            content {
              mount_path = volume_mount.value.mount_path
              name       = volume_mount.value.name
              read_only  = volume_mount.value.read_only
            }
          }

          # A list of default kong volumes
          # these enable kong to run with a
          # read only root fs
          dynamic "volume_mount" {
            for_each = toset(var.volume_kong_mounts)
            content {
              mount_path = volume_mount.value.mount_path
              name       = volume_mount.value.name
              read_only  = volume_mount.value.read_only
            }
          }
          resources {
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
          }
          lifecycle {
            pre_stop {
              exec {
                command = var.pre_stop_command
              }
            }
          }

          dynamic "liveness_probe" {
            for_each = lookup(var.config, "KONG_STATUS_LISTEN", "") != "" ? ["liveness_probe"] : []
            content {
              dynamic "http_get" {
                for_each = lookup(var.config, "KONG_STATUS_LISTEN", "") != "" ? ["http_get"] : []
                content {
                  path   = var.status_path
                  port   = local.status_port
                  scheme = local.status_scheme
                }
              }
              initial_delay_seconds = var.liveness_initial_delay_seconds
              timeout_seconds       = var.liveness_timeout_seconds
              period_seconds        = var.liveness_period_seconds
              success_threshold     = var.liveness_success_threshold
              failure_threshold     = var.liveness_failure_threshold
            }
          }

          dynamic "readiness_probe" {
            for_each = lookup(var.config, "KONG_STATUS_LISTEN", "") != "" ? ["readiness_probe"] : []
            content {
              dynamic "http_get" {
                for_each = lookup(var.config, "KONG_STATUS_LISTEN", "") != "" ? ["http_get"] : []
                content {
                  path   = var.status_path
                  port   = local.status_port
                  scheme = local.status_scheme
                }
              }
              initial_delay_seconds = var.readiness_initial_delay_seconds
              timeout_seconds       = var.readiness_timeout_seconds
              period_seconds        = var.readiness_period_seconds
              success_threshold     = var.readiness_success_threshold
              failure_threshold     = var.readiness_failure_threshold
            }
          }
        }
      }
    }
  }
}
