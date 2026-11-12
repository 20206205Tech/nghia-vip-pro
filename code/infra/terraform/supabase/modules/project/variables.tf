variable "name" {
  type        = string
  description = "Tên project Supabase"
}

variable "organization_id" {
  type        = string
  description = "ID organization Supabase chứa project"
}

variable "region" {
  type        = string
  description = "Region đặt project"
  default     = "ap-southeast-1"
}

variable "database_password" {
  type        = string
  description = "Mật khẩu database"
  sensitive   = true
}

variable "site_url" {
  type        = string
  description = "URL chính Supabase Auth redirect về sau khi đăng nhập"
}

variable "allowed_uris" {
  type        = list(string)
  description = "Các URL redirect được phép thêm ngoài site_url"
  default     = []
}

variable "google_client_id" {
  type        = string
  description = "Google OAuth Client ID"
  sensitive   = true
}

variable "google_client_secret" {
  type        = string
  description = "Google OAuth Client Secret"
  sensitive   = true
}

variable "smtp" {
  type = object({
    host        = string
    port        = string
    username    = string
    password    = string
    admin_email = string
    sender_name = string
  })
  description = "Cấu hình SMTP gửi email Auth"
  sensitive   = true
}
