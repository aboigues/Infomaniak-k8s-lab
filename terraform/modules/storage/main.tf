# Module Storage pour Infomaniak

variable "s3_bucket_name" {
  description = "Nom du bucket S3"
  type        = string
}

variable "s3_versioning" {
  description = "Activer le versioning S3"
  type        = bool
  default     = true
}

variable "persistent_volumes" {
  description = "Configuration des volumes persistants"
  type = map(object({
    size_gb = number
    type    = string
  }))
  default = {}
}

# Bucket S3 pour artifacts et backups
resource "infomaniak_s3_bucket" "artifacts" {
  name   = var.s3_bucket_name
  region = "ch-dc3"
  
  # Versioning pour historique
  versioning {
    enabled = var.s3_versioning
  }
  
  # Lifecycle rules pour coûts
  lifecycle_rule {
    id      = "cleanup-old-backups"
    enabled = true
    
    expiration {
      days = 30
    }
    
    noncurrent_version_expiration {
      days = 7
    }
  }
  
  # Chiffrement
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  
  tags = {
    purpose     = "lab-artifacts"
    auto_backup = "enabled"
  }
}

# Dossiers S3 logiques
resource "infomaniak_s3_object" "folders" {
  for_each = toset([
    "backups/",
    "docker-images/",
    "ml-models/",
    "datasets/",
    "configs/",
    "logs/"
  ])
  
  bucket  = infomaniak_s3_bucket.artifacts.id
  key     = each.value
  content = ""
}

# Volumes persistants OpenStack
resource "infomaniak_volume" "persistent" {
  for_each = var.persistent_volumes
  
  name        = each.key
  size        = each.value.size_gb
  volume_type = each.value.type
  
  description = "Persistent volume for ${each.key}"
  
  tags = {
    volume_type = "persistent"
    managed_by  = "terraform"
  }
}

# Storage Classes Kubernetes (via manifests)
# Ces manifests seront appliqués séparément

# Outputs
output "s3_bucket_name" {
  description = "Nom du bucket S3"
  value       = infomaniak_s3_bucket.artifacts.id
}

output "s3_bucket_endpoint" {
  description = "Endpoint S3"
  value       = "https://s3.pub1.infomaniak.cloud"
}

output "volume_ids" {
  description = "IDs des volumes persistants"
  value       = { for k, v in infomaniak_volume.persistent : k => v.id }
}
