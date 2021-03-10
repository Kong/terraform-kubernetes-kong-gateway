# terraform-kubernetes-kong-enterprise

A terraform module for provisioning Kong GW into kuberenetes.

## Status
Prototyping - frequent commits, only a few tests

## Prerequisits

### Using the module

This module utilises the terraform kubernetes provider, so when including
this module in your code you will need to specify the provider and args e.g.


```hcl
provider "kubernetes" {
  config_path = "~/.kube/config"
}
```

You will also need to provide secrets to the kubernetes cluster for your
kong license and your docker registry. You can look at the hybrid example
in the examples directory to see how this can be done.

## Usage

```hcl
locals {

  kong_image_pull_secrets = [
    {
      name = "name_of_docker_registry_secret_in_k8"
    }
  ]

  kong_volume_mounts = [
    {
      mount_path = "/etc/secrets/kong-cluster-cert"
      name       = "name_of_tls_secrets_in_k8"
      read_only  = true
    }
  ]

  kong_volume_secrets = [
    {
      name        = "name_of_tls_secrets_in_k8"
      secret_name = "name_of_tls_secrets_in_k8"
    }
  ]

  kong_cp_secret_config = [
    {
      name        = "KONG_LICENSE_DATA"
      secret_name = "name_of_generic_secret_in_k8"
      key         = "name_of_generic_secret_in_k8"
    }
  ]

  kong_cp_config = [
    {
      name  = "KONG_ADMIN_LISTEN"
      value = "0.0.0.0:8001, 0.0.0.0:8444 ssl"
    },
    {
      name  = "KONG_ADMIN_GUI_AUTH"
      value = "basic-auth"
    },
    {
      name  = "KONG_ADMIN_GUI_LISTEN"
      value = "0.0.0.0:8002, 0.0.0.0:8445 ssl"
    },
    ...
    ...
    ...
    <truncated>
  ]
}

module "kong-enterprise-control-plane" {
  source              = "git@github.com:Kong/terraform-kubernetes-kong-enterprise.git"
  deployment_name     = "kong-control-plane"
  namespace           = "kong-cp"
  deployment_replicas = 2
  config              = local.kong_cp_config
  secret_config       = local.kong_cp_secret_config
  kong_image          = "kong-docker-kong-enterprise-edition-docker.bintray.io/kong-enterprise-edition:2.2.0.0-alpine"
  image_pull_secrets  = local.kong_image_pull_secrets
  volume_mounts       = local.kong_volume_mounts
  volume_secrets      = local.kong_volume_secrets
}
```

Examples of how to use the module are in the examples directory.
Currently two examples exist `hybrid` and `hybrid_with_ingress`.

`hybrid` deploys Kong in hybrid mode and exposes the Kong services via
Kubernetes services of type load balancer.

`hybrid_with_ingress` deploys in hybrid mode but uses kubernetes clusterIP services
and exposes those behing a kubernetes ingress service. This example is still a
work in progress

## Testing

This module uses kitchen-terraform to test its self. To install you can use the
`Gemfile`. You will need Ruby (ruby devel needed as well) installed and bundler,
then you can run `bundle install` in the repos home directory

## Hybrid Example

### Prerequisites

* A kubernetes environment to use with kube config file at `~/.kube/config`
* A docker `config.json` located at `~/.docker/config.json` this file should contain
the auth details for your docker registry (e.g. bintray). You can generate this file
by running docker login

``` bash
docker login -u <my-user> -p <my-pass> kong-docker-kong-enterprise-edition-docker.bintray.io
```

* A Kong license string in a file at the following location `~/.kong_license`

The docker config file and the license file are read in as secrets to kubernetes
by the `secret_setup.tf` terraform

### Run

``` bash
terraform init
terraform apply
```

### Destroy

``` bash
terraform destroy
```
