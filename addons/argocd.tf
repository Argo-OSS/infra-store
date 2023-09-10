provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

resource "helm_release" "argo-cd" {
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.helm_argo_cd

  namespace = "addon-argo-cd"
  name      = "argocd"

  values = [
    file("${path.module}/values/argo/argo-cd.yaml"),
    local.argocd_configs,
    local.argocd_ingress,
    local.argocd_apps,
    local.argocd_dex_github,
  ]

  wait = false

  create_namespace = true

  # depends_on = [
  #   kubernetes_secret.github-secret,
  # ]
}

resource "kubernetes_secret" "github-secret" {
  metadata {
    namespace = "addon-argo-cd"
    name      = "github-secret"
  }

  type = "Opaque"

  data = {
    "sshPrivateKey" = data.aws_ssm_parameter.github_secret.value
  }
}

locals {
  argocd_dex_callback = format("https://%s/api/dex/callback", var.argo_cd_host)

  # Argo expects the password in the secret to be bcrypt hashed.
  # You can create this hash with
  # `htpasswd -nbBC 10 "" $ARGO_PWD | tr -d ':\n' | sed 's/$2y/$2a/'`
  # Password modification time defaults to current time if not set
  # argocdServerAdminPasswordMtime: "2006-01-02T15:04:05Z"
  # `date -u +"%Y-%m-%dT%H:%M:%SZ"`
  argocd_configs = yamlencode(
    {
      configs = {
        secret = {
          argocdServerAdminPassword      = data.aws_ssm_parameter.argocd_password.value
          argocdServerAdminPasswordMtime = data.aws_ssm_parameter.argocd_mtime.value
        }
      }
    }
  )

  argocd_ingress = yamlencode(
    {
      server = {
        "service" = {
          type = "ClusterIP"
        }
        "ingress" = {
          "enabled" = true
          "annotations" = {
            "kubernetes.io/ingress.class"              = var.argo_cd_ingress_class
            "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
          }
          "hosts" = [
            var.argo_cd_host
          ]
          "https" = false
        }
        "config" = {
          url = format("https://%s", var.argo_cd_host)
        }
      }
    }
  )

  argocd_apps = yamlencode(
    {
      server = {
        additionalApplications = [
          for item in var.argo_cd_apps :
          {
            "name"    = item["name"],
            "project" = "default",
            "source" = {
              repoURL        = item["repo_url"]
              targetRevision = item["revision"]
              path           = item["path"]
              directory = {
                recurse = true
              }
            },
            "destination" = {
              server    = "https://kubernetes.default.svc"
              namespace = "addon-argo-cd"
            },
            "syncPolicy" = {
              automated = {
                prune    = true
                selfHeal = true
              }
            }
          }
        ]
      }
    }
  )

  argocd_dex_github = yamlencode(
    {
      server = {
        "config" = {
          "dex.config" = yamlencode(
            {
              connectors = [
                {
                  id   = "github"
                  type = "github"
                  name = "Github"
                  config = {
                    clientID     = data.aws_ssm_parameter.argocd_github_client_id.value
                    clientSecret = data.aws_ssm_parameter.argocd_github_client_secret.value
                    orgs = [
                      {
                        name  = var.sso_allowed_organizations
                        teams = []
                      }
                    ]
                  }
                }
              ]
            }
          )
        }
      }
    }
  )
}
