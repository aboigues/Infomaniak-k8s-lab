#!/bin/bash
# Script de démarrage du lab Kubernetes
# Usage: ./lab-start.sh [profile]

set -e

# Couleurs pour output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables
PROFILE=${1:-standard}
TERRAFORM_DIR="terraform/environments/prod"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${GREEN}=== Démarrage Lab Kubernetes Infomaniak ===${NC}"
echo "Profile: $PROFILE"
echo "Timestamp: $TIMESTAMP"
echo ""

# Vérifier que le profile est valide
valid_profiles=("minimal" "standard" "memory" "ai")
if [[ ! " ${valid_profiles[@]} " =~ " ${PROFILE} " ]]; then
    echo -e "${RED}Erreur: Profile '$PROFILE' invalide${NC}"
    echo "Profiles valides: ${valid_profiles[*]}"
    exit 1
fi

# Charger les variables d'environnement
if [ -f .env ]; then
    echo -e "${YELLOW}Chargement configuration...${NC}"
    source .env
else
    echo -e "${RED}Erreur: Fichier .env non trouvé${NC}"
    echo "Copiez .env.example vers .env et configurez-le"
    exit 1
fi

# Vérifier l'état actuel
echo -e "${YELLOW}Vérification état actuel...${NC}"
if kubectl get nodes &>/dev/null; then
    RUNNING_NODES=$(kubectl get nodes --no-headers | wc -l)
    if [ "$RUNNING_NODES" -gt 0 ]; then
        echo -e "${YELLOW}Attention: $RUNNING_NODES nodes déjà actifs${NC}"
        read -p "Voulez-vous continuer? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
fi

# Backup de l'état actuel si nodes actifs
if [ "$RUNNING_NODES" -gt 0 ]; then
    echo -e "${YELLOW}Sauvegarde état actuel...${NC}"
    ./scripts/backup-cluster-state.sh
fi

# Démarrer avec Terraform
echo -e "${GREEN}Démarrage des nodes via Terraform...${NC}"
cd $TERRAFORM_DIR

terraform apply \
    -var="lab_mode=active" \
    -var="profile=$PROFILE" \
    -auto-approve

cd ../../..

# Attendre que les nodes soient prêts
echo -e "${YELLOW}Attente des nodes (peut prendre 2-3 minutes)...${NC}"
TIMEOUT=300
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready " || echo "0")
    if [ "$READY_NODES" -gt 0 ]; then
        echo -e "${GREEN}$READY_NODES node(s) prêt(s)!${NC}"
        break
    fi
    echo -n "."
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    echo -e "${RED}Timeout: Les nodes n'ont pas démarré dans le temps imparti${NC}"
    exit 1
fi

echo ""

# Restaurer les workloads si backup existe
if [ -f "backups/cluster-state-latest.yaml" ]; then
    echo -e "${YELLOW}Restauration des workloads...${NC}"
    ./scripts/restore-cluster-state.sh
fi

# Afficher l'état final
echo ""
echo -e "${GREEN}=== Lab démarré avec succès! ===${NC}"
kubectl get nodes
echo ""
kubectl get pods --all-namespaces
echo ""

# Calculer le coût estimé
echo -e "${YELLOW}=== Coûts estimés ===${NC}"
./scripts/calculate-costs.sh

# Enregistrer l'heure de démarrage
echo "$TIMESTAMP" > /tmp/lab-start-time

# Programmer l'auto-shutdown
echo ""
echo -e "${YELLOW}Auto-shutdown programmé après ${AUTO_SHUTDOWN_AFTER_HOURS}h${NC}"
echo -e "${RED}N'oubliez pas de faire 'make stop' à la fin!${NC}"

# Afficher les commandes utiles
echo ""
echo -e "${GREEN}Commandes utiles:${NC}"
echo "  make status  - Vérifier l'état"
echo "  make cost    - Calculer les coûts"
echo "  make stop    - Arrêter le lab"
echo "  make logs    - Voir les logs"
