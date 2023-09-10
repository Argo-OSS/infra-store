# data

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name 
}

data "aws_ssm_parameter" "github_secret" {
  name = format("/k8s/%s", "/github-secret")
}

data "aws_ssm_parameter" "argocd_password" {
  name = format("/k8s/%s", "argocd_password")
}

data "aws_ssm_parameter" "argocd_mtime" {
  name = format("/k8s/%s", "argocd_mtime")
}

data "aws_ssm_parameter" "argocd_github_client_id" {
  name = format("/k8s/%s", "argocd/github_client_id")
}

data "aws_ssm_parameter" "argocd_github_client_secret" {
  name = format("/k8s/%s", "argocd/github_client_secret")
}