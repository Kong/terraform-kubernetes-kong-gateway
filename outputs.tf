locals {
  services = {
    for name, svc in kubernetes_service.this-service :
    name => {
      for port in svc.spec.0.port :
      port.name => {
        endpoint = "${svc.spec.0.cluster_ip}:${port.port}"
        port     = svc.spec.0.port.0.port
        ip       = svc.spec.0.cluster_ip
        name     = name
      }
    }
  }

  load_balancer_services = {
    for name, svc in kubernetes_service.this-load-balancer-service :
    name => {
      for port in svc.spec.0.port :
      port.name => {
        endpoint = svc.status.0.load_balancer.0.ingress.0.hostname != "" ? "${svc.status.0.load_balancer.0.ingress.0.hostname}:${port.port}" : "${svc.status.0.load_balancer.0.ingress.0.ip}:${port.port}"
        port     = port.port
        ip       = svc.status.0.load_balancer.0.ingress.0.hostname != "" ? svc.status.0.load_balancer.0.ingress.0.hostname : svc.status.0.load_balancer.0.ingress.0.ip
        name     = name
      }
    }
  }
}

output "services" {
  value = local.services
}

output "load_balancer_services" {
  value = local.load_balancer_services
}

output "lb_raw" {
  value = kubernetes_service.this-load-balancer-service
}

output "svc_raw" {
  value = kubernetes_service.this-service
}
