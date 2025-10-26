# Variables pour le module Network

variable "environment" {
  description = "Environnement (dev, prod, lab)"
  type        = string
  default     = "lab"
}

variable "network_name" {
  description = "Nom du réseau principal"
  type        = string
  default     = "lab-network"
}

variable "workers_subnet_cidr" {
  description = "CIDR du sous-réseau workers"
  type        = string
  default     = "10.0.1.0/24"
}

variable "services_subnet_cidr" {
  description = "CIDR du sous-réseau services"
  type        = string
  default     = "10.0.2.0/24"
}

variable "dns_nameservers" {
  description = "Serveurs DNS"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "external_network_id" {
  description = "ID du réseau externe Infomaniak"
  type        = string
}

variable "admin_ip_cidr" {
  description = "CIDR IP autorisée pour l'administration"
  type        = string
  default     = "0.0.0.0/0"  # À restreindre en production
}

variable "create_load_balancer" {
  description = "Créer un load balancer"
  type        = bool
  default     = false  # Économie - utiliser NodePort par défaut
}
