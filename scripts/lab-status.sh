#!/bin/bash
# Script de status du Lab Kubernetes Infomaniak
# Usage: ./lab-status.sh

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TERRAFORM_DIR="terraform/environments/prod"

echo -e "${BLUE}=== Status du Lab Kubernetes Infomaniak ===${NC}"
echo "Timestamp: $(date)"
echo ""

# Vérification Terraform
check_terraform_state() {
    echo -e "${YELLOW}Infrastructure Terraform:${NC}"
    
    if [ ! -d "$TERRAFORM_DIR/.terraform" ]; then
        echo -e "${RED}  ✗ Terraform non initialisé${NC}"
        echo "  Exécuter: cd $TERRAFORM_DIR && terraform init"
        return 1
    fi
    
    cd $TERRAFORM_DIR
    
    # État du lab
    local lab_active=$(terraform output -raw lab_active 2>/dev/null || echo "unknown")
    
    if [ "$lab_active" == "true" ]; then
        echo -e "${GREEN}  ✓ Lab ACTIF${NC}"
    elif [ "$lab_active" == "false" ]; then
        echo -e "${YELLOW}  ○ Lab ARRÊTÉ${NC}"
    else
        echo -e "${RED}  ? État inconnu${NC}"
    fi
    
    # Node pools
    echo ""
    echo "Node pools:"
    terraform output -json node_pools_status 2>/dev/null | jq -r '
        to_entries[] | 
        "  - \(.key): \(.value.current_nodes)/\(.value.max_nodes) nodes"
    ' || echo "  Erreur lecture node pools"
    
    # Coût horaire
    local hourly_cost=$(terraform output -raw estimated_hourly_cost 2>/dev/null || echo "N/A")
    echo ""
    echo "Coût horaire actuel: $hourly_cost"
    
    cd - > /dev/null
}

# Vérification cluster Kubernetes
check_kubernetes_cluster() {
    echo ""
    echo -e "${YELLOW}Cluster Kubernetes:${NC}"
    
    export KUBECONFIG="$TERRAFORM_DIR/kubeconfig.yaml"
    
    if [ ! -f "$KUBECONFIG" ]; then
        echo -e "${RED}  ✗ Kubeconfig non trouvé${NC}"
        return 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        echo -e "${RED}  ✗ Cluster non accessible${NC}"
        echo "  Le lab est probablement arrêté"
        return 1
    fi
    
    echo -e "${GREEN}  ✓ Cluster accessible${NC}"
    
    # Nodes
    echo ""
    echo "Nodes:"
    kubectl get nodes -o wide 2>/dev/null | while IFS= read -r line; do
        echo "  $line"
    done
    
    # Ressources
    echo ""
    echo "Utilisation ressources:"
    kubectl top nodes 2>/dev/null | while IFS= read -r line; do
        echo "  $line"
    done || echo "  Metrics server non disponible"
    
    # Pods count
    echo ""
    local total_pods=$(kubectl get pods --all-namespaces --no-headers 2>/dev/null | wc -l)
    local running_pods=$(kubectl get pods --all-namespaces --no-headers 2>/dev/null | grep -c "Running" || echo "0")
    echo "Pods: $running_pods/$total_pods running"
}

