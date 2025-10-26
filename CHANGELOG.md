# Changelog

## [1.0.0] - 2025-10-25

### Ajouté
- Infrastructure Terraform complète pour Infomaniak Public Cloud
- Modules: network, kubernetes, storage
- Scripts automation: start, stop, backup, restore, cost calculation
- Configuration à la demande avec nodes à min=0
- 4 profiles prédéfinis: minimal, standard, memory, ai
- Documentation complète (Architecture, Troubleshooting, Labs)
- Labs Docker: construction images optimisées
- Labs Kubernetes: fundamentals avec 6 exercices
- Makefile avec commandes simplifiées
- Auto-shutdown après 5h pour protection coûts
- Dashboard coûts en temps réel
- Backup/restore automatique vers S3
- Support GPU NVIDIA L4 pour workloads IA
- Network policies et security groups
- Monitoring léger avec Prometheus/Grafana
- Intégration CI/CD avec GitLab/GitHub
- Configuration .env pour credentials
- Exemples de manifests Kubernetes
- Guide de démarrage rapide
- Support multi-profiles simultanés

### Caractéristiques
- Coût optimisé: 11-21 CHF/mois (vs. 240 CHF en 24/7)
- Économie: 92%
- Démarrage rapide: 2-3 minutes
- Control plane gratuit (cluster shared)
- Stockage persistent entre sessions
- Facturation à la seconde

### Infrastructure
- Kubernetes 1.28+
- Cilium CNI
- NGINX Ingress Controller
- Cert-manager pour SSL
- Object Storage S3
- Block storage NVMe
- Load Balancer managé
- Réseau privé 10.0.0.0/16

### Sécurité
- RBAC configuré
- Network policies
- Secrets management
- Security groups
- SSL/TLS automatique

### Documentation
- README principal
- QUICKSTART guide
- Architecture détaillée
- Guide troubleshooting
- Labs avec exercices pratiques
- Exemples de code
- Diagrammes réseau

## Roadmap

### [1.1.0] - À venir
- ArgoCD pour GitOps
- External Secrets Operator
- Velero pour backup complet
- Monitoring avancé avec Loki
- Prometheus remote write
- Dashboard Grafana enrichi
- Plus de labs IA/ML
- Support multi-régions
- Terraform Cloud backend

### [1.2.0] - Futur
- Cluster dedicated en option
- Multi-tenancy avancé
- Service Mesh (Istio/Linkerd)
- Observability complète
- Chaos engineering
- Policy as Code (OPA)
- Cost optimization avancée
