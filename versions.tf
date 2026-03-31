terraform {
  required_version = ">= 1.0"

  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "0.11.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "4.2.1"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.0.1"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.7.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "3.2.4"
    }
  }
}
