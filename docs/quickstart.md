# Guide de démarrage rapide

Ce guide vous permettra de démarrer votre lab Kubernetes sur Infomaniak en quelques minutes.

## Prérequis

1. Compte Infomaniak avec accès Public Cloud
2. Terraform ou OpenTofu >= 1.6 installé
3. kubectl >= 1.28 installé
4. Git installé

## Étape 1 : Configuration initiale

### 1.1 Cloner le repository

```bash
git clone <votre-repo>
cd infomaniak-k8s-lab
```

### 1.2 Obtenir les identifiants Infomaniak

Connectez-vous à la console Infomaniak :

1. Aller sur https://manager.infomaniak.com
2. Accéder à Public Cloud > OpenStack
3. Récupérer vos credentials OpenStack :
   - Nom du projet (tenant_name)
   - Username
   - Password

### 1.3 Obtenir l'ID du réseau externe

```bash
# Installer OpenStack CLI si nécessaire
pip install python-openstackclient

# Configurer les variables d'environnement
export OS_AUTH_URL=https://api.pub1.infomaniak.cloud/identity/v3
export OS_PROJECT_NAME=votre-projet
export OS_USERNAME=votre-username
export OS_PASSWORD=votre-password
export OS_REGION_NAME=ch-dc3-a
export OS_INTERFACE=public
export OS_IDENTITY_API_VERSION=3

# Lister les réseaux externes
openstack network list --external
```

### 1.4 Créer une keypair SSH

```bash
# Créer une paire de clés
ssh-keygen -t rsa -b 4096 -f ~/.ssh/infomaniak-k8s-lab

# Importer dans Infomaniak
openstack keypair create --public-key ~/.ssh/infomaniak-k8s-lab.pub infomaniak-k8s-lab
```

### 1.5 Configurer Terraform

```bash
cd terraform/environments/prod

# Copier le fichier d'exemple
cp terraform.tfvars.example terraform.tfvars

# Éditer avec vos valeurs
vim terraform.tfvars
```

Remplir les valeurs :

```hcl
openstack_tenant_name = "votre-projet"
openstack_username    = "votre-username"
openstack_password    = "votre-password"
external_network_id   = "id-du-reseau-externe"
cluster_template_id   = "obtenir-via-api"  # Voir étape suivante
keypair_name          = "infomaniak-k8s-lab"
```

### 1.6 Obtenir l'ID du template Kubernetes

Le template Kubernetes peut varier. Contacter le support Infomaniak ou consulter la documentation pour obtenir l'ID du template.

## Étape 2 : Déploiement initial

### 2.1 Initialiser Terraform

```bash
cd terraform/environments/prod
terraform init
```

### 2.2 Vérifier le plan

```bash
terraform plan
```

### 2.3 Déployer l'infrastructure (lab arrêté)

```bash
# Déploiement avec nodes à 0 (pas de coûts de compute)
terraform apply
```

Cette étape crée :
- Le cluster Kubernetes (control plane gratuit)
- Les réseaux privés
- Le stockage S3
- Les volumes persistants
- Configuration à 0 nodes (arrêté)

### 2.4 Exporter le kubeconfig

```bash
terraform output -raw kubeconfig > kubeconfig.yaml
export KUBECONFIG=$(pwd)/kubeconfig.yaml
```

## Étape 3 : Premier démarrage

### 3.1 Retour à la racine du projet

```bash
cd ../../..
```

### 3.2 Démarrer le lab (profil standard)

```bash
make start profile=standard
```

Cette commande :
- Démarre 2 nodes general + 1 node memory
- Attend que les nodes soient prêts
- Configure kubectl
- Coût : ~0.12 CHF/h

### 3.3 Vérifier les nodes

```bash
kubectl get nodes -o wide
```

Vous devriez voir 3 nodes en status Ready.

### 3.4 Déployer les composants de base

```bash
make deploy-base
```

