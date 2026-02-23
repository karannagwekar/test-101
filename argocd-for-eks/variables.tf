variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kubeconfig_context" {
  description = "Kubeconfig context name to target. Run 'kubectl config get-contexts' to list available contexts."
  type        = string
}

variable "cluster_type" {
  description = "Cluster type - EKS specific"
  type        = string
  default     = "eks"
  
  validation {
    condition     = var.cluster_type == "eks"
    error_message = "This configuration is for EKS clusters only. Use argocd-for-k3d for k3d clusters."
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
  description = "Domain for ArgoCD server (EKS)"
  type        = string
  default     = "argocd-eks.example.com"
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

variable "server_insecure" {
  description = "Run ArgoCD server without TLS (set true when TLS is terminated externally by a load balancer or ingress)"
  type        = bool
  default     = true
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for ELB SSL termination. When set, the Classic ELB will terminate HTTPS using this cert and forward plain HTTP to ArgoCD. Find yours with: aws acm list-certificates --region us-east-1"
  type        = string
  default     = ""
}
