output "project_ref" {
  value = supabase_project.this.id
}

output "anon_key" {
  value     = data.supabase_apikeys.this.anon_key
  sensitive = true
}
