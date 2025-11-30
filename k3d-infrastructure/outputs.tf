output "cluster_name" {
  description = "The name of the k3d cluster"
  value       = var.cluster_name
}

output "k8s_version" {
  description = "Kubernetes version of the cluster"
  value       = var.k8s_version
}

output "agent_nodes_count" {
  description = "Number of worker nodes in the cluster"
  value       = var.agent_nodes_count
}

output "cluster_info" {
  description = "Information about the cluster"
  value       = "Run 'k3d cluster list' to see your cluster details"
}

output "kubeconfig_info" {
  description = "How to get kubeconfig"
  value       = "Run 'k3d kubeconfig get ${var.cluster_name} > ~/.kube/k3d-config' to save kubeconfig"
}

output "traefik_http_port" {
  description = "Traefik HTTP port mapping (host port)"
  value       = var.enable_traefik_port_mapping ? var.traefik_http_port : "disabled"
}

output "traefik_https_port" {
  description = "Traefik HTTPS port mapping (host port)"
  value       = var.enable_traefik_port_mapping ? var.traefik_https_port : "disabled"
}

output "metallb_ip_pool_range" {
  description = "IP range for MetalLB IP address pool"
  value       = "${var.metallb_ip_pool_start} - ${cidrhost(cidrsubnet("${var.metallb_ip_pool_start}/24", 0, 0), var.metallb_ip_pool_size - 1)}"
}

output "access_instructions" {
  description = "Instructions for accessing the cluster"
  value       = <<-EOT
    Cluster Setup Complete!
    
    1. Save kubeconfig:
       k3d kubeconfig get ${var.cluster_name} > ~/.kube/k3d-config
    
    2. Verify cluster:
       kubectl --kubeconfig=~/.kube/k3d-config cluster-info
    
    3. For Traefik (coming soon):
       - HTTP traffic will arrive on localhost:${var.traefik_http_port}
       - HTTPS traffic will arrive on localhost:${var.traefik_https_port}
    
    4. For MetalLB (coming soon):
       - IP pool: ${var.metallb_ip_pool_start} - ${cidrhost(cidrsubnet("${var.metallb_ip_pool_start}/24", 0, 0), var.metallb_ip_pool_size - 1)}
       - To access externally on macOS/Linux, add route:
         sudo route add -net 172.18.0.0/16 $(docker network inspect k3d-${var.cluster_name} | grep -oP '"Gateway": "\K[^"]+' | head -1)
  EOT
}
