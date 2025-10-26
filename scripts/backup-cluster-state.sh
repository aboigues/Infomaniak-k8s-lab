#!/bin/bash
# Script de backup de l'état du cluster
# Usage: ./backup-cluster-state.sh

set -e

BACKUP_DIR="backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/cluster-state-${TIMESTAMP}.yaml"
LATEST_LINK="${BACKUP_DIR}/cluster-state-latest.yaml"

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Backup état cluster ===${NC}"
echo "Fichier: $BACKUP_FILE"

# Créer le répertoire de backup
mkdir -p $BACKUP_DIR

# Backup de toutes les ressources
echo -e "${YELLOW}Backup des ressources Kubernetes...${NC}"

cat > $BACKUP_FILE <<EOF
# Backup cluster Kubernetes - $TIMESTAMP
# Généré automatiquement
---
EOF

# Namespaces (hors système)
echo "Backup namespaces..."
kubectl get ns -o yaml | grep -v "kube-" | grep -v "default" >> $BACKUP_FILE 2>/dev/null || true

# Deployments
echo "Backup deployments..."
for ns in $(kubectl get ns -o jsonpath='{.items[*].metadata.name}' | grep -v "kube-" | grep -v "default"); do
    kubectl get deploy -n $ns -o yaml >> $BACKUP_FILE 2>/dev/null || true
done

# Services
echo "Backup services..."
for ns in $(kubectl get ns -o jsonpath='{.items[*].metadata.name}' | grep -v "kube-" | grep -v "default"); do
    kubectl get svc -n $ns -o yaml >> $BACKUP_FILE 2>/dev/null || true
done

# ConfigMaps
echo "Backup configmaps..."
for ns in $(kubectl get ns -o jsonpath='{.items[*].metadata.name}' | grep -v "kube-" | grep -v "default"); do
    kubectl get cm -n $ns -o yaml >> $BACKUP_FILE 2>/dev/null || true
done

# Secrets (attention: sensible!)
echo "Backup secrets..."
for ns in $(kubectl get ns -o jsonpath='{.items[*].metadata.name}' | grep -v "kube-" | grep -v "default"); do
    kubectl get secret -n $ns -o yaml >> $BACKUP_FILE 2>/dev/null || true
done

# PersistentVolumeClaims
echo "Backup PVCs..."
kubectl get pvc --all-namespaces -o yaml >> $BACKUP_FILE 2>/dev/null || true

# Ingress
echo "Backup ingress..."
kubectl get ingress --all-namespaces -o yaml >> $BACKUP_FILE 2>/dev/null || true

# Créer lien symbolique vers dernière version
ln -sf $(basename $BACKUP_FILE) $LATEST_LINK

# Upload vers S3 si configuré
if [ ! -z "$S3_BUCKET_NAME" ]; then
    echo -e "${YELLOW}Upload vers S3...${NC}"
    aws s3 cp $BACKUP_FILE s3://${S3_BUCKET_NAME}/backups/ --endpoint-url=$S3_ENDPOINT 2>/dev/null || echo "Upload S3 échoué (non critique)"
fi

# Nettoyer les anciens backups (garder 7 derniers)
echo "Nettoyage anciens backups..."
ls -t $BACKUP_DIR/cluster-state-*.yaml | tail -n +8 | xargs rm -f 2>/dev/null || true

BACKUP_SIZE=$(du -h $BACKUP_FILE | cut -f1)
echo -e "${GREEN}Backup terminé: $BACKUP_FILE ($BACKUP_SIZE)${NC}"
