variable "cluster_name" {
  description = "Name of the k3d cluster"
  type        = string
  default     = "k3d-cluster"
}

variable "k8s_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "v1.31.1"
}

variable "nodes_count" {
  description = "Number of nodes in the cluster"
  type        = number
  default     = 2
}

variable "agent_nodes_count" {
  description = "Number of agent (worker) nodes"
  type        = number
  default     = 2
}

variable "port_mapping" {
  description = "Port mapping for the cluster"
  type        = string
  default     = "8080:80@loadbalancer"
}
