# =============================================================================
# Supabase: 4 môi trường, mỗi môi trường một bộ biến riêng trong Doppler
#   SUPABASE_ACCESS_TOKEN_<ENV>, SUPABASE_ORGANIZATION_ID_<ENV>, SUPABASE_DB_PASSWORD_<ENV>,
#   GOOGLE_CLIENT_ID_<ENV>, GOOGLE_CLIENT_SECRET_<ENV>, SMTP_USERNAME_<ENV>, SMTP_PASSWORD_<ENV>
#
# Hai môi trường có thể dùng chung một tài khoản Supabase (cùng token/org), chỉ cần
# đặt giá trị giống nhau trong Doppler. Tên project trùng GCP project: nghia-vip-<env>.
# =============================================================================

locals {
  default_callback = "https://20206205tech.github.io/auth-callback"
  local_callback   = "http://localhost:3000/auth/callback"

  smtp_common = {
    host        = var.SMTP_HOST
    port        = var.SMTP_PORT
    admin_email = var.SMTP_ADMIN_EMAIL
    sender_name = var.SMTP_SENDER_NAME
  }
}

# dev: Tài khoản B, dùng localhost
module "dev" {
  source    = "./modules/project"
  providers = { supabase = supabase.dev }

  name              = "nghia-vip-dev"
  organization_id   = var.SUPABASE_ORGANIZATION_ID_DEV
  database_password = var.SUPABASE_DB_PASSWORD_DEV

  site_url     = local.local_callback
  allowed_uris = [local.default_callback]

  google_client_id     = var.GOOGLE_CLIENT_ID_DEV
  google_client_secret = var.GOOGLE_CLIENT_SECRET_DEV

  smtp = merge(local.smtp_common, {
    username = var.SMTP_USERNAME_DEV
    password = var.SMTP_PASSWORD_DEV
  })
}

# stg: Tài khoản A, chưa có domain nên tạm dùng localhost
module "stg" {
  source    = "./modules/project"
  providers = { supabase = supabase.stg }

  name              = "nghia-vip-stg"
  organization_id   = var.SUPABASE_ORGANIZATION_ID_STG
  database_password = var.SUPABASE_DB_PASSWORD_STG

  site_url     = local.local_callback
  allowed_uris = [local.default_callback]

  google_client_id     = var.GOOGLE_CLIENT_ID_STG
  google_client_secret = var.GOOGLE_CLIENT_SECRET_STG

  smtp = merge(local.smtp_common, {
    username = var.SMTP_USERNAME_STG
    password = var.SMTP_PASSWORD_STG
  })
}

# prod: Tài khoản A
module "prod" {
  source    = "./modules/project"
  providers = { supabase = supabase.prod }

  name              = "nghia-vip-prod"
  organization_id   = var.SUPABASE_ORGANIZATION_ID_PROD
  database_password = var.SUPABASE_DB_PASSWORD_PROD

  site_url     = "https://20206205.tech/auth/callback"
  allowed_uris = [local.default_callback]

  google_client_id     = var.GOOGLE_CLIENT_ID_PROD
  google_client_secret = var.GOOGLE_CLIENT_SECRET_PROD

  smtp = merge(local.smtp_common, {
    username = var.SMTP_USERNAME_PROD
    password = var.SMTP_PASSWORD_PROD
  })
}

# test: Tài khoản B, dùng cho CI (app chạy localhost trên runner)
module "test" {
  source    = "./modules/project"
  providers = { supabase = supabase.test }

  name              = "nghia-vip-test"
  organization_id   = var.SUPABASE_ORGANIZATION_ID_TEST
  database_password = var.SUPABASE_DB_PASSWORD_TEST

  site_url     = local.local_callback
  allowed_uris = [local.default_callback]

  google_client_id     = var.GOOGLE_CLIENT_ID_TEST
  google_client_secret = var.GOOGLE_CLIENT_SECRET_TEST

  smtp = merge(local.smtp_common, {
    username = var.SMTP_USERNAME_TEST
    password = var.SMTP_PASSWORD_TEST
  })
}
