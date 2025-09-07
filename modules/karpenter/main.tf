resource "null_resource" "install_karpenter" {
  triggers = {
    cluster_name = var.cluster_name
  }

  provisioner "local-exec" {
    command = <<-EOT
      # 添加 helm repo
      helm repo add karpenter https://charts.karpenter.sh
      helm repo update
      
      # 创建 namespace
      kubectl create namespace karpenter --dry-run=client -o yaml | kubectl apply -f -
      
      # 安装 karpenter
      helm upgrade --install karpenter karpenter/karpenter \
        --namespace karpenter \
        --version ${var.karpenter_version} \
        --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=${var.karpenter_controller_iam_arn} \
        --set settings.clusterName=${var.cluster_name} \
        --set settings.clusterEndpoint=${var.cluster_endpoint} \
        --set controller.defaultInstanceProfile=${var.node_instance_profile}
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      helm uninstall karpenter --namespace karpenter || true
      kubectl delete namespace karpenter --ignore-not-found=true
    EOT
  }
}

resource "null_resource" "karpenter_provisioner" {
  depends_on = [null_resource.install_karpenter]

  provisioner "local-exec" {
    command = <<-EOT
      kubectl apply -f - <<EOF
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
      EOF
    EOT
  }
}

resource "null_resource" "karpenter_node_template" {
  depends_on = [null_resource.install_karpenter]

  provisioner "local-exec" {
    command = <<-EOT
      kubectl apply -f - <<EOF
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
      EOF
    EOT
  }
}