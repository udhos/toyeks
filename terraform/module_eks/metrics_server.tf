
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.8.3"
  wait       = false
  values     = [local.values_metrics_server]

  /*
  values = [
    "${file("values.yaml")}"
  ]

  set {
    name  = "metrics.enabled"
    value = "true"
  }

  set {
    name  = "service.annotations.prometheus\\.io/port"
    value = "9127"
    type  = "string"
  }
  */
}

locals {
  values_metrics_server = <<VALUES
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: karpenter.sh/provisioner-name
          operator: DoesNotExist
VALUES
}
