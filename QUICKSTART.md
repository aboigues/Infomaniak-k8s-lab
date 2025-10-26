# Démarrage rapide - 5 minutes

## 1. Configuration initiale

```bash
# Copier la configuration
cp .env.example .env

# Éditer avec vos credentials Infomaniak
nano .env
```

Remplir:
- `INFOMANIAK_API_TOKEN`: Token depuis console Infomaniak
- `INFOMANIAK_PROJECT_ID`: ID de votre projet
- `ALERT_EMAIL`: Votre email

## 2. Initialiser Terraform

```bash
cd terraform/environments/prod
terraform init
cd ../../..
```

## 3. Déployer l'infrastructure

```bash
# Créer le cluster (nodes à 0)
make init
cd terraform/environments/prod
terraform apply
cd ../../..
```

## 4. Démarrer votre première session

```bash
# Démarrer avec profile minimal
make start PROFILE=minimal

# Attendre 2-3 minutes...
# Les nodes vont démarrer automatiquement
```

## 5. Vérifier que tout fonctionne

```bash
# Voir les nodes
kubectl get nodes

# Créer un namespace de test
kubectl create namespace test

# Déployer nginx
kubectl create deployment nginx --image=nginx -n test
kubectl get pods -n test
```

## 6. Arrêter la session

```bash
make stop
```

C'est tout! Vous avez maintenant:
- Un cluster Kubernetes fonctionnel
- Des coûts minimaux (~11 CHF/mois)
- Une infrastructure prête pour vos labs

## Prochaines étapes

1. Explorer les labs:
   - `kubernetes/labs/docker/` - Labs Docker
   - `kubernetes/labs/k8s/` - Labs Kubernetes
   - `kubernetes/labs/ai/` - Labs IA/ML

2. Personnaliser:
   - Modifier les profiles dans `terraform/environments/prod/main.tf`
   - Ajouter des node pools
   - Configurer monitoring

3. Automatiser:
   - Configurer CI/CD
   - Ajouter ArgoCD
   - Implémenter GitOps

## Commandes essentielles

```bash
make start              # Démarrer (profile standard)
make start PROFILE=ai   # Démarrer avec GPU
make stop               # Arrêter
make status             # État actuel
make cost               # Coûts estimés
make help               # Voir toutes les commandes
```

## Aide

- Documentation: `docs/`
- Troubleshooting: `docs/TROUBLESHOOTING.md`
- Architecture: `docs/ARCHITECTURE.md`
