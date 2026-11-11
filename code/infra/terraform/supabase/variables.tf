# Biến bí mật: không đặt default, lưu trong Doppler cùng tên
# scripts/infra/terraform/doppler-tf-env.sh chỉ lấy những biến khai báo ở đây
# Biến không quan trọng: điền luôn default

# ----- Tài khoản Supabase A (prod, stg) -----

variable "SUPABASE_ACCESS_TOKEN_A" {
  type        = string
  description = "Personal Access Token của tài khoản Supabase A"
  sensitive   = true
}

variable "SUPABASE_ORGANIZATION_ID_A" {
  type        = string
  description = "ID organization của tài khoản Supabase A"
  default     = "lzpbqmedjxywckgdnoqx"
}

# ----- Tài khoản Supabase B (dev, test) -----

variable "SUPABASE_ACCESS_TOKEN_B" {
  type        = string
  description = "Personal Access Token của tài khoản Supabase B"
  sensitive   = true
}

# Chưa biết trước nên không đặt default: lưu trong Doppler (hoặc điền default khi đã có)
variable "SUPABASE_ORGANIZATION_ID_B" {
  type        = string
  description = "ID organization của tài khoản Supabase B"
}

# ----- Chung -----

variable "SUPABASE_DB_PASSWORD" {
  type        = string
  description = "Mật khẩu database cho mọi project"
  sensitive   = true
}

# ----- Google OAuth: mỗi môi trường một client trong GCP project nghia-vip-<env> -----

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

# ----- SMTP -----

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

variable "SMTP_USERNAME" {
  type        = string
  description = "Tên đăng nhập SMTP"
  sensitive   = true
}

variable "SMTP_PASSWORD" {
  type        = string
  description = "Mật khẩu SMTP"
  sensitive   = true
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
