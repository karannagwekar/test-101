output "cluster_name" {
  description = "The name of the k3d cluster"
  value       = k3d_cluster.main.name
}

output "k8s_version" {
  description = "Kubernetes version of the cluster"
  value       = var.k8s_version
}

output "cluster_servers" {
  description = "Number of server nodes"
  value       = k3d_cluster.main.servers
}

output "cluster_agents" {
  description = "Number of agent nodes"
  value       = k3d_cluster.main.agents
}
