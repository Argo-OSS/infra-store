# variable

variable "cluster_name" {
  default = "argoworkflows-oss-eks" # module.eks.cluster_id
}

### sso ###

variable "sso" {
  default = "github" # [github, google, okta]
}

variable "sso_allowed_organizations" {
  default = "ArgoWorkflows-OSS" # for github
}

### argo cd ###

variable "argo_cd_apps" {
  default = []
}

variable "argo_cd_host" {
  default = ""
}

variable "argo_cd_ingress_class" {
  default = "nginx"
}
