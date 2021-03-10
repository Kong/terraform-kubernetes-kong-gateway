output "connection" {
  value = {
    ip       = kubernetes_service.postgres.spec.0.cluster_ip
    port     = kubernetes_service.postgres.spec.0.port.0.port
    endpoint = "${kubernetes_service.postgres.spec.0.cluster_ip}:${kubernetes_service.postgres.spec.0.port.0.port}"
  }
}
