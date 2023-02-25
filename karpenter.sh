#!/bin/bash

#
# https://karpenter.sh/v0.25.0/getting-started/migrating-from-cas/
#

KARPENTER_VERSION=v0.25.0
echo KARPENTER_VERSION=$KARPENTER_VERSION

CLUSTER_NAME=$(grep eks_cluster_name terraform/main.tf | head -1 | awk '{print $3}' | tr -d '"')
echo CLUSTER_NAME=$CLUSTER_NAME

[ -z "$CLUSTER_NAME" ] && { echo >&2 "missing CLUSTER_NAME"; exit 1; }

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID

[ -z "$AWS_ACCOUNT_ID" ] && { echo >&2 "missing AWS_ACCOUNT_ID"; exit 1; }

cat <<EOF

# Step 1/5:
#
# Make sure kubectl is working.

aws eks update-kubeconfig --name $CLUSTER_NAME --region us-east-2

kubectl get ns

#
# Hit ENTER to continue
#
EOF

read i

cat <<EOF

# Step 2/5:
#
# Update cm aws-auth adding the rule below.
#
# Keep {{EC2PrivateDNSName}} unchanged.

kubectl edit configmap aws-auth -n kube-system

    - groups:
      - system:bootstrappers
      - system:nodes
      rolearn: arn:aws:iam::$AWS_ACCOUNT_ID:role/KarpenterInstanceNodeRole
      username: system:node:{{EC2PrivateDNSName}}

#
# Hit ENTER to continue
#
EOF

read i

helm template karpenter oci://public.ecr.aws/karpenter/karpenter --version ${KARPENTER_VERSION} --namespace karpenter \
    --set settings.aws.defaultInstanceProfile=KarpenterInstanceProfile \
    --set settings.aws.clusterName=${CLUSTER_NAME} \
    --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="arn:aws:iam::${AWS_ACCOUNT_ID}:role/KarpenterControllerRole-${CLUSTER_NAME}" \
    --version ${KARPENTER_VERSION} > karpenter.yaml

NODEGROUP1=$(grep node_group_name terraform/module_eks/main.tf | head -1 | awk '{print $3}' | tr -d '"')
NODEGROUP2=$(grep node_group_name terraform/module_eks/main.tf | head -2 | tail -1 | awk '{print $3}' | tr -d '"')

echo NODEGROUP1=$NODEGROUP1
echo NODEGROUP2=$NODEGROUP2

cat <<EOF

# Step 3/5:
#
# Edit deployment affinity rules in the file just created: karpenter.yaml
#
# Modify the affinity so karpenter will run on one of the existing node group nodes.
#
# The rules should look something like this.

      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: karpenter.sh/provisioner-name
                operator: DoesNotExist
            - matchExpressions:
              - key: eks.amazonaws.com/nodegroup
                operator: In
                values:
                - ${NODEGROUP1}
                - ${NODEGROUP2}

#
# Hit ENTER to continue
#
EOF

read i

cat <<EOF

# Step 4/5:
#
# Deploy karpenter using commands below.

kubectl create namespace karpenter

kubectl create -f https://raw.githubusercontent.com/aws/karpenter/${KARPENTER_VERSION}/pkg/apis/crds/karpenter.sh_provisioners.yaml

kubectl create -f https://raw.githubusercontent.com/aws/karpenter/${KARPENTER_VERSION}/pkg/apis/crds/karpenter.k8s.aws_awsnodetemplates.yaml

kubectl apply -f karpenter.yaml

#
# Hit ENTER to continue
#
EOF

read i

cat <<__EOF__

# Step 5/5:
#
# Create default provisioner.

cat <<EOF | kubectl apply -f -
apiVersion: karpenter.sh/v1alpha5
kind: Provisioner
metadata:
  name: default
spec:
  requirements:
    - key: karpenter.k8s.aws/instance-category
      operator: In
      values: [c, m, r]
    - key: karpenter.k8s.aws/instance-generation
      operator: Gt
      values: ["2"]
    - key: "karpenter.sh/capacity-type" # If not included, the webhook for the AWS cloud provider will default to on-demand
      operator: In
      values: ["spot", "on-demand"]

  # Resource limits constrain the total size of the cluster.
  # Limits prevent Karpenter from creating new instances once the limit is exceeded.
  limits:
    resources:
      cpu: "1000"
      memory: 1000Gi

  # Enables consolidation which attempts to reduce cluster cost by both removing un-needed nodes and down-sizing those
  # that can't be removed.  Mutually exclusive with the ttlSecondsAfterEmpty parameter.
  consolidation:
    enabled: true

  providerRef:
    name: default
---
apiVersion: karpenter.k8s.aws/v1alpha1
kind: AWSNodeTemplate
metadata:
  name: default
spec:
  subnetSelector:
    karpenter.sh/discovery: "${CLUSTER_NAME}"
  securityGroupSelector:
    karpenter.sh/discovery: "${CLUSTER_NAME}"
EOF

#
# Verify karpenter
#

kubectl logs -f -n karpenter -c controller -l app.kubernetes.io/name=karpenter
__EOF__

