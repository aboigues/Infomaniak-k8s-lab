#!/bin/bash
# Script d'arrêt du lab Kubernetes
# Usage: ./lab-stop.sh

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TERRAFORM_DIR="terraform/environments/prod"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${YELLOW}=== Arrêt Lab Kubernetes Infomaniak ===${NC}"
echo "Timestamp: $TIMESTAMP"
echo ""

# Vérifier si des nodes sont actifs
RUNNING_NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l || echo "0")
if [ "$RUNNING_NODES" -eq 0 ]; then
    echo -e "${GREEN}Aucun node actif, rien à faire${NC}"
    exit 0
fi

echo -e "${YELLOW}$RUNNING_NODES node(s) actif(s) détecté(s)${NC}"

# Confirmation
read -p "Voulez-vous arrêter le lab? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# Sauvegarder l'état du cluster
echo -e "${GREEN}Sauvegarde de l'état du cluster...${NC}"
./scripts/backup-cluster-state.sh

# Calculer et afficher les coûts de la session
if [ -f /tmp/lab-start-time ]; then
    START_TIME=$(cat /tmp/lab-start-time)
    echo -e "${YELLOW}Session démarrée: $START_TIME${NC}"
    ./scripts/calculate-costs.sh
fi

# Scale down tous les deployments non-système
echo -e "${YELLOW}Scale down des workloads...${NC}"
for ns in $(kubectl get ns -o jsonpath='{.items[*].metadata.name}' | grep -v "kube-" | grep -v "default"); do
    echo "  Namespace: $ns"
    kubectl scale deployment --all --replicas=0 -n $ns 2>/dev/null || true
done

# Attendre quelques secondes
sleep 5

# Arrêter les nodes via Terraform
echo -e "${GREEN}Arrêt des nodes via Terraform...${NC}"
cd $TERRAFORM_DIR

terraform apply \
    -var="lab_mode=stopped" \
    -auto-approve

cd ../../..

# Vérifier que les nodes sont arrêtés
echo -e "${YELLOW}Vérification arrêt des nodes...${NC}"
sleep 10

REMAINING_NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l || echo "0")
if [ "$REMAINING_NODES" -gt 0 ]; then
    echo -e "${RED}Attention: $REMAINING_NODES node(s) encore actif(s)${NC}"
    echo "Les nodes peuvent prendre quelques minutes à s'arrêter complètement"
else
    echo -e "${GREEN}Tous les nodes sont arrêtés${NC}"
fi

# Nettoyer les fichiers temporaires
rm -f /tmp/lab-start-time

echo ""
echo -e "${GREEN}=== Lab arrêté avec succès! ===${NC}"
echo -e "${GREEN}Coûts minimisés - Seul le stockage reste facturé${NC}"
echo ""
echo "Pour redémarrer: make start"
