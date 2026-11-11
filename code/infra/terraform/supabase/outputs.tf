locals {
  project_refs = {
    dev  = module.dev.project_ref
    stg  = module.stg.project_ref
    prod = module.prod.project_ref
    test = module.test.project_ref
  }
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
  value = {
    dev  = module.dev.anon_key
    stg  = module.stg.anon_key
    prod = module.prod.anon_key
    test = module.test.anon_key
  }
  sensitive = true
}
