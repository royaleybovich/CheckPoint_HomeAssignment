resource "random_id" "unique_suffix" {
  byte_length = 4  # 8 hex characters (e.g., "a1b2c3d4")
  
  keepers = {
    # Regenerate if project_name or environment changes
    project_name = var.project_name
    environment  = var.environment
  }
}