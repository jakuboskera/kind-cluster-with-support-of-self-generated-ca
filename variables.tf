variable "deploy_registry" {
  description = "Deploy a local Docker registry with TLS (signed by internal CA) and a test pod. Set to false when using an existing on-premise registry."
  type        = bool
  default     = true
}
