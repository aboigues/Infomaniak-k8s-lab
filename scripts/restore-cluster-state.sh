#!/bin/bash
# Script de restore de l'état du cluster
# Usage: ./restore-cluster-state.sh [backup_file]

set -e

BACKUP_FILE=${1:-"backups/cluster-state-latest.yaml"}

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Restore état cluster ===${NC}"

# Vérifier que le fichier existe
if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}Erreur: Fichier backup non trouvé: $BACKUP_FILE${NC}"
    echo "Fichiers disponibles:"
    ls -lh backups/cluster-state-*.yaml 2>/dev/null || echo "Aucun backup trouvé"
    exit 1
fi

echo "Fichier: $BACKUP_FILE"
BACKUP_SIZE=$(du -h $BACKUP_FILE | cut -f1)
echo "Taille: $BACKUP_SIZE"
echo ""

# Confirmation
read -p "Voulez-vous restaurer cet état? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# Attendre que les nodes soient prêts
echo -e "${YELLOW}Vérification nodes...${NC}"
kubectl wait --for=condition=Ready nodes --all --timeout=300s || {
    echo -e "${RED}Les nodes ne sont pas prêts${NC}"
    exit 1
}

# Appliquer le backup
echo -e "${GREEN}Restauration en cours...${NC}"

# Filtrer et appliquer les ressources
kubectl apply -f $BACKUP_FILE 2>&1 | grep -v "unchanged" | grep -v "configured" || true

# Attendre que les pods soient prêts
echo -e "${YELLOW}Attente démarrage des pods...${NC}"
sleep 10

# Afficher l'état
echo ""
echo -e "${GREEN}État après restauration:${NC}"
kubectl get pods --all-namespaces

echo ""
echo -e "${GREEN}Restauration terminée${NC}"
