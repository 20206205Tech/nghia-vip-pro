# =============================================================================
# Supabase: 4 môi trường chia trên 2 tài khoản (mỗi tài khoản Free được 2 project)
#
#   Tài khoản A: prod, stg   (provider supabase.a)
#   Tài khoản B: dev,  test  (provider supabase.b)
#
# Tên project trùng tên GCP project (nghia-vip-<env>), Google OAuth client cũng
# lấy từ GCP project cùng tên. Muốn đổi môi trường sang tài khoản khác: sửa `account`.
# =============================================================================

locals {
  default_callback = "https://20206205tech.github.io/auth-callback"
  local_callback   = "http://localhost:3000/auth/callback"

  environments = {
    prod = { account = "a", site_url = "https://20206205.tech/auth/callback" }
    stg  = { account = "a", site_url = local.local_callback } # Chưa có domain, tạm dùng localhost
    dev  = { account = "b", site_url = local.local_callback }
    test = { account = "b", site_url = local.local_callback } # Dùng cho CI (app chạy localhost trên runner)
  }

  projects = {
    for env, cfg in local.environments : env => {
      account      = cfg.account
      name         = "nghia-vip-${env}"
      site_url     = cfg.site_url
      allowed_uris = [local.default_callback]
    }
  }

  google_oauth = {
    dev  = { client_id = var.GOOGLE_CLIENT_ID_DEV, client_secret = var.GOOGLE_CLIENT_SECRET_DEV }
    stg  = { client_id = var.GOOGLE_CLIENT_ID_STG, client_secret = var.GOOGLE_CLIENT_SECRET_STG }
    prod = { client_id = var.GOOGLE_CLIENT_ID_PROD, client_secret = var.GOOGLE_CLIENT_SECRET_PROD }
    test = { client_id = var.GOOGLE_CLIENT_ID_TEST, client_secret = var.GOOGLE_CLIENT_SECRET_TEST }
  }

  smtp = {
    host        = var.SMTP_HOST
    port        = var.SMTP_PORT
    username    = var.SMTP_USERNAME
    password    = var.SMTP_PASSWORD
    admin_email = var.SMTP_ADMIN_EMAIL
    sender_name = var.SMTP_SENDER_NAME
  }
}

module "account_a" {
  source    = "./modules/project"
  providers = { supabase = supabase.a }

  organization_id   = var.SUPABASE_ORGANIZATION_ID_A
  database_password = var.SUPABASE_DB_PASSWORD
  smtp              = local.smtp

  projects = {
    for env, p in local.projects : env => { name = p.name, site_url = p.site_url, allowed_uris = p.allowed_uris }
    if p.account == "a"
  }
  google_oauth = { for env, p in local.projects : env => local.google_oauth[env] if p.account == "a" }
}

module "account_b" {
  source    = "./modules/project"
  providers = { supabase = supabase.b }

  organization_id   = var.SUPABASE_ORGANIZATION_ID_B
  database_password = var.SUPABASE_DB_PASSWORD
  smtp              = local.smtp

  projects = {
    for env, p in local.projects : env => { name = p.name, site_url = p.site_url, allowed_uris = p.allowed_uris }
    if p.account == "b"
  }
  google_oauth = { for env, p in local.projects : env => local.google_oauth[env] if p.account == "b" }
}
