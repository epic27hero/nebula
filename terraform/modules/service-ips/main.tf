# Module to manage static LoadBalancer IPs for services
# This ensures services always get the same external IP

resource "kubernetes_service_v1" "argocd" {
  metadata {
    name      = "argocd-server-lb"
    namespace = "argocd"
    labels = {
      app     = "argocd"
      service = "argocd-server"
    }
  }

  spec {
    type = "LoadBalancer"

    load_balancer_ip = var.argocd_ip

    selector = {
      "app.kubernetes.io/instance" = "argocd"
      "app.kubernetes.io/name"     = "argocd-server"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }

    port {
      name        = "https"
      port        = 443
      target_port = 8443
      protocol    = "TCP"
    }
  }

  depends_on = [var.argocd_namespace_exists]
}

resource "kubernetes_service_v1" "prometheus" {
  metadata {
    name      = "prometheus-lb-static"
    namespace = "monitoring"
    labels = {
      app     = "prometheus"
      service = "prometheus"
    }
  }

  spec {
    type = "LoadBalancer"

    load_balancer_ip = var.prometheus_ip

    selector = {
      "app.kubernetes.io/instance" = "prometheus"
      "app.kubernetes.io/name"     = "prometheus"
    }

    port {
      name        = "http"
      port        = 9090
      target_port = 9090
      protocol    = "TCP"
    }
  }

  depends_on = [var.monitoring_namespace_exists]
}

resource "kubernetes_service_v1" "grafana" {
  metadata {
    name      = "grafana-lb-static"
    namespace = "monitoring"
    labels = {
      app     = "grafana"
      service = "grafana"
    }
  }

  spec {
    type = "LoadBalancer"

    load_balancer_ip = var.grafana_ip

    selector = {
      "app.kubernetes.io/instance" = "grafana"
      "app.kubernetes.io/name"     = "grafana"
    }

    port {
      name        = "http"
      port        = 3000
      target_port = 3000
      protocol    = "TCP"
    }
  }

  depends_on = [var.monitoring_namespace_exists]
}

resource "kubernetes_service_v1" "fastapi" {
  metadata {
    name      = "fastapi-app-lb-static"
    namespace = "production"
    labels = {
      app     = "fastapi-app"
      service = "fastapi-app"
    }
  }

  spec {
    type = "LoadBalancer"

    load_balancer_ip = var.fastapi_ip

    selector = {
      app = "fastapi-app"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 8000
      protocol    = "TCP"
    }
  }

  depends_on = [var.production_namespace_exists]
}

resource "kubernetes_service_v1" "envoy" {
  metadata {
    name      = "envoy-gateway-lb-static"
    namespace = "gateway-system"
    labels = {
      app     = "envoy-gateway"
      service = "envoy-gateway"
    }
  }

  spec {
    type = "LoadBalancer"

    load_balancer_ip = var.envoy_ip

    selector = {
      "app.kubernetes.io/instance" = "eg"
      "app.kubernetes.io/name"     = "gateway-helm"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }

    port {
      name        = "https"
      port        = 443
      target_port = 8443
      protocol    = "TCP"
    }

    port {
      name        = "metrics"
      port        = 19001
      target_port = 19001
      protocol    = "TCP"
    }
  }

  depends_on = [var.gateway_namespace_exists]
}
