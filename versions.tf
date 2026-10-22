terraform {
  required_version = ">= 1.0"

  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "0.13.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "4.4.2"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.4.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.9.1"
    }

    null = {
      source  = "hashicorp/null"
      version = "3.3.2"
    }
  }
}
