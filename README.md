# toyeks

Quickly booting up an EKS cluster.

## Requirements

Tested with:

```
$ terraform version
Terraform v1.3.9
on linux_amd64

$ aws --version
aws-cli/2.10.3 Python/3.9.11 Linux/5.4.0-139-generic exe/x86_64.ubuntu.20 prompt/off

$ kubectl version --short
Flag --short has been deprecated, and will be removed in the future. The --short output will become the default.
Client Version: v1.25.6

$ helm version
version.BuildInfo{Version:"v3.11.1", GitCommit:"293b50c65d4d56187cd4e2f390f0ada46b4c4737", GitTreeState:"clean", GoVersion:"go1.18.10"}
```

## Create the cluster

```
git clone https://github.com/udhos/toyeks

cd toyeks

export AWS_PROFILE=...

./run.sh boot
./run.sh plan
./run.sh apply
```

## Access the cluster

Update ~/.kube/config with the new cluster.

```
$ aws eks update-kubeconfig --name eks_toyeks_cluster1 --region us-east-2
```

List cluster namespaces.

```
$ kubectl get ns
NAME              STATUS   AGE
default           Active   16m
kube-node-lease   Active   16m
kube-public       Active   16m
kube-system       Active   16m
```

## Deploy karpenter

```
./karpenter.sh
```

## Destroy the cluster

Do not forget to destroy everything.

```
./run.sh destroy
```
