#!/bin/bash
# Script de backup et restauration du cluster
# Usage: ./backup-restore.sh [backup|restore|list]

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
TERRAFORM_DIR="terraform/environments/prod"
BACKUP_DIR="backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Fonction backup
backup() {
    echo -e "${GREEN}=== Backup du cluster ===${NC}"
    echo "Timestamp: $(date)"
    
    export KUBECONFIG="$TERRAFORM_DIR/kubeconfig.yaml"
    
    if ! kubectl cluster-info &> /dev/null; then
        echo -e "${RED}Erreur: Cluster non accessible${NC}"
        exit 1
    fi
    
    mkdir -p "$BACKUP_DIR"
    
    local backup_file="$BACKUP_DIR/backup-$TIMESTAMP"
    
    echo "Backup des ressources Kubernetes..."
    
    # Namespaces
    kubectl get namespaces -o yaml > "$backup_file-namespaces.yaml"
    
    # ConfigMaps
    kubectl get configmap --all-namespaces -o yaml > "$backup_file-configmaps.yaml"
    
    # Secrets (attention données sensibles)
    kubectl get secret --all-namespaces -o yaml > "$backup_file-secrets.yaml"
    
    # Services
    kubectl get svc --all-namespaces -o yaml > "$backup_file-services.yaml"
    
    # Deployments
    kubectl get deployment --all-namespaces -o yaml > "$backup_file-deployments.yaml"
    
    # StatefulSets
    kubectl get statefulset --all-namespaces -o yaml > "$backup_file-statefulsets.yaml"
    
    # DaemonSets
    kubectl get daemonset --all-namespaces -o yaml > "$backup_file-daemonsets.yaml"
    
    # PersistentVolumeClaims
    kubectl get pvc --all-namespaces -o yaml > "$backup_file-pvcs.yaml"
    
    # Ingress
    kubectl get ingress --all-namespaces -o yaml > "$backup_file-ingress.yaml"
    
    # NetworkPolicies
    kubectl get networkpolicy --all-namespaces -o yaml > "$backup_file-networkpolicies.yaml"
    
    # CronJobs
    kubectl get cronjob --all-namespaces -o yaml > "$backup_file-cronjobs.yaml"
    
    # Jobs
    kubectl get job --all-namespaces -o yaml > "$backup_file-jobs.yaml"
    
    # Créer un tarball compressé
    tar -czf "$backup_file.tar.gz" "$backup_file"-*.yaml
    rm "$backup_file"-*.yaml
    
    # Lien symbolique vers le dernier backup
    ln -sf "backup-$TIMESTAMP.tar.gz" "$BACKUP_DIR/latest-backup.tar.gz"
    
    echo ""
    echo -e "${GREEN}✓ Backup créé avec succès${NC}"
    echo "Fichier: $backup_file.tar.gz"
    echo "Taille: $(du -h "$backup_file.tar.gz" | cut -f1)"
    
    # Uploader vers S3 si configuré
    if command -v aws &> /dev/null && [ -n "$S3_BUCKET" ]; then
        echo ""
        echo "Upload vers S3..."
        aws s3 cp "$backup_file.tar.gz" "s3://$S3_BUCKET/backups/" --endpoint-url "$S3_ENDPOINT"
        echo -e "${GREEN}✓ Backup uploadé vers S3${NC}"
    fi
    
    # Nettoyer les anciens backups (garder les 7 derniers)
    echo ""
    echo "Nettoyage des anciens backups..."
    cd "$BACKUP_DIR"
    ls -t backup-*.tar.gz | tail -n +8 | xargs -r rm
    echo "Backups conservés: $(ls -1 backup-*.tar.gz 2>/dev/null | wc -l)"
}

# Fonction restore
restore() {
    echo -e "${YELLOW}=== Restauration du cluster ===${NC}"
    
    export KUBECONFIG="$TERRAFORM_DIR/kubeconfig.yaml"
    
    if ! kubectl cluster-info &> /dev/null; then
        echo -e "${RED}Erreur: Cluster non accessible${NC}"
        exit 1
    fi
    
    local restore_file=""
    
    if [ -z "$1" ]; then
        # Utiliser le dernier backup
        if [ -f "$BACKUP_DIR/latest-backup.tar.gz" ]; then
            restore_file="$BACKUP_DIR/latest-backup.tar.gz"
        else
            echo -e "${RED}Erreur: Aucun backup trouvé${NC}"
            exit 1
        fi
    else
        restore_file="$1"
        if [ ! -f "$restore_file" ]; then
            echo -e "${RED}Erreur: Fichier $restore_file non trouvé${NC}"
            exit 1
        fi
    fi
    
    echo "Restauration depuis: $restore_file"
    echo ""
    
    # Confirmation
    read -p "Confirmer la restauration? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Restauration annulée"
        exit 0
    fi
    
    # Extraire le backup
    local temp_dir=$(mktemp -d)
    tar -xzf "$restore_file" -C "$temp_dir"
    
    echo "Application des ressources..."
    
    # Ordre de restauration
    local resources=(
        "namespaces"
        "configmaps"
        "secrets"
        "pvcs"
        "services"
        "deployments"
        "statefulsets"
        "daemonsets"
        "ingress"
        "networkpolicies"
        "cronjobs"
        "jobs"
    )
    
    for resource in "${resources[@]}"; do
        local file=$(find "$temp_dir" -name "*-${resource}.yaml" | head -1)
        if [ -f "$file" ]; then
            echo "  Restauration: $resource"
            kubectl apply -f "$file" 2>/dev/null || echo "    Warning: Erreurs lors de la restauration de $resource"
        fi
    done
    
    # Nettoyage
    rm -rf "$temp_dir"
    
    echo ""
    echo -e "${GREEN}✓ Restauration terminée${NC}"
    echo ""
    echo "Vérification des ressources:"
    kubectl get pods --all-namespaces
}

# Fonction list
list_backups() {
    echo -e "${GREEN}=== Liste des backups ===${NC}"
    echo ""
    
    if [ ! -d "$BACKUP_DIR" ]; then
        echo "Aucun backup trouvé"
        exit 0
    fi
    
    cd "$BACKUP_DIR"
    
    if [ ! -f backup-*.tar.gz ]; then
        echo "Aucun backup trouvé"
        exit 0
    fi
    
    echo "Backups disponibles:"
    echo ""
    printf "%-25s %-10s %-20s\n" "FICHIER" "TAILLE" "DATE"
    echo "-----------------------------------------------------------"
    
    for backup in $(ls -t backup-*.tar.gz); do
        local size=$(du -h "$backup" | cut -f1)
        local date=$(echo "$backup" | sed 's/backup-\(.*\)\.tar\.gz/\1/' | sed 's/\([0-9]\{8\}\)-\([0-9]\{6\}\)/\1 \2/')
        printf "%-25s %-10s %-20s\n" "$backup" "$size" "$date"
    done
    
    echo ""
    echo "Dernier backup: $(readlink latest-backup.tar.gz 2>/dev/null || echo 'N/A')"
}

# Main
case "${1:-}" in
    backup)
        backup
        ;;
    restore)
        restore "${2:-}"
        ;;
    list)
        list_backups
        ;;
    *)
        echo "Usage: $0 {backup|restore|list}"
        echo ""
        echo "  backup           Créer un nouveau backup"
        echo "  restore [file]   Restaurer depuis un backup (dernier par défaut)"
        echo "  list             Lister les backups disponibles"
        exit 1
        ;;
esac