# Calcul des coûts
calculate_costs() {
    echo ""
    echo -e "${YELLOW}Coûts estimés:${NC}"
    
    # Coûts fixes mensuels
    echo "Fixes (mensuels):"
    echo "  - Control plane: 0 CHF (shared gratuit)"
    echo "  - S3 Storage (100GB): 3 CHF"
    echo "  - Volumes (50GB): 5 CHF"
    echo "  Total fixe: ~8 CHF/mois"
    
    # Coûts session en cours
    if [ -f "logs/lab-usage.log" ]; then
        local last_start=$(tail -n 1 logs/lab-usage.log | grep "START" | cut -d'|' -f1)
        
        if [ -n "$last_start" ]; then
            local start_epoch=$(date -d "$last_start" +%s 2>/dev/null || echo "0")
            local now_epoch=$(date +%s)
            local duration_sec=$((now_epoch - start_epoch))
            local duration_hours=$(echo "scale=2; $duration_sec / 3600" | bc)
            
            local cost_per_hour=$(tail -n 1 logs/lab-usage.log | cut -d'|' -f4)
            local session_cost=$(echo "scale=3; $duration_hours * $cost_per_hour" | bc)
            
            echo ""
            echo "Session actuelle:"
            echo "  - Durée: ${duration_hours}h"
            echo "  - Coût estimé: ${session_cost} CHF"
            
            # Alerte si > 4h
            if (( $(echo "$duration_hours > 4" | bc -l) )); then
                echo -e "${RED}  ⚠ ATTENTION: Session > 4h !${NC}"
                echo "  Penser à arrêter le lab pour économiser"
            fi
        fi
    fi
    
    # Coûts hebdomadaires
    if [ -f "logs/lab-usage.log" ]; then
        local week_start=$(date -d "7 days ago" +%s)
        local total_week_cost=$(awk -F'|' -v start="$week_start" '
            /STOP/ {
                cmd = "date -d \""$1"\" +%s";
                cmd | getline timestamp;
                close(cmd);
                if (timestamp > start) {
                    split($4, a, ":");
                    gsub("CHF", "", a[2]);
                    sum += a[2];
                }
            }
            END { printf "%.2f", sum }
        ' logs/lab-usage.log 2>/dev/null || echo "0")
        
        echo ""
        echo "Cette semaine:"
        echo "  - Coût total: ${total_week_cost} CHF"
        echo "  - Budget recommandé: 5 CHF/semaine"
        
        if (( $(echo "$total_week_cost > 5" | bc -l) )); then
            echo -e "${YELLOW}  ⚠ Budget hebdomadaire dépassé${NC}"
        fi
    fi
}

# Vérification dernières backups
check_backups() {
    echo ""
    echo -e "${YELLOW}Backups:${NC}"
    
    if [ -f "backups/last-backup.timestamp" ]; then
        local last_backup=$(cat backups/last-backup.timestamp)
        echo "  Dernier backup: $last_backup"
    else
        echo "  Aucun backup trouvé"
    fi
}

# Recommandations
show_recommendations() {
    echo ""
    echo -e "${YELLOW}Recommandations:${NC}"
    
    export KUBECONFIG="$TERRAFORM_DIR/kubeconfig.yaml"
    
    if kubectl cluster-info &> /dev/null; then
        # Vérifier uptime
        if [ -f "logs/lab-usage.log" ]; then
            local last_start=$(tail -n 1 logs/lab-usage.log | grep "START" | cut -d'|' -f1)
            if [ -n "$last_start" ]; then
                local start_epoch=$(date -d "$last_start" +%s 2>/dev/null || echo "0")
                local now_epoch=$(date +%s)
                local duration_hours=$(echo "scale=1; ($now_epoch - $start_epoch) / 3600" | bc)
                
                if (( $(echo "$duration_hours > 4" | bc -l) )); then
                    echo -e "${RED}  ! Arrêter le lab maintenant: ./lab-stop.sh${NC}"
                elif (( $(echo "$duration_hours > 3" | bc -l) )); then
                    echo -e "${YELLOW}  ⚠ Lab actif depuis ${duration_hours}h - penser à l'arrêter bientôt${NC}"
                else
                    echo -e "${GREEN}  ✓ Durée session acceptable (${duration_hours}h)${NC}"
                fi
            fi
        fi
    else
        echo "  ✓ Lab arrêté - pas de coûts de compute"
    fi
}

# Exécution
main() {
    check_terraform_state
    check_kubernetes_cluster
    calculate_costs
    check_backups
    show_recommendations
    
    echo ""
    echo -e "${BLUE}=== Fin du status ===${NC}"
}

main
