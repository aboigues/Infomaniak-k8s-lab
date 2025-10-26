# Variables pour le module Storage

variable "region" {
  description = "Région Infomaniak"
  type        = string
  default     = "ch-dc3-a"
}

variable "s3_bucket_name" {
  description = "Nom du bucket S3 principal"
  type        = string
  default     = "lab-artifacts"
}

variable "s3_storage_gb" {
  description = "Taille estimée du stockage S3 en GB"
  type        = number
  default     = 100
}

variable "create_persistent_volume" {
  description = "Créer un volume persistant"
  type        = bool
  default     = true
}

variable "persistent_volume_size" {
  description = "Taille du volume persistant en GB"
  type        = number
  default     = 50
}

variable "enable_snapshots" {
  description = "Activer les snapshots automatiques"
  type        = bool
  default     = true
}

variable "snapshot_volume_size" {
  description = "Taille du volume de snapshots en GB"
  type        = number
  default     = 20
}
