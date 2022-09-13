# kind K8s cluster with support of self generated CA

`Problem` - I want to run a container image in [kind](https://kind.sigs.k8s.io)
K8s cluster from container repository with TLS certificate issued by self
generated CA, but kubelet cannot pull that image because of this error
`x509: certificate signed by unknown authority`.

`Solution` - Inject self generated [CA certificate](internal-ca-bundle.crt)(s)
into K8s cluster node so kubelet will treat a TLS certificate
(issued from self generated CA) for container repository as trusted.

Original [issue](https://github.com/kubernetes-sigs/kind/issues/2055).

## TOC

- [kind K8s cluster with support of self generated CA](#kind-k8s-cluster-with-support-of-self-generated-ca)
  - [TOC](#toc)
  - [🏁 Get started](#-get-started)
    - [Add your CA bundle](#add-your-ca-bundle)
    - [🚀 Create cluster](#-create-cluster)
    - [🧹 Destroy cluster](#-destroy-cluster)
    - [🙋‍♂️ Additional info](#️-additional-info)

## 🏁 Get started

### Add your CA bundle

Add certificate(s) of self generated CA into [internal-ca-bundle.crt](internal-ca-bundle.crt)
file. If there is some intermediate issuer(s), place it in this order

```bash
$ cat internal-ca-bundle.crt
-----BEGIN CERTIFICATE-----
<certificate_of_root_issuer>
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
<certificate_of_intermediate_issuer>
-----END CERTIFICATE-----
```

[More info](https://cheapsslsecurity.com/p/what-is-ssl-certificate-chain/)
regarding order of multiple CAs.

### 🚀 Create cluster

```bash
make tf-apply
```

### 🧹 Destroy cluster

```bash
make tf-destroy
```

### 🙋‍♂️ Additional info

In created cluster there is preinstalled
[ingress-nginx](https://github.com/kubernetes/ingress-nginx),
which maps your local ports `80` and `443` to this ingress controller.
To use this ingress controller, specify `.spec.ingressClassName: nginx`
in your ingress manifest(s).
