# Biến bí mật: không đặt default, lưu trong Doppler cùng tên
# scripts/infra/terraform/doppler-tf-env.sh chỉ lấy những biến khai báo ở đây
# Biến không quan trọng: điền luôn default

# ----- dev (nghia-vip-dev) -----

variable "SUPABASE_ACCESS_TOKEN_DEV" {
  type        = string
  description = "Personal Access Token của tài khoản Supabase chứa project dev"
  sensitive   = true
}

variable "SUPABASE_ORGANIZATION_ID_DEV" {
  type        = string
  description = "ID organization Supabase chứa project dev"
}

variable "SUPABASE_DB_PASSWORD_DEV" {
  type        = string
  description = "Mật khẩu database của project dev"
  sensitive   = true
}

variable "GOOGLE_CLIENT_ID_DEV" {
  type        = string
  description = "Google OAuth Client ID (GCP nghia-vip-dev)"
  sensitive   = true
}

variable "GOOGLE_CLIENT_SECRET_DEV" {
  type        = string
  description = "Google OAuth Client Secret (GCP nghia-vip-dev)"
  sensitive   = true
}

variable "SMTP_USERNAME_DEV" {
  type        = string
  description = "Tên đăng nhập SMTP gửi email Auth của dev"
  sensitive   = true
}

variable "SMTP_PASSWORD_DEV" {
  type        = string
  description = "Mật khẩu SMTP (App Password) của dev"
  sensitive   = true
}

# ----- stg (nghia-vip-stg) -----

variable "SUPABASE_ACCESS_TOKEN_STG" {
  type        = string
  description = "Personal Access Token của tài khoản Supabase chứa project stg"
  sensitive   = true
}

variable "SUPABASE_ORGANIZATION_ID_STG" {
  type        = string
  description = "ID organization Supabase chứa project stg"
}

variable "SUPABASE_DB_PASSWORD_STG" {
  type        = string
  description = "Mật khẩu database của project stg"
  sensitive   = true
}

variable "GOOGLE_CLIENT_ID_STG" {
  type        = string
  description = "Google OAuth Client ID (GCP nghia-vip-stg)"
  sensitive   = true
}

variable "GOOGLE_CLIENT_SECRET_STG" {
  type        = string
  description = "Google OAuth Client Secret (GCP nghia-vip-stg)"
  sensitive   = true
}

variable "SMTP_USERNAME_STG" {
  type        = string
  description = "Tên đăng nhập SMTP gửi email Auth của stg"
  sensitive   = true
}

variable "SMTP_PASSWORD_STG" {
  type        = string
  description = "Mật khẩu SMTP (App Password) của stg"
  sensitive   = true
}

# ----- prod (nghia-vip-prod) -----

variable "SUPABASE_ACCESS_TOKEN_PROD" {
  type        = string
  description = "Personal Access Token của tài khoản Supabase chứa project prod"
  sensitive   = true
}

variable "SUPABASE_ORGANIZATION_ID_PROD" {
  type        = string
  description = "ID organization Supabase chứa project prod"
}

variable "SUPABASE_DB_PASSWORD_PROD" {
  type        = string
  description = "Mật khẩu database của project prod"
  sensitive   = true
}

variable "GOOGLE_CLIENT_ID_PROD" {
  type        = string
  description = "Google OAuth Client ID (GCP nghia-vip-prod)"
  sensitive   = true
}

variable "GOOGLE_CLIENT_SECRET_PROD" {
  type        = string
  description = "Google OAuth Client Secret (GCP nghia-vip-prod)"
  sensitive   = true
}

variable "SMTP_USERNAME_PROD" {
  type        = string
  description = "Tên đăng nhập SMTP gửi email Auth của prod"
  sensitive   = true
}

variable "SMTP_PASSWORD_PROD" {
  type        = string
  description = "Mật khẩu SMTP (App Password) của prod"
  sensitive   = true
}

# ----- test (nghia-vip-test) -----

variable "SUPABASE_ACCESS_TOKEN_TEST" {
  type        = string
  description = "Personal Access Token của tài khoản Supabase chứa project test"
  sensitive   = true
}

variable "SUPABASE_ORGANIZATION_ID_TEST" {
  type        = string
  description = "ID organization Supabase chứa project test"
}

variable "SUPABASE_DB_PASSWORD_TEST" {
  type        = string
  description = "Mật khẩu database của project test"
  sensitive   = true
}

variable "GOOGLE_CLIENT_ID_TEST" {
  type        = string
  description = "Google OAuth Client ID (GCP nghia-vip-test)"
  sensitive   = true
}

variable "GOOGLE_CLIENT_SECRET_TEST" {
  type        = string
  description = "Google OAuth Client Secret (GCP nghia-vip-test)"
  sensitive   = true
}

variable "SMTP_USERNAME_TEST" {
  type        = string
  description = "Tên đăng nhập SMTP gửi email Auth của test"
  sensitive   = true
}

variable "SMTP_PASSWORD_TEST" {
  type        = string
  description = "Mật khẩu SMTP (App Password) của test"
  sensitive   = true
}

# ----- SMTP dùng chung -----

variable "SMTP_HOST" {
  type        = string
  description = "Địa chỉ máy chủ SMTP"
  default     = "smtp.gmail.com"
}

variable "SMTP_PORT" {
  type        = string
  description = "Cổng SMTP"
  default     = "587"
}

variable "SMTP_ADMIN_EMAIL" {
  type        = string
  description = "Địa chỉ email người gửi (From Email)"
  default     = "support@20206205.tech"
}

variable "SMTP_SENDER_NAME" {
  type        = string
  description = "Tên hiển thị của người gửi (From Name)"
  default     = "(20206205.tech) AI Chatbot - Support"
}
