# =============================================================================
# Module con: tạo MỘT project Supabase và cấu hình Auth (Google OAuth, SMTP, mẫu email).
# Được gọi từ ../../main.tf, mỗi môi trường một lần với provider riêng.
# =============================================================================

resource "supabase_project" "this" {
  organization_id   = var.organization_id
  name              = var.name
  database_password = var.database_password
  region            = var.region

  lifecycle {
    ignore_changes = [database_password]
  }
}

data "supabase_apikeys" "this" {
  project_ref = supabase_project.this.id
}

resource "supabase_settings" "this" {
  project_ref = supabase_project.this.id

  auth = jsonencode({
    # # Mặc định là 1 giờ, cấu hình 12 giờ = 43200 giây
    # jwt_exp = 43200

    # OAuth client của GCP project cùng tên (nghia-vip-<env>)
    external_google_enabled   = true
    external_google_client_id = var.google_client_id
    external_google_secret    = var.google_client_secret

    site_url = var.site_url

    # Dùng join để biến list thành string cách nhau bởi dấu phẩy
    uri_allow_list = join(",", distinct(concat(
      [var.site_url],
      var.allowed_uris
    )))

    smtp_host        = var.smtp.host
    smtp_port        = var.smtp.port
    smtp_user        = var.smtp.username
    smtp_pass        = var.smtp.password
    smtp_admin_email = var.smtp.admin_email
    smtp_sender_name = var.smtp.sender_name

    # --- CẤU HÌNH RATE LIMIT ---
    rate_limit_email_sent = 100

    # =========================================================
    # --- CẤU HÌNH ĐỊNH DẠNG EMAIL XÁC NHẬN (CONFIRMATION) ---
    # =========================================================
    mailer_templates_confirmation_subject = "Xác nhận đăng ký tài khoản"
    mailer_templates_confirmation_content = <<-EOT
      <div style="font-family: sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto;">
        <h2>Xác nhận đăng ký tài khoản</h2>
        <p>Chào bạn,</p>
        <p>Cảm ơn bạn đã đăng ký tài khoản. Vui lòng nhấn vào nút bên dưới để xác nhận địa chỉ email của bạn:</p>
        <br>
        <p style="text-align: center;">
          <a style="background-color: #04aa6d; color: white; padding: 12px 24px; text-decoration: none; border-radius: 12px; font-weight: bold; display: inline-block;" href="{{ .ConfirmationURL }}" target="_blank">
            &#128073; Xác nhận tài khoản
          </a>
        </p>
        <br>
        <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
        <p style="font-size: 14px; color: #666;"><em>Nếu nút bấm không hoạt động, vui lòng copy và dán đường dẫn sau vào trình duyệt:</em></p>
        <p style="font-size: 14px; word-break: break-all; color: #04aa6d;">
          <a href="{{ .ConfirmationURL }}" style="color: #04aa6d;">{{ .ConfirmationURL }}</a>
        </p>
      </div>
    EOT

    # =========================================================
    # --- CẤU HÌNH ĐỊNH DẠNG EMAIL QUÊN MẬT KHẨU (RECOVERY) ---
    # =========================================================
    mailer_templates_recovery_subject = "Yêu cầu đặt lại mật khẩu"
    mailer_templates_recovery_content = <<-EOT
      <div style="font-family: sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto;">
        <h2>Đặt lại mật khẩu của bạn</h2>
        <p>Chào bạn,</p>
        <p>Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản của bạn. Vui lòng nhấn vào nút bên dưới để tiến hành tạo mật khẩu mới:</p>
        <br>
        <p style="text-align: center;">
          <a style="background-color: #04aa6d; color: white; padding: 12px 24px; text-decoration: none; border-radius: 12px; font-weight: bold; display: inline-block;" href="{{ .ConfirmationURL }}" target="_blank">
            &#128073; Đặt lại mật khẩu
          </a>
        </p>
        <br>
        <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
        <p style="font-size: 14px; color: #666;"><em>Nếu nút bấm không hoạt động, vui lòng copy và dán đường dẫn sau vào trình duyệt:</em></p>
        <p style="font-size: 14px; word-break: break-all; color: #04aa6d;">
          <a href="{{ .ConfirmationURL }}" style="color: #04aa6d;">{{ .ConfirmationURL }}</a>
        </p>
        <p style="font-size: 14px; color: #999; margin-top: 20px;">Nếu bạn không thực hiện yêu cầu này, vui lòng bỏ qua email này.</p>
      </div>
    EOT
  })
}
