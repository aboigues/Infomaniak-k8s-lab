# Variables pour l'environnement Production/Lab

# Credentials Infomaniak OpenStack
variable "openstack_auth_url" {
  description = "URL d'authentification OpenStack Infomaniak"
  type        = string
  default     = "https://api.pub1.infomaniak.cloud/identity/v3"
}

variable "openstack_tenant_name" {
  description = "Nom du projet OpenStack"
  type        = string
}

variable "openstack_username" {
  description = "Nom d'utilisateur OpenStack"
  type        = string
}

variable "openstack_password" {
  description = "Mot de passe OpenStack"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Région Infomaniak"
  type        = string
  default     = "ch-dc3-a"
}

# Configuration générale
variable "environment" {
  description = "Nom de l'environnement"
  type        = string
  default     = "lab"
}

# État du lab
variable "lab_active" {
  description = "Lab actif (nodes démarrés) ou arrêté (nodes à 0)"
  type        = bool
  default     = false
}

# Configuration réseau
variable "network_name" {
  description = "Nom du réseau principal"
  type        = string
  default     = "lab-network"
}

variable "workers_subnet_cidr" {
  description = "CIDR pour le sous-réseau workers"
  type        = string
  default     = "10.0.1.0/24"
}

variable "services_subnet_cidr" {
  description = "CIDR pour le sous-réseau services"
  type        = string
  default     = "10.0.2.0/24"
}

variable "external_network_id" {
  description = "ID du réseau externe Infomaniak"
  type        = string
}

variable "admin_ip_cidr" {
  description = "CIDR autorisé pour administration SSH/API"
  type        = string
  default     = "0.0.0.0/0"
}

variable "create_load_balancer" {
  description = "Créer un load balancer (coût additionnel)"
  type        = bool
  default     = false
}

# Configuration stockage
variable "s3_bucket_name" {
  description = "Nom du bucket S3 principal"
  type        = string
  default     = "lab-artifacts"
}

variable "s3_storage_gb" {
  description = "Taille estimée stockage S3 en GB"
  type        = number
  default     = 100
}

variable "create_persistent_volume" {
  description = "Créer des volumes persistants"
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

# Configuration Kubernetes
variable "cluster_name" {
  description = "Nom du cluster Kubernetes"
  type        = string
  default     = "lab-cluster-k8s"
}

variable "cluster_template_id" {
  description = "ID du template cluster Infomaniak (obtenir via API)"
  type        = string
}

variable "keypair_name" {
  description = "Nom de la keypair SSH pour les nodes"
  type        = string
}

# Node Pool - General Purpose
variable "general_node_flavor" {
  description = "Flavor pour nodes general"
  type        = string
  default     = "a1-ram2-disk20-perf1"
}

variable "general_pool_min" {
  description = "Min nodes general (quand actif)"
  type        = number
  default     = 2
}

variable "general_pool_max" {
  description = "Max nodes general"
  type        = number
  default     = 3
}

variable "general_pool_desired" {
  description = "Nombre désiré nodes general (quand actif)"
  type        = number
  default     = 2
}

# Node Pool - High Memory
variable "memory_node_flavor" {
  description = "Flavor pour nodes memory"
  type        = string
  default     = "a1-ram4-disk50-perf1"
}

variable "memory_pool_min" {
  description = "Min nodes memory (quand actif)"
  type        = number
  default     = 1
}

variable "memory_pool_max" {
  description = "Max nodes memory"
  type        = number
  default     = 2
}

variable "memory_pool_desired" {
  description = "Nombre désiré nodes memory (quand actif)"
  type        = number
  default     = 1
}

# Node Pool - GPU
variable "enable_gpu_pool" {
  description = "Activer le pool GPU"
  type        = bool
  default     = true
}

variable "gpu_node_flavor" {
  description = "Flavor pour nodes GPU"
  type        = string
  default     = "g1-gpu-1"
}

variable "gpu_pool_active" {
  description = "Démarrer le GPU pour cette session"
  type        = bool
  default     = false
}
