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

Karpenter OCI registry: https://gallery.ecr.aws/karpenter/karpenter

Query configuration values available for helm chart hosted on OCI registry:

```
export HELM_EXPERIMENTAL_OCI=1 ;# no longer required since helm 3.8.0

helm show values oci://public.ecr.aws/karpenter/karpenter --version v0.25.0
```

You can add chart values to script karpenter.sh.

Deploy script:

```
./karpenter.sh
```

## Launch many pods and check karpenter autoscaling

```
helm repo add miniapi https://udhos.github.io/miniapi
helm repo update
helm search repo miniapi -l --version ">=0.0.0"
helm install my-miniapi miniapi/miniapi --values miniapi/values.yaml

kubectl scale deploy my-miniapi --replicas=200

kubectl get deploy my-miniapi
kubectl get nodes

kubectl scale deploy my-miniapi --replicas=1
```

## Destroy the cluster

Do not forget to destroy everything.

```
./run.sh destroy
```
