resource "kind_cluster" "my-cluster" {
  name           = "my-cluster"
  wait_for_ready = "true"
  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role  = "control-plane"
      image = "kindest/node:v1.35.1"

      extra_mounts {
        host_path      = "internal-ca-bundle.crt"
        container_path = "/usr/local/share/ca-certificates/internal-ca-bundle.crt"
      }
    }
  }

  provisioner "local-exec" {
    command = "docker exec ${kind_cluster.my-cluster.name}-control-plane /bin/sh -c \"update-ca-certificates ; systemctl restart containerd.service\""
  }

  depends_on = [local_file.ca_cert]
}
