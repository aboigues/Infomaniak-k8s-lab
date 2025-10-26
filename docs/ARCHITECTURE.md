# Architecture détaillée

## Vue d'ensemble

Infrastructure Kubernetes sur Infomaniak Public Cloud optimisée pour un usage intermittent (4-5h/semaine).

## Composants principaux

### 1. Cluster Kubernetes managé

**Type**: Shared Control Plane
- Control plane gratuit et permanent
- Configuration préservée même sans nodes
- API server accessible 24/7
- ETCD et control plane managés par Infomaniak

**Avantages**:
- Zéro coût pour le control plane
- Pas de gestion des masters
- Mises à jour automatiques
- Haute disponibilité incluse

### 2. Architecture réseau

```
┌─────────────────────────────────────────┐
│         Load Balancer Public            │
│         (0.015 CHF/h si actif)          │
└────────────┬────────────────────────────┘
             │
    ┌────────┴────────┐
    │  Network 10.0.0.0/16  │
    └────────┬────────┘
             │
    ┌────────┴──────────┬──────────────┐
    │                   │              │
┌───┴────┐      ┌──────┴─────┐   ┌───┴────┐
│ Subnet │      │  Subnet    │   │Subnet  │
│Workers │      │ Services   │   │  DB    │
│.1.0/24 │      │  .2.0/24   │   │.3.0/24 │
└────────┘      └────────────┘   └────────┘
```

### 3. Node Pools configuration

**General Purpose Pool**:
```
Type: a1-ram2-disk20-perf1
vCPU: 1
RAM: 2GB
Disk: 20GB NVMe
Coût: 0.03 CHF/h
Min: 0 (par défaut)
Max: 3
```

**Memory Pool**:
```
Type: a1-ram4-disk50-perf1
vCPU: 2
RAM: 4GB
Disk: 50GB NVMe
Coût: 0.06 CHF/h
Min: 0 (par défaut)
Max: 3
```

**AI/GPU Pool**:
```
Type: g1-gpu-1-l4
vCPU: 4
RAM: 16GB
GPU: NVIDIA L4
Coût: 2.50 CHF/h
Min: 0 (par défaut)
Max: 1
```

### 4. Stockage

**Block Storage (Volumes persistants)**:
- Type: NVMe haute performance
- Taille: 50GB par défaut
- Coût: 0.10 CHF/GB/mois
- Persistent entre sessions
- Snapshots automatiques

**Object Storage S3**:
- Endpoint: s3.pub1.infomaniak.cloud
- Bucket: lab-artifacts
- Taille: 100GB
- Coût: 0.03 CHF/GB/mois
- Versioning activé
- Lifecycle policies: 30 jours

### 5. Sécurité

**Network Policies**:
- Isolation par namespace
- Règles par défaut restrictives
- Communication inter-pods contrôlée

**RBAC**:
- Rôles par namespace
- ServiceAccounts dédiés
- Principe du moindre privilège

**Secrets Management**:
- Kubernetes Secrets natifs
- Chiffrement au repos
- Rotation manuelle

### 6. Monitoring

**Stack légère**:
```
Prometheus:
  CPU: 500m
  Memory: 1GB
  Retention: 2 jours
  
Grafana:
  CPU: 250m
  Memory: 512MB
  Dashboards: Coûts, uptime, ressources
```

## Flux de travail typique

### Démarrage session
```
1. make start PROFILE=standard
2. Terraform scale node pools 0→2
3. Attente nodes ready (2-3 min)
4. Restauration workloads depuis backup
5. Lab opérationnel
```

### Session active
```
1. Développement/tests sur cluster
2. Monitoring coûts en temps réel
3. Alertes si uptime > 5h
4. Auto-shutdown après 6h
```

### Arrêt session
```
1. make stop
2. Backup état cluster → S3
3. Scale down workloads
4. Terraform scale node pools 2→0
5. Seul stockage reste facturé
```

## Optimisations coûts

### Stratégies implémentées

1. **Control plane gratuit**: Cluster shared = 0 CHF
2. **Nodes à 0 par défaut**: Min size = 0
3. **Facturation seconde**: Pas d'arrondi
4. **Auto-shutdown**: Protection oubli
5. **Monitoring coûts**: Dashboard temps réel
6. **Stockage optimisé**: S3 lifecycle policies
7. **Images cachées**: Pas de rebuild constant

### Résultat
- Coût 24/7: ~240 CHF/mois
- Coût on-demand: ~11-21 CHF/mois
- **Économie: 92%**

## Évolutivité

### Ajout de nodes
```bash
# Via Terraform
terraform apply -var="profile=memory"

# Via kubectl (temporaire)
kubectl scale deployment --replicas=5
```

### Ajout de node pool
```hcl
# Dans main.tf
custom = {
  name         = "custom-pool"
  instance_type = "a1-ram8-disk100-perf2"
  min_nodes    = 0
  max_nodes    = 2
}
```

## Haute disponibilité

Pour production (hors scope lab):
- Passer en cluster Dedicated
- Min 3 nodes par pool
- Multi-zone deployment
- Load balancer redondant
- Database managed avec réplication

## Intégrations

### CI/CD
- GitLab CI
- GitHub Actions
- ArgoCD pour GitOps

### Monitoring externe
- Prometheus remote write
- Grafana Cloud
- Alertmanager

### Backup
- Velero pour backup complet
- S3 pour artifacts
- Snapshots volumes

## Limites connues

1. **Cluster shared**:
   - Pas de SLA
   - Control plane partagé
   - Max 10 nodes

2. **Cold start**:
   - 2-3 minutes démarrage nodes
   - Restauration workloads nécessaire

3. **Persistance**:
   - State cluster à sauvegarder
   - Volumes persistent mais pods non

## Prochaines étapes

1. Implémenter External Secrets Operator
2. Ajouter Velero pour backup complet
3. Configurer Prometheus remote write
4. Ajouter ArgoCD pour GitOps
5. Implémenter Network Policies avancées
