# module "addons" {
#     source  = "./addons"

#     cluster_name = module.eks.cluster_id
#     sso          = "github"
#     sso_allowed_organizations = "ArgoWorkflows-OSS"
#     argo_cd_apps = []
#     argo_cd_host = ""
#     argo_cd_ingress_class = "nginx"
# }

## 남은 작업
# ingress 추가
# dex 관련 설정 ssm에 추가