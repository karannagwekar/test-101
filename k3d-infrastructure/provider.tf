terraform {
  required_version = ">= 1.0"
  required_providers {
    k3d = {
      source  = "pvtl/k3d"
      version = "~> 0.0"
    }
  }
}

provider "k3d" {}
