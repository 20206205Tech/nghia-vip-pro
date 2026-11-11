locals {
  project_refs = merge(module.account_a.project_refs, module.account_b.project_refs)
}

output "project_refs" {
  description = "Project ref (ID) của các project Supabase theo môi trường"
  value       = local.project_refs
}

output "api_urls" {
  description = "URL API của các project Supabase theo môi trường"
  value       = { for env, ref in local.project_refs : env => "https://${ref}.supabase.co" }
}

output "anon_keys" {
  description = "Anon key (public) của các project Supabase theo môi trường"
  value       = merge(module.account_a.anon_keys, module.account_b.anon_keys)
  sensitive   = true
}
