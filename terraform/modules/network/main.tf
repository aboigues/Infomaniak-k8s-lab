# Module Network pour Infomaniak

variable "cluster_name" {
  description = "Nom du cluster"
  type        = string
}

variable "network_cidr" {
  description = "CIDR du réseau privé"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnets" {
  description = "Configuration des sous-réseaux"
  type = map(string)
  default = {
    workers  = "10.0.1.0/24"
    services = "10.0.2.0/24"
  }
}

# Réseau privé principal
resource "infomaniak_network" "main" {
  name = "${var.cluster_name}-network"
  cidr = var.network_cidr
  
  description = "Réseau privé pour cluster Kubernetes lab"
  
  tags = {
    cluster     = var.cluster_name
    environment = "lab"
  }
}

# Sous-réseaux
resource "infomaniak_subnet" "subnets" {
  for_each = var.subnets
  
  network_id = infomaniak_network.main.id
  name       = "${var.cluster_name}-${each.key}"
  cidr       = each.value
  
  # DHCP enabled
  enable_dhcp = true
  
  tags = {
    subnet_type = each.key
    cluster     = var.cluster_name
  }
}

# Security groups
resource "infomaniak_security_group" "cluster" {
  name        = "${var.cluster_name}-sg"
  description = "Security group pour cluster Kubernetes"
  
  tags = {
    cluster = var.cluster_name
  }
}

# Règles SSH (depuis n'importe où - à restreindre en production)
resource "infomaniak_security_group_rule" "ssh" {
  security_group_id = infomaniak_security_group.cluster.id
  
  direction   = "ingress"
  protocol    = "tcp"
  port_range  = "22"
  cidr        = "0.0.0.0/0"
  description = "SSH access"
}

# Règles Kubernetes API
resource "infomaniak_security_group_rule" "k8s_api" {
  security_group_id = infomaniak_security_group.cluster.id
  
  direction   = "ingress"
  protocol    = "tcp"
  port_range  = "6443"
  cidr        = "0.0.0.0/0"
  description = "Kubernetes API server"
}

# Communication interne cluster
resource "infomaniak_security_group_rule" "internal" {
  security_group_id = infomaniak_security_group.cluster.id
  
  direction   = "ingress"
  protocol    = "all"
  cidr        = var.network_cidr
  description = "Internal cluster communication"
}

# Sortie internet
resource "infomaniak_security_group_rule" "egress" {
  security_group_id = infomaniak_security_group.cluster.id
  
  direction   = "egress"
  protocol    = "all"
  cidr        = "0.0.0.0/0"
  description = "Allow all outbound"
}

# Load Balancer (optionnel)
resource "infomaniak_loadbalancer" "cluster" {
  name        = "${var.cluster_name}-lb"
  network_id  = infomaniak_network.main.id
  
  # Configuration minimale
  flavor = "small"
  
  tags = {
    cluster = var.cluster_name
    purpose = "ingress"
  }
}

# Outputs
output "network_id" {
  description = "ID du réseau privé"
  value       = infomaniak_network.main.id
}

output "subnet_ids" {
  description = "IDs des sous-réseaux"
  value       = { for k, v in infomaniak_subnet.subnets : k => v.id }
}

output "security_group_id" {
  description = "ID du security group"
  value       = infomaniak_security_group.cluster.id
}

output "loadbalancer_id" {
  description = "ID du load balancer"
  value       = infomaniak_loadbalancer.cluster.id
}

output "loadbalancer_ip" {
  description = "IP publique du load balancer"
  value       = infomaniak_loadbalancer.cluster.public_ip
}
