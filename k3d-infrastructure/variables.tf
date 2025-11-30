variable "cluster_name" {
  description = "Name of the k3d cluster"
  type        = string
  default     = "k3d-cluster"
}

variable "k8s_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "v1.31.1-k3s1"
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

variable "enable_traefik_port_mapping" {
  description = "Enable port mappings for Traefik ingress controller"
  type        = bool
  default     = true
}

variable "traefik_http_port" {
  description = "Host port for Traefik HTTP (80 inside container)"
  type        = number
  default     = 8080

  validation {
    condition     = var.traefik_http_port > 1024 && var.traefik_http_port < 65535
    error_message = "Traefik HTTP port must be between 1024 and 65535."
  }
}

variable "traefik_https_port" {
  description = "Host port for Traefik HTTPS (443 inside container)"
  type        = number
  default     = 8443

  validation {
    condition     = var.traefik_https_port > 1024 && var.traefik_https_port < 65535
    error_message = "Traefik HTTPS port must be between 1024 and 65535."
  }
}

variable "metallb_ip_pool_start" {
  description = "Starting IP address for MetalLB IP pool"
  type        = string
  default     = "172.18.0.200"

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", var.metallb_ip_pool_start))
    error_message = "metallb_ip_pool_start must be a valid IP address."
  }
}

variable "metallb_ip_pool_size" {
  description = "Number of IP addresses in the MetalLB pool"
  type        = number
  default     = 50

  validation {
    condition     = var.metallb_ip_pool_size > 0 && var.metallb_ip_pool_size <= 255
    error_message = "metallb_ip_pool_size must be between 1 and 255."
  }
}
