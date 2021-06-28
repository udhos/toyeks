# toyeks

Quickly booting up an EKS cluster.

## Requirements

Tested with:

```
$ terraform version
Terraform v1.0.1
on linux_amd64

$ aws --version
aws-cli/2.2.14 Python/3.8.8 Linux/3.10.0-1127.19.1.el7.x86_64 exe/x86_64.centos.7 prompt/off

$ kubectl version
Client Version: version.Info{Major:"1", Minor:"19", GitVersion:"v1.19.0", GitCommit:"e19964183377d0ec2052d1f1fa930c4d7575bd50", GitTreeState:"clean", BuildDate:"2020-08-26T14:30:33Z", GoVersion:"go1.15", Compiler:"gc", Platform:"linux/amd64"}
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
$ aws eks update-kubeconfig --name eks_toyeks --profile $AWS_PROFILE --region us-east-2
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

## Destroy the cluster

Do not forget to destroy everything.

```
./run.sh destroy
```
