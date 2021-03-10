# optional: this module can create cluster services for you
# if you pass it a list of service objects. see variables for
# details
resource "kubernetes_service" "this-service" {
  for_each = var.services
  metadata {
    name      = each.key
    namespace = each.value.namespace
  }
  spec {
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
      app = var.deployment_name
    }
  }
}

# optional: this module can create load balancer services for you
# if you pass it a list of service objects. see variables for
# details
resource "kubernetes_service" "this-load-balancer-service" {
  for_each = var.load_balancer_services
  metadata {
    name      = each.key
    namespace = each.value.namespace
  }
  spec {
    type                        = "LoadBalancer"
    load_balancer_source_ranges = each.value.load_balancer_source_ranges
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
      app = var.deployment_name
    }
  }
}

# standard kong kubernetes deployment.
resource "kubernetes_deployment" "this-kong-deployment" {
  metadata {
    name      = var.deployment_name
    namespace = var.namespace
  }
  spec {
    selector {
      match_labels = {
        app = var.deployment_name
      }
    }
    replicas = var.deployment_replicas
    template {
      metadata {
        labels = {
          name = var.deployment_name
          app  = var.deployment_name
        }
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

        container {
          name  = var.deployment_name
          image = var.kong_image
          # The module takes a list of config
          # maps as var.config. This dynamic
          # block will iterate over that list and
          # add the items as environment variables
          # to each pod
          dynamic "env" {
            for_each = var.config
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
        }
      }
    }
  }
}
