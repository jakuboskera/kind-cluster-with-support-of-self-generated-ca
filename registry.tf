locals {
  registry_name = "registry"
  registry_port = 5443
}

# ==============================================================================
# Internal CA
# ==============================================================================

resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem = tls_private_key.ca.private_key_pem

  is_ca_certificate = true

  subject {
    common_name  = "Internal Root CA"
    organization = "Internal"
  }

  validity_period_hours = 8760

  allowed_uses = [
    "digital_signature",
    "cert_signing",
    "crl_signing",
  ]
}

resource "local_file" "ca_cert" {
  content  = tls_self_signed_cert.ca.cert_pem
  filename = "${path.module}/internal-ca-bundle.crt"
}

# ==============================================================================
# Registry server certificate (signed by internal CA)
# ==============================================================================

resource "tls_private_key" "registry" {
  count     = var.deploy_registry ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "registry" {
  count           = var.deploy_registry ? 1 : 0
  private_key_pem = tls_private_key.registry[0].private_key_pem

  subject {
    common_name = local.registry_name
  }

  dns_names = [local.registry_name]
}

resource "tls_locally_signed_cert" "registry" {
  count              = var.deploy_registry ? 1 : 0
  cert_request_pem   = tls_cert_request.registry[0].cert_request_pem
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]
}

resource "local_file" "registry_cert" {
  count    = var.deploy_registry ? 1 : 0
  content  = tls_locally_signed_cert.registry[0].cert_pem
  filename = "${path.module}/certs/registry.crt"
}

resource "local_sensitive_file" "registry_key" {
  count           = var.deploy_registry ? 1 : 0
  content         = tls_private_key.registry[0].private_key_pem
  filename        = "${path.module}/certs/registry.key"
  file_permission = "0600"
}

# ==============================================================================
# Docker Registry container (with TLS from internal CA)
# ==============================================================================

resource "null_resource" "registry" {
  count = var.deploy_registry ? 1 : 0

  triggers = {
    registry_name = local.registry_name
  }

  depends_on = [
    kind_cluster.my-cluster,
    local_file.registry_cert,
    local_sensitive_file.registry_key,
  ]

  provisioner "local-exec" {
    command = <<-EOT
      docker run -d --restart=always \
        --name ${local.registry_name} \
        --network kind \
        -v ${abspath(path.module)}/certs:/certs \
        -e REGISTRY_HTTP_ADDR=0.0.0.0:${local.registry_port} \
        -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/registry.crt \
        -e REGISTRY_HTTP_TLS_KEY=/certs/registry.key \
        -p ${local.registry_port}:${local.registry_port} \
        registry:2
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "docker rm -f ${self.triggers.registry_name} || true"
  }
}

# ==============================================================================
# Push test image to registry
# ==============================================================================

resource "null_resource" "push_test_image" {
  count      = var.deploy_registry ? 1 : 0
  depends_on = [null_resource.registry]

  provisioner "local-exec" {
    command = <<-EOT
      # Configure Docker client to trust the internal CA for the registry
      if [ "$(uname)" = "Linux" ]; then
        sudo mkdir -p /etc/docker/certs.d/localhost:${local.registry_port}
        sudo cp ${abspath(path.module)}/internal-ca-bundle.crt \
          /etc/docker/certs.d/localhost:${local.registry_port}/ca.crt
      fi
      mkdir -p ~/.docker/certs.d/localhost:${local.registry_port}
      cp ${abspath(path.module)}/internal-ca-bundle.crt \
        ~/.docker/certs.d/localhost:${local.registry_port}/ca.crt

      # Wait for registry to be ready
      for i in $(seq 1 10); do
        curl -sf --cacert ${abspath(path.module)}/internal-ca-bundle.crt \
          https://localhost:${local.registry_port}/v2/ && break
        sleep 2
      done

      # Pull, tag, and push a test image
      docker pull busybox:latest
      docker tag busybox:latest localhost:${local.registry_port}/busybox:latest
      docker push localhost:${local.registry_port}/busybox:latest
    EOT
  }
}

# ==============================================================================
# Test pod pulling from the internal registry
# ==============================================================================

resource "kubernetes_pod_v1" "test" {
  count      = var.deploy_registry ? 1 : 0
  depends_on = [null_resource.push_test_image]

  metadata {
    name      = "test-internal-registry"
    namespace = "default"
  }

  spec {
    container {
      name    = "busybox"
      image   = "${local.registry_name}:${local.registry_port}/busybox:latest"
      command = ["sleep", "3600"]
    }
  }
}

# ==============================================================================
# Verify the test pod is running (image was pulled from internal registry)
# ==============================================================================

resource "null_resource" "verify_test_pod" {
  count      = var.deploy_registry ? 1 : 0
  depends_on = [kubernetes_pod_v1.test]

  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${abspath(path.module)}/my-cluster-config
      kubectl wait --for=condition=Ready pod/test-internal-registry --timeout=120s
      echo "✅ Pod successfully pulled image from internal registry with self-signed CA!"
    EOT
  }
}
