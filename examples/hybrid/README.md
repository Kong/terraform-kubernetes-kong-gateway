# Hybrid Example

## Prerequisites

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

## Run

``` bash
terraform init
terraform apply
```

## Destroy

``` bash
terraform destroy
```
