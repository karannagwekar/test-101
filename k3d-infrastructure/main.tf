resource "k3d_cluster" "main" {
  name            = var.cluster_name
  servers         = 1
  agents          = var.agent_nodes_count
  image           = "rancher/k3s:${var.k8s_version}"
  network         = "k3d-network"
  wait            = true
  disable         = ["traefik"]

  port {
    host      = 8080
    container = 80
    protocol  = "TCP"
  }

  port {
    host      = 6443
    container = 6443
    protocol  = "TCP"
  }

  label {
    key   = "environment"
    value = "development"
  }

  env {
    key   = "K3S_DEBUG"
    value = "false"
  }
}
