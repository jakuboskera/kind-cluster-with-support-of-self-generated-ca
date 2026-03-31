output "registry_url" {
  value = var.deploy_registry ? "https://localhost:${local.registry_port}" : null
}

output "test_image" {
  value = var.deploy_registry ? "${local.registry_name}:${local.registry_port}/busybox:latest" : null
}
