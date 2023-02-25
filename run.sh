#!/bin/bash

arg="$1"

tf_fmt() {
    terraform -chdir=./terraform fmt -recursive
}
tf_validate() {
    terraform -chdir=./terraform validate
}
tf_init() {
    terraform -chdir=./terraform init
}

case $arg in
    validate)
        tf_validate
        ;;
    fmt)
        tf_fmt
        ;;
    init)
        tf_init
        ;;
    upgrade)
        terraform -chdir=./terraform init --upgrade
        ;;
    boot)
        tf_fmt
        tf_validate
        tf_init
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
