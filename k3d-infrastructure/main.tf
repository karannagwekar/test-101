resource "null_resource" "k3d_cluster" {
  provisioner "local-exec" {
    command = "k3d cluster create ${var.cluster_name} --image rancher/k3s:${var.k8s_version} --agents ${var.agent_nodes_count} --servers 1 --port 8080:80@server:0 --port 6443:6443@server:0 --k3s-arg '--disable=traefik@server:0' --wait"
  }

  lifecycle {
    ignore_changes = all
  }
}

resource "null_resource" "k3d_cluster_delete" {
  triggers = {
    cluster_name = var.cluster_name
  }

  provisioner "local-exec" {
    when    = destroy
    command = "k3d cluster delete ${self.triggers.cluster_name}"
  }

  depends_on = [null_resource.k3d_cluster]
}
