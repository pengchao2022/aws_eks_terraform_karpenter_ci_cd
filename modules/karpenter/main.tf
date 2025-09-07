resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "https://charts.karpenter.sh"
  chart      = "karpenter"
  version    = var.karpenter_version

  values = [
    <<-EOT
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: ${var.karpenter_controller_iam_arn}
    
    settings:
      clusterName: ${var.cluster_name}
      clusterEndpoint: ${var.cluster_endpoint}
      interruptionQueue: ${var.cluster_name}
    
    controller:
      defaultInstanceProfile: ${var.node_instance_profile}
    EOT
  ]

  depends_on = [kubernetes_namespace.karpenter]
}

resource "kubernetes_namespace" "karpenter" {
  metadata {
    name = "karpenter"
  }
}

resource "kubectl_manifest" "karpenter_provisioner" {
  yaml_body = <<-YAML
apiVersion: karpenter.sh/v1alpha5
kind: Provisioner
metadata:
  name: default
spec:
  requirements:
    - key: kubernetes.io/arch
      operator: In
      values: ["amd64"]
    - key: kubernetes.io/os
      operator: In
      values: ["linux"]
    - key: karpenter.sh/capacity-type
      operator: In
      values: ["on-demand"]
    - key: node.kubernetes.io/instance-type
      operator: In
      values: ["t3.micro"]
  providerRef:
    name: default
  ttlSecondsAfterEmpty: 30
  limits:
    resources:
      cpu: 1000
  YAML

  depends_on = [helm_release.karpenter]
}

resource "kubectl_manifest" "karpenter_aws_node_template" {
  yaml_body = <<-YAML
apiVersion: karpenter.k8s.aws/v1alpha1
kind: AWSNodeTemplate
metadata:
  name: default
spec:
  subnetSelector:
    karpenter.sh/discovery: ${var.cluster_name}
  securityGroupSelector:
    karpenter.sh/discovery: ${var.cluster_name}
  blockDeviceMappings:
    - deviceName: /dev/xvda
      ebs:
        volumeSize: 20Gi
        volumeType: gp3
        deleteOnTermination: true
  amiFamily: Ubuntu
  instanceTypes: ["t3.micro"]
  userData: |
    #!/bin/bash
    set -ex
    apt-get update
    apt-get install -y docker.io
    systemctl enable docker
    systemctl start docker
  YAML

  depends_on = [helm_release.karpenter]
}

# Create initial nodes using Karpenter provisioner
resource "kubectl_manifest" "initial_nodes" {
  count = var.node_count

  yaml_body = <<-YAML
apiVersion: karpenter.sh/v1alpha5
kind: NodeClaim
metadata:
  name: initial-node-${count.index}
  labels:
    app: initial-node
spec:
  requirements:
    - key: kubernetes.io/arch
      operator: In
      values: ["amd64"]
    - key: kubernetes.io/os
      operator: In
      values: ["linux"]
    - key: node.kubernetes.io/instance-type
      operator: In
      values: ["t3.micro"]
  nodeClassRef:
    apiGroup: karpenter.k8s.aws
    kind: AWSNodeTemplate
    name: default
  ttlSecondsAfterEmpty: 86400
  YAML

  depends_on = [
    helm_release.karpenter,
    kubectl_manifest.karpenter_provisioner,
    kubectl_manifest.karpenter_aws_node_template
  ]
}