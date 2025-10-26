# Module Kubernetes pour Infomaniak

variable "cluster_name" {
  description = "Nom du cluster Kubernetes"
  type        = string
}

variable "cluster_region" {
  description = "Région du cluster"
  type        = string
  default     = "ch-dc3-a"
}

variable "cluster_type" {
  description = "Type de cluster: shared ou dedicated"
  type        = string
  default     = "shared"
}

variable "network_id" {
  description = "ID du réseau privé"
  type        = string
}

variable "node_pools" {
  description = "Configuration des node pools"
  type = map(object({
    name          = string
    instance_type = string
    min_nodes     = number
    max_nodes     = number
    desired_nodes = number
  }))
  default = {}
}

# Cluster Kubernetes
resource "infomaniak_kubernetes_cluster" "main" {
  name   = var.cluster_name
  region = var.cluster_region
  type   = var.cluster_type
  
  version = "1.28"  # Version Kubernetes
  
  network_id = var.network_id
  
  # Cilium CNI (par défaut)
  cni = "cilium"
  
  # Auto-update control plane
  auto_upgrade = {
    enabled = true
    window  = "sun:02:00-04:00"
  }
  
  tags = {
    environment = "lab"
    managed_by  = "terraform"
    cost_center = "lab"
  }
}

# Node pools dynamiques
resource "infomaniak_kubernetes_node_pool" "pools" {
  for_each = var.node_pools
  
  cluster_id = infomaniak_kubernetes_cluster.main.id
  
  name          = each.value.name
  instance_type = each.value.instance_type
  
  min_size      = each.value.min_nodes
  max_size      = each.value.max_nodes
  desired_size  = each.value.desired_nodes
  
  # Autoscaling
  autoscaling_enabled = each.value.max_nodes > each.value.min_nodes
  
  # Labels pour identification
  labels = {
    pool      = each.value.name
    lab_mode  = "on-demand"
    auto_stop = "enabled"
  }
  
  # Taints pour GPU si applicable
  dynamic "taint" {
    for_each = contains(["ai-pool", "gpu-pool"], each.value.name) ? [1] : []
    content {
      key    = "nvidia.com/gpu"
      value  = "true"
      effect = "NoSchedule"
    }
  }
}

# Kubeconfig generation
resource "local_file" "kubeconfig" {
  content  = infomaniak_kubernetes_cluster.main.kubeconfig
  filename = "${path.module}/kubeconfig.yaml"
  
  file_permission = "0600"
}

# Outputs
output "cluster_id" {
  description = "ID du cluster"
  value       = infomaniak_kubernetes_cluster.main.id
}

output "cluster_endpoint" {
  description = "Endpoint API server"
  value       = infomaniak_kubernetes_cluster.main.endpoint
  sensitive   = true
}

output "kubeconfig" {
  description = "Kubeconfig content"
  value       = infomaniak_kubernetes_cluster.main.kubeconfig
  sensitive   = true
}

output "node_pool_ids" {
  description = "IDs des node pools"
  value       = { for k, v in infomaniak_kubernetes_node_pool.pools : k => v.id }
}
