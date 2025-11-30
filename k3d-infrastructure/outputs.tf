output "cluster_name" {
  description = "The name of the k3d cluster"
  value       = var.cluster_name
}

output "k8s_version" {
  description = "Kubernetes version of the cluster"
  value       = var.k8s_version
}

output "cluster_info" {
  description = "Information about the cluster"
  value       = "Run 'k3d cluster list' to see your cluster details"
}

output "kubeconfig_info" {
  description = "How to get kubeconfig"
  value       = "Run 'k3d kubeconfig get ${var.cluster_name}' to get kubeconfig"
}
