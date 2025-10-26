# Variables pour le module Kubernetes

variable "cluster_name" {
  description = "Nom du cluster Kubernetes"
  type        = string
  default     = "lab-cluster-k8s"
}

variable "cluster_template_id" {
  description = "ID du template de cluster Infomaniak"
  type        = string
}

variable "environment" {
  description = "Environnement (dev, prod, lab)"
  type        = string
  default     = "lab"
}

variable "keypair_name" {
  description = "Nom de la keypair SSH"
  type        = string
}

# État du lab (actif ou arrêté)
variable "lab_active" {
  description = "Lab actif (true) ou arrêté (false)"
  type        = bool
  default     = false
}

# Configuration Node Pool - General Purpose
variable "general_node_flavor" {
  description = "Flavor pour les nodes general purpose"
  type        = string
  default     = "a1-ram2-disk20-perf1"  # 1 vCPU, 2GB RAM
}

variable "general_pool_min" {
  description = "Nombre minimum de nodes general"
  type        = number
  default     = 2
}

variable "general_pool_max" {
  description = "Nombre maximum de nodes general"
  type        = number
  default     = 3
}

variable "general_pool_desired" {
  description = "Nombre désiré de nodes general quand actif"
  type        = number
  default     = 2
}

# Configuration Node Pool - High Memory
variable "memory_node_flavor" {
  description = "Flavor pour les nodes high memory"
  type        = string
  default     = "a1-ram4-disk50-perf1"  # 2 vCPU, 4GB RAM
}

variable "memory_pool_min" {
  description = "Nombre minimum de nodes memory"
  type        = number
  default     = 1
}

variable "memory_pool_max" {
  description = "Nombre maximum de nodes memory"
  type        = number
  default     = 2
}

variable "memory_pool_desired" {
  description = "Nombre désiré de nodes memory quand actif"
  type        = number
  default     = 1
}

# Configuration Node Pool - GPU/AI
variable "enable_gpu_pool" {
  description = "Activer le node pool GPU"
  type        = bool
  default     = true
}

variable "gpu_node_flavor" {
  description = "Flavor pour les nodes GPU"
  type        = string
  default     = "g1-gpu-1"  # 4 vCPU + GPU NVIDIA L4
}

variable "gpu_pool_active" {
  description = "Activer le GPU dans cette session"
  type        = bool
  default     = false
}

# Labels personnalisés
variable "cluster_labels" {
  description = "Labels additionnels pour le cluster"
  type        = map(string)
  default     = {}
}
