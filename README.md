# kind K8s cluster with support of self generated CA

`Problem` - I want to run a container image in [kind](https://kind.sigs.k8s.io)
K8s cluster from container repository with TLS certificate issued by self
generated CA, but kubelet cannot pull that image because of this error
`x509: certificate signed by unknown authority`.

`Solution` - Inject self generated CA certificate(s)
into K8s cluster node so kubelet will treat a TLS certificate
(issued from self generated CA) for container repository as trusted.

Original [issue](https://github.com/kubernetes-sigs/kind/issues/2055).

## TOC

- [kind K8s cluster with support of self generated CA](#kind-k8s-cluster-with-support-of-self-generated-ca)
  - [TOC](#toc)
  - [🏁 Get started](#-get-started)
    - [🚀 Create infra](#-create-infra)
    - [Using an existing on-premise registry](#using-an-existing-on-premise-registry)
    - [🧹 Destroy infra](#-destroy-infra)
  - [What happens under the hood](#what-happens-under-the-hood)

## 🏁 Get started

### 🚀 Create infra

```bash
make tf-apply
```

By default, this deploys a local Docker registry with TLS (signed by the
internal CA), pushes a test image, and verifies a pod can pull it.

### Using an existing on-premise registry

If you already have an on-premise registry with a certificate signed by your
internal CA, you can skip the local registry deployment:

```bash
terraform apply -auto-approve -var deploy_registry=false
```

In this mode, only the kind cluster with the injected CA trust store is created.
You provide your own CA bundle in `internal-ca-bundle.crt` before running apply.

### 🧹 Destroy infra

```bash
make tf-destroy
```

## What happens under the hood

1. Terraform generates an **internal CA** (key + certificate) using the `tls` provider
2. A **kind K8s cluster** is created with the CA certificate injected into the
   node's trust store (`update-ca-certificates`)
3. *(when `deploy_registry = true`)* A **Docker registry** with TLS (server cert
   signed by the internal CA) is started and connected to the `kind` Docker network
4. A test image (`busybox`) is pushed to the internal registry
5. A **test pod** is created that pulls the image from the internal registry —
   proving that kubelet trusts the internal CA
6. The pod is verified to be in `Ready` state
