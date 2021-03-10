resource "kubernetes_secret" "kong_enterprise_docker_cfg-cp" {
  for_each = var.namespaces
  metadata {
    name      = var.image_pull_secret_name
    namespace = kubernetes_namespace.kong[each.value["name"]].metadata[0].name
  }

  data = {
    ".dockerconfigjson" = file(var.docker_config_file)
  }

  type = "kubernetes.io/dockerconfigjson"
}

resource "kubernetes_secret" "license-cp" {
  for_each = var.namespaces
  metadata {
    name      = var.kong_license_secret_name
    namespace = kubernetes_namespace.kong[each.value["name"]].metadata[0].name
  }

  type = "Opaque"
  data = {
    (var.kong_license_secret_name) = file(var.kong_license_file)
  }
}


resource "kubernetes_secret" "kong-enterprise-superuser-password" {
  metadata {
    name      = var.kong_superuser_secret_name
    namespace = kubernetes_namespace.kong["kong-hybrid-cp"].metadata[0].name
  }

  type = "Opaque"
  data = {
    (var.kong_superuser_secret_name) = var.super_admin_password
  }
}

resource "kubernetes_secret" "kong-session-conf" {
  metadata {
    name      = var.session_conf_secret_name
    namespace = kubernetes_namespace.kong["kong-hybrid-cp"].metadata[0].name
  }

  type = "Opaque"
  data = {
    (var.gui_config_secret_key)    = file("${path.module}/.session_conf/admin_gui_session_conf")
    (var.portal_config_secret_key) = file("${path.module}/.session_conf/portal_session_conf")
  }
}

resource "kubernetes_secret" "kong-database-password" {
  metadata {
    name      = var.kong_database_secret_name
    namespace = kubernetes_namespace.kong["kong-hybrid-cp"].metadata[0].name
  }

  type = "Opaque"
  data = {
    (var.kong_database_secret_name) = var.kong_database_password
  }
}
