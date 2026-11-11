output "project_refs" {
  value = { for env, p in supabase_project.this : env => p.id }
}

output "anon_keys" {
  value     = { for env, k in data.supabase_apikeys.this : env => k.anon_key }
  sensitive = true
}
