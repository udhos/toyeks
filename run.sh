#!/bin/bash

arg="$1"

case $arg in
    validate)
        terraform -chdir=./terraform validate
        ;;
    fmt)
        terraform -chdir=./terraform fmt
        ;;
    init)
        terraform -chdir=./terraform init
        ;;
    boot)
        terraform -chdir=./terraform fmt
        terraform -chdir=./terraform validate
        terraform -chdir=./terraform init
        ;;
    plan)
        terraform -chdir=./terraform plan -out=./plan
        ;;
    apply)
        terraform -chdir=./terraform apply ./plan
        ;;
    show)
        terraform -chdir=./terraform show
        ;;
    destroy)
        terraform -chdir=./terraform destroy
        ;;
    *)
        echo bad option: [$arg]
        ;;
esac