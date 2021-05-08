.PHONY: all build test out clean

all: build test

build: build_prep build_platform

build_prep:
	@echo "Prep environment"
	terraform init

build_platform:
	@echo "Deploy Kong platform"
	terraform apply -auto-approve

test: test_clustering

test_clustering:
	@echo "Test clustering and service + route creation and consumption"
	cinc-auditor exec ../../test/integration/default/ --input-file ../../test/integration/attributes/default/attrs.yml

out:
	@echo "Platform endpoints"
	terraform output

clean:
	@echo "Cleaning up...."
	terraform destroy -auto-approve
