# Lab Kubernetes sur Infomaniak - Infrastructure à la demande

Infrastructure de laboratoire Kubernetes optimisée pour un usage intermittent (4-5h/semaine), hébergée sur le Public Cloud Infomaniak.

## Caractéristiques

- **Coût optimisé**: ~11-21 CHF/mois (92% d'économie vs. 24/7)
- **Control plane gratuit**: Cluster Shared Infomaniak permanent
- **Nodes à la demande**: Scale automatique 0→N
- **Démarrage rapide**: 2-3 minutes
- **Auto-shutdown**: Protection contre oubli
- **Stockage persistent**: Données préservées entre sessions

## Prérequis

- Compte Infomaniak Public Cloud
- Terraform/OpenTofu >= 1.6
- kubectl >= 1.28
- Python 3.9+ (pour scripts automation)
- Make (optionnel mais recommandé)

## Installation rapide

```bash
# 1. Cloner et configurer
cd infomaniak-k8s-lab

# 2. Configurer credentials Infomaniak
cp .env.example .env
# Éditer .env avec vos credentials

# 3. Initialiser Terraform
cd terraform/environments/prod
terraform init

# 4. Déployer infrastructure (nodes à 0)
terraform apply

# 5. Configurer kubectl
export KUBECONFIG=./kubeconfig.yaml
```

## Utilisation

### Démarrer une session lab

```bash
make start                    # Profile standard (2 nodes)
make start PROFILE=minimal    # 1 node seulement
make start PROFILE=ai         # Avec GPU
```

### Arrêter la session

```bash
make stop
```

### Vérifier l'état

```bash
make status                   # État global
make cost                     # Coûts actuels
kubectl get nodes             # Nodes actifs
```

## Profiles disponibles

| Profile | Nodes | vCPU | RAM | Coût/h | Usage |
|---------|-------|------|-----|--------|-------|
| minimal | 1 | 1 | 2GB | 0.03 CHF | Docker, tests rapides |
| standard | 2-3 | 2-3 | 4-6GB | 0.09 CHF | Kubernetes, labs standard |
| memory | 3 | 4 | 12GB | 0.15 CHF | Databases, analytics |
| ai | 1+1 GPU | 5 | 6GB | 2.56 CHF | Machine Learning |

## Labs disponibles

1. **Docker basics** (1-2h, 0.06 CHF)
2. **Kubernetes fundamentals** (2-3h, 0.25 CHF)
3. **AI/ML avec GPU** (1-2h, 5 CHF)
4. **Automation & GitOps** (1h, 0.06 CHF)

## Documentation

- [Architecture détaillée](docs/ARCHITECTURE.md)
- [Guide Terraform](docs/TERRAFORM.md)
- [Labs et exercices](docs/LABS.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## Licence

MIT License
