resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgres"
    namespace = var.namespace
  }
  spec {
    port {
      name        = "pgql"
      port        = 5432
      protocol    = "TCP"
      target_port = 5432
    }
    selector = {
      app = kubernetes_stateful_set.postgres.metadata.0.labels.app
    }
  }
}

locals {
  pg_ip   = kubernetes_service.postgres.spec.0.cluster_ip
  pg_port = kubernetes_service.postgres.spec.0.port.0.port
}

resource "kubernetes_stateful_set" "postgres" {
  metadata {
    name      = "postgres"
    namespace = var.namespace
    labels = {
      app = "postgres"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "postgres"
      }
    }
    service_name = "postgres"
    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }
      spec {
        container {
          env {
            name  = "POSTGRES_USER"
            value = "kong"
          }
          env {
            name  = "POSTGRES_PASSWORD"
            value = "kong"
          }
          env {
            name  = "POSTGRES_DB"
            value = "kong"
          }
          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }
          image = "postgres:9.5"
          name  = "postgres"
          port {
            container_port = 5432
          }
          #          volume_mount {
          #            mount_path = "/var/lib/postgresql/data"
          #            name       = "datadir"
          #            sub_path   = "pgdata"
          #          }
        }
        termination_grace_period_seconds = 60
      }
    }
    #    volume_claim_template {
    #      metadata {
    #        name = "datadir"
    #      }
    #      spec {
    #        access_modes = ["ReadWriteOnce"]
    #        resources {
    #          requests = {
    #            storage = "16Gi"
    #          }
    #        }
    #      }
    #    }
  }
}

resource "kubernetes_job" "demo" {
  metadata {
    name      = "kong-migrations"
    namespace = var.namespace
  }
  spec {
    template {
      metadata {
        name = "kong-migrations"
      }
      spec {
        image_pull_secrets {
          name = "kong-enterprise-edition-docker"
        }
        restart_policy = "OnFailure"
        init_container {
          name  = "wait-for-postgres"
          image = "busybox"
          command = [
            "/bin/sh",
            "-c",
            "until nc -zv $KONG_PG_HOST $KONG_PG_PORT -w1; do echo 'waiting for db'; sleep 1; done"
          ]
          env {
            name  = "KONG_PG_HOST"
            value = local.pg_ip
          }
          env {
            name  = "KONG_PG_PORT"
            value = local.pg_port
          }
        }
        container {
          image = var.kong_image
          name  = "kong-migrations"
          command = [
            "/bin/sh",
            "-c",
            "kong migrations bootstrap"
          ]
          env {
            name = "KONG_LICENSE_DATA"
            value_from {
              secret_key_ref {
                key  = var.kong_license_secret_name
                name = var.kong_license_secret_name
              }
            }
          }
          env {
            name = "KONG_PASSWORD"
            value_from {
              secret_key_ref {
                key  = var.kong_superuser_secret_name
                name = var.kong_superuser_secret_name
              }
            }
          }
          env {
            name = "KONG_PG_PASSWORD"
            value_from {
              secret_key_ref {
                key  = var.kong_database_secret_name
                name = var.kong_database_secret_name
              }
            }
          }
          env {
            name  = "KONG_DATABASE"
            value = "postgres"
          }
          env {
            name  = "KONG_PG_HOST"
            value = local.pg_ip
          }
          env {
            name  = "KONG_PG_USER"
            value = "kong"
          }
          env {
            name  = "KONG_PG_DATABASE"
            value = "kong"
          }
          env {
            name  = "KONG_PORT"
            value = local.pg_port
          }
        }
      }
    }
  }
}
