resource "neon_project" "this" {
  for_each = toset(var.projects)

  org_id    = var.NEON_ORGANIZATION_ID
  name      = each.key
  region_id = "aws-ap-southeast-1"

  history_retention_seconds = 21600
}
