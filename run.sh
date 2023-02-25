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
    upgrade)
        terraform -chdir=./terraform init --upgrade
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
    refresh)
        terraform -chdir=./terraform apply -refresh-only
        ;;
    import)
        echo import resource_type.resource_name resource_address:
        echo terraform -chdir=./terraform import aws_eks_cluster.eks_toyeks eks_toyeks
        ;;
    *)
        echo bad option: [$arg]
        ;;
esac
