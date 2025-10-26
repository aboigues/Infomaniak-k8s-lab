terraform {
  required_version = ">= 1.6"
  
  required_providers {
    infomaniak = {
      source  = "infomaniak/infomaniak"
      version = "~> 1.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }

  # Backend S3 pour state (optionnel)
  # backend "s3" {
  #   bucket = "lab-terraform-state"
  #   key    = "prod/terraform.tfstate"
  #   region = "ch-dc3"
  #   endpoint = "https://s3.pub1.infomaniak.cloud"
  # }
}

provider "infomaniak" {
  api_token  = var.infomaniak_api_token
  project_id = var.infomaniak_project_id
}

# Variables
variable "infomaniak_api_token" {
  description = "Token API Infomaniak"
  type        = string
  sensitive   = true
}

variable "infomaniak_project_id" {
  description = "ID du projet Infomaniak"
  type        = string
}

variable "lab_mode" {
  description = "Mode du lab: active ou stopped"
  type        = string
  default     = "stopped"
  validation {
    condition     = contains(["active", "stopped"], var.lab_mode)
    error_message = "lab_mode doit être 'active' ou 'stopped'"
  }
}

variable "profile" {
  description = "Profile de déploiement: minimal, standard, memory, ai"
  type        = string
  default     = "standard"
}

# Module réseau
module "network" {
  source = "../../modules/network"
  
  cluster_name = "lab-cluster-k8s"
  network_cidr = "10.0.0.0/16"
  subnets = {
    workers  = "10.0.1.0/24"
    services = "10.0.2.0/24"
  }
}

# Module Kubernetes
module "kubernetes" {
  source = "../../modules/kubernetes"
  
  cluster_name   = "lab-cluster-k8s"
  cluster_region = "ch-dc3-a"
  cluster_type   = "shared"  # shared ou dedicated
  
  network_id = module.network.network_id
  
  # Configuration node pools selon profile
  node_pools = var.lab_mode == "active" ? local.profiles[var.profile] : {}
  
  depends_on = [module.network]
}

# Module stockage
module "storage" {
  source = "../../modules/storage"
  
  s3_bucket_name    = "lab-artifacts"
  s3_versioning     = true
  
  persistent_volumes = {
    "lab-data" = {
      size_gb = 50
      type    = "standard"
    }
    "monitoring-data" = {
      size_gb = 20
      type    = "standard"
    }
  }
}

# Configuration profiles
locals {
  profiles = {
    minimal = {
      general = {
        name         = "general-pool"
        instance_type = "a1-ram2-disk20-perf1"
        min_nodes    = 1
        max_nodes    = 1
        desired_nodes = 1
      }
    }
    
    standard = {
      general = {
        name         = "general-pool"
        instance_type = "a1-ram2-disk20-perf1"
        min_nodes    = 2
        max_nodes    = 3
        desired_nodes = 2
      }
    }
    
    memory = {
      general = {
        name         = "general-pool"
        instance_type = "a1-ram2-disk20-perf1"
        min_nodes    = 1
        max_nodes    = 2
        desired_nodes = 1
      }
      memory = {
        name         = "memory-pool"
        instance_type = "a1-ram4-disk50-perf1"
        min_nodes    = 2
        max_nodes    = 3
        desired_nodes = 2
      }
    }
    
    ai = {
      general = {
        name         = "general-pool"
        instance_type = "a1-ram2-disk20-perf1"
        min_nodes    = 1
        max_nodes    = 1
        desired_nodes = 1
      }
      gpu = {
        name         = "ai-pool"
        instance_type = "g1-gpu-1-l4"
        min_nodes    = 1
        max_nodes    = 1
        desired_nodes = 1
      }
    }
  }
}

# Outputs
output "cluster_endpoint" {
  description = "Endpoint du cluster Kubernetes"
  value       = module.kubernetes.cluster_endpoint
  sensitive   = true
}

output "kubeconfig" {
  description = "Fichier kubeconfig pour accès cluster"
  value       = module.kubernetes.kubeconfig
  sensitive   = true
}

output "current_mode" {
  description = "Mode actuel du lab"
  value       = var.lab_mode
}

output "active_profile" {
  description = "Profile actif"
  value       = var.profile
}

output "s3_bucket_endpoint" {
  description = "Endpoint du bucket S3"
  value       = module.storage.s3_bucket_endpoint
}
