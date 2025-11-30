variable "kubeconfig_path" {
  description = "Path to kubeconfig file for the target cluster (e.g., ~/.kube/config for k3d or ~/.kube/eks-config for EKS)"
  type        = string
  default     = "~/.kube/k3d-config"
}

variable "cluster_type" {
  description = "Type of cluster: k3d or eks"
  type        = string
  default     = "k3d"
  
  validation {
    condition     = contains(["k3d", "eks"], var.cluster_type)
    error_message = "cluster_type must be either 'k3d' or 'eks'."
  }
}

variable "argocd_namespace" {
  description = "Namespace where ArgoCD will be installed"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "7.0.0"
}

variable "argocd_domain" {
  description = "Domain for ArgoCD server"
  type        = string
  default     = "argocd.example.com"
}

variable "git_repository_url" {
  description = "Git repository URL for GitOps"
  type        = string
}

variable "git_repository_branch" {
  description = "Git repository branch"
  type        = string
  default     = "main"
}

variable "git_repository_path" {
  description = "Path in git repository for applications"
  type        = string
  default     = "k8s-manifests"
}

variable "enable_ingress" {
  description = "Enable Ingress for ArgoCD server"
  type        = bool
  default     = false
}
