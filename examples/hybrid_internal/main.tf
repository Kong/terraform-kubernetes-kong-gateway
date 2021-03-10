###########################################################
# Some prerequs for running the example:
#  a kubernetes cluster (minikube/eks) and a
#  ~/.kube/config file that enables connectivity to it
#
# Other Files In this Example:
#
# secrets_setup.tf: creates secrets in kubernetes for the kong
#                   + postgres deployments
#
# variables.tf:      variables for the kong deployment
#                   can be overriden if needed

provider "kubernetes" {
  config_path = var.kube_config_file
}

# Create two namespaces one for cp and pg and
# one for dp
resource "kubernetes_namespace" "kong" {
  for_each = var.namespaces
  metadata {
    name = each.value["name"]
  }
}

module "postgres" {
  source                     = "../shared_modules/postgres"
  namespace                  = local.cp_ns
  kong_superuser_secret_name = var.kong_superuser_secret_name
  kong_database_secret_name  = var.kong_database_secret_name
  kong_license_secret_name   = var.kong_license_secret_name
  kong_image                 = var.kong_image
}

module "tls_cluster" {
  source                = "../shared_modules/tls"
  private_key_algorithm = var.tls_cluster.private_key_algorithm
  ca_common_name        = var.tls_cluster.ca_common_name
  override_common_name  = var.tls_cluster.override_common_name # shared cluster mode needs specific common name
  namespaces            = var.tls_cluster.namespaces
  certificates          = var.tls_cluster.certificates
}

module "tls_services" {
  source         = "../shared_modules/tls"
  ca_common_name = var.tls_services.ca_common_name
  namespaces     = var.tls_services.namespaces
  certificates   = var.tls_services.certificates
}

locals {

  dp_mounts = concat(module.tls_cluster.namespace_name_map[local.dp_ns])
  cp_mounts = concat(module.tls_cluster.namespace_name_map[local.cp_ns],
  module.tls_services.namespace_name_map[local.cp_ns])

  cp_ns = kubernetes_namespace.kong["kong-hybrid-cp"].metadata[0].name
  dp_ns = kubernetes_namespace.kong["kong-hybrid-dp"].metadata[0].name

  proxy_ssl      = module.kong-dp.services["kong-proxy"]["kong-proxy-ssl"].endpoint
  api_ssl        = module.kong-cp.services["kong-api-man"]["kong-admin-ssl"].endpoint
  manager_ssl    = module.kong-cp.services["kong-api-man"]["kong-manager-ssl"].endpoint
  portal_api_ssl = module.kong-cp.services["kong-portal"]["kong-portal-admin-ssl"].endpoint
  portal_gui_ssl = module.kong-cp.services["kong-portal"]["kong-portal-gui-ssl"].endpoint

  proxy      = module.kong-dp.services["kong-proxy"]["kong-proxy"].endpoint
  api        = module.kong-cp.services["kong-api-man"]["kong-admin"].endpoint
  manager    = module.kong-cp.services["kong-api-man"]["kong-manager"].endpoint
  portal_api = module.kong-cp.services["kong-portal"]["kong-portal-admin"].endpoint
  portal_gui = module.kong-cp.services["kong-portal"]["kong-portal-gui"].endpoint

  cluster   = module.kong-cp.services["kong-cluster"]["kong-cluster"].endpoint
  telemetry = module.kong-cp.services["kong-cluster"]["kong-telemetry"].endpoint

  kong_cp_deployment_name = "kong-enterprise-cp"
  kong_dp_deployment_name = "kong-enterprise-dp"
  kong_image              = var.kong_image

  kong_image_pull_secrets = [
    {
      name = var.image_pull_secret_name
    }
  ]

  kong_dp_volume_mounts = [for p in local.dp_mounts :
    {
      mount_path = "/etc/secrets/${p}"
      name       = p
      read_only  = true
    }
  ]

  kong_dp_volume_secrets = [for p in local.dp_mounts :
    {
      name        = p
      secret_name = p
    }
  ]

  kong_cp_volume_mounts = [for p in local.cp_mounts :
    {
      mount_path = "/etc/secrets/${p}"
      name       = p
      read_only  = true
    }
  ]

  kong_cp_volume_secrets = [for p in local.cp_mounts :
    {
      name        = p
      secret_name = p
    }
  ]

  #
  # Control plane configuration 
  #
  kong_cp_secret_config = [
    {
      name        = "KONG_LICENSE_DATA"
      secret_name = var.kong_license_secret_name
      key         = var.kong_license_secret_name
    },
    {
      name        = "KONG_ADMIN_GUI_SESSION_CONF"
      secret_name = var.session_conf_secret_name
      key         = var.gui_config_secret_key
    },
    {
      name        = "KONG_PORTAL_SESSION_CONF"
      secret_name = var.session_conf_secret_name
      key         = var.portal_config_secret_key
    },
    {
      name        = "KONG_PG_PASSWORD"
      secret_name = var.kong_database_secret_name
      key         = var.kong_database_secret_name
    }
  ]

  #
  # Merge static control plane configuration
  # with dynamic service address values
  #
  kong_cp_merge_config = {
    "KONG_PG_HOST" = module.postgres.connection.ip
    "KONG_PG_PORT" = module.postgres.connection.port
  }

  kong_cp_config = merge(var.kong_control_plane_config, local.kong_cp_merge_config)

  #
  # Data plane configuration 
  #
  kong_dp_secret_config = [
    {
      name        = "KONG_LICENSE_DATA"
      secret_name = var.kong_license_secret_name
      key         = var.kong_license_secret_name
    }
  ]
  #
  # Merge static data plane configuration
  # with dynamic service address values.
  # currently no dynamic values for data plane
  #
  kong_dp_merge_config = {}
  kong_dp_config       = merge(var.kong_data_plane_config, local.kong_dp_merge_config)

}

# Use the Kong module to create a cp
module "kong-cp" {
  source                 = "../../"
  deployment_name        = local.kong_cp_deployment_name
  namespace              = local.cp_ns
  deployment_replicas    = var.control_plane_replicas
  config                 = local.kong_cp_config
  secret_config          = local.kong_cp_secret_config
  kong_image             = local.kong_image
  image_pull_secrets     = local.kong_image_pull_secrets
  volume_mounts          = local.kong_cp_volume_mounts
  volume_secrets         = local.kong_cp_volume_secrets
  services               = var.cp_svcs
  load_balancer_services = var.cp_lb_svcs
  depends_on             = [kubernetes_namespace.kong]
}

# Use the Kong module to create a dp
module "kong-dp" {
  source                 = "../../"
  deployment_name        = local.kong_dp_deployment_name
  namespace              = local.dp_ns
  deployment_replicas    = var.data_plane_replicas
  config                 = local.kong_dp_config
  secret_config          = local.kong_dp_secret_config
  kong_image             = local.kong_image
  image_pull_secrets     = local.kong_image_pull_secrets
  volume_mounts          = local.kong_dp_volume_mounts
  volume_secrets         = local.kong_dp_volume_secrets
  services               = var.dp_svcs
  load_balancer_services = var.dp_lb_svcs
  depends_on             = [kubernetes_namespace.kong]
}
