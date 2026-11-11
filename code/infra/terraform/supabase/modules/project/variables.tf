variable "organization_id" {
  type        = string
  description = "ID organization Supabase của tài khoản này"
}

variable "region" {
  type        = string
  description = "Region đặt project"
  default     = "ap-southeast-1"
}

# Không chứa secret để dùng được làm for_each (Terraform không cho for_each trên giá trị sensitive)
variable "projects" {
  type = map(object({
    name         = string
    site_url     = string
    allowed_uris = list(string)
  }))
  description = "Các project cần tạo, key là tên môi trường (dev, stg, prod, test)"
}

variable "google_oauth" {
  type = map(object({
    client_id     = string
    client_secret = string
  }))
  description = "Google OAuth client theo môi trường, cùng key với var.projects"
  sensitive   = true
}

variable "database_password" {
  type        = string
  description = "Mật khẩu database"
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
