output "webhook_url" {
  description = "URL để cấu hình vào dịch vụ gửi webhook"
  value       = hookdeck_source.webhook_inbound.url
}
