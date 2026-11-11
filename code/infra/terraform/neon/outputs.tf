output "project_ids" {
  description = "ID các project Neon theo tên"
  value       = { for name, p in neon_project.this : name => p.id }
}