Ceci installe :
- Namespaces pour les labs
- Ingress NGINX controller
- Stack monitoring (Prometheus/Grafana)

## Étape 4 : Premiers tests

### 4.1 Déployer une application de test

```bash
kubectl apply -f kubernetes/examples/nginx-demo.yaml
```

### 4.2 Vérifier le déploiement

```bash
kubectl get pods -n lab-k8s
kubectl get svc -n lab-k8s
```

### 4.3 Accéder à l'application

```bash
# Port-forward pour test local
kubectl port-forward -n lab-k8s svc/nginx-demo 8080:80
```

Ouvrir http://localhost:8080

## Étape 5 : Arrêt du lab

### 5.1 Arrêter proprement

```bash
make stop
```

Cette commande :
- Sauvegarde l'état du cluster
- Scale les workloads à 0
- Arrête tous les nodes (coût → 0 CHF/h)
- Le control plane reste actif (gratuit)

### 5.2 Vérifier l'arrêt

```bash
make status
```

## Étape 6 : Utilisation quotidienne

### Démarrer une session de travail

```bash
# Profil minimal (1 node)
make start profile=minimal

# Profil standard (3 nodes)
make start profile=standard

# Profil IA (3 nodes + GPU)
make start profile=ai
```

### Travailler dans le lab

```bash
# Vérifier le status
make status

# Voir les coûts
make costs

# Lister les nodes
make nodes

# Voir les pods
make pods
```

### Terminer la session

```bash
# Arrêt propre
make stop

# OU arrêt forcé sans confirmation
make stop-force
```

## Commandes utiles

```bash
# Aide
make help

# Status complet
make status

# Coûts actuels
make costs

# Backup manuel
make backup

# Restore
make restore

# Afficher kubeconfig
make kubeconfig

# Shell avec KUBECONFIG
make shell
```

## Sécurité financière

Le lab inclut plusieurs protections :

1. **Auto-shutdown** : Arrêt automatique après 5h
2. **Alertes** : Notification à 4h d'uptime
3. **Dashboard coûts** : Suivi en temps réel
4. **Budget tracking** : Alerte si dépassement hebdomadaire

## Coûts typiques

### Par session

| Durée | Profil | Coût |
|-------|--------|------|
| 1h | Minimal | 0.03 CHF |
| 2h | Standard | 0.24 CHF |
| 2h | AI (avec GPU) | 5.24 CHF |

### Mensuel (20h/mois)

| Composant | Coût |
|-----------|------|
| Fixe (S3 + volumes) | 8 CHF |
| Sessions standard | 2.7 CHF |
| **Total** | **~11 CHF/mois** |

Avec GPU occasionnel : ~21 CHF/mois

## Troubleshooting

### Nodes ne démarrent pas

```bash
# Vérifier Terraform
cd terraform/environments/prod
terraform refresh
terraform plan

# Vérifier les quotas OpenStack
openstack quota show
```

### Cluster non accessible

```bash
# Vérifier le kubeconfig
cat terraform/environments/prod/kubeconfig.yaml

# Réexporter
export KUBECONFIG=$(pwd)/terraform/environments/prod/kubeconfig.yaml

# Tester la connexion
kubectl cluster-info
```

### Coûts inattendus

```bash
# Vérifier les nodes actifs
kubectl get nodes

# Forcer l'arrêt
make stop-force

# Vérifier via Terraform
cd terraform/environments/prod
terraform output node_pools_status
```

## Prochaines étapes

- Consulter [Labs Docker](labs-docker.md)
- Consulter [Labs Kubernetes](labs-kubernetes.md)
- Consulter [Labs IA](labs-ai.md)
- Explorer [Architecture détaillée](architecture.md)

## Support

- Issues GitHub : Créer un issue
- Documentation Infomaniak : https://docs.infomaniak.cloud
- Support Infomaniak : https://support.infomaniak.com
