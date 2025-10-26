#!/bin/bash
# Script de calcul des coûts du lab
# Usage: ./calculate-costs.sh

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Tarifs Infomaniak (CHF/heure)
COST_NODE_1CPU_2GB=0.03
COST_NODE_2CPU_4GB=0.06
COST_NODE_GPU_L4=2.50
COST_LOADBALANCER=0.015

# Tarifs stockage (CHF/mois)
COST_BLOCK_STORAGE_GB=0.10
COST_S3_STORAGE_GB=0.03

echo -e "${GREEN}=== Calcul des coûts Lab ===${NC}"
echo ""

# Vérifier si des nodes sont actifs
RUNNING_NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l || echo "0")

if [ "$RUNNING_NODES" -eq 0 ]; then
    echo -e "${GREEN}Aucun node actif${NC}"
    echo "Coûts compute: 0.00 CHF/h"
else
    echo -e "${YELLOW}Nodes actifs: $RUNNING_NODES${NC}"
    
    # Compter les différents types de nodes
    SMALL_NODES=$(kubectl get nodes -o json 2>/dev/null | jq '[.items[] | select(.status.capacity.memory == "2Gi")] | length' || echo "0")
    MEDIUM_NODES=$(kubectl get nodes -o json 2>/dev/null | jq '[.items[] | select(.status.capacity.memory == "4Gi")] | length' || echo "0")
    GPU_NODES=$(kubectl get nodes -l nvidia.com/gpu=true --no-headers 2>/dev/null | wc -l || echo "0")
    
    # Calculer coût par heure
    COST_PER_HOUR=$(echo "$SMALL_NODES * $COST_NODE_1CPU_2GB + $MEDIUM_NODES * $COST_NODE_2CPU_4GB + $GPU_NODES * $COST_NODE_GPU_L4 + $COST_LOADBALANCER" | bc)
    
    echo "  - Nodes 1CPU/2GB: $SMALL_NODES (${COST_NODE_1CPU_2GB} CHF/h chacun)"
    echo "  - Nodes 2CPU/4GB: $MEDIUM_NODES (${COST_NODE_2CPU_4GB} CHF/h chacun)"
    echo "  - Nodes GPU: $GPU_NODES (${COST_NODE_GPU_L4} CHF/h chacun)"
    echo ""
    echo -e "${YELLOW}Coût compute: ${COST_PER_HOUR} CHF/h${NC}"
fi

# Calculer temps d'exécution si session active
if [ -f /tmp/lab-start-time ]; then
    START_TIME=$(cat /tmp/lab-start-time)
    START_EPOCH=$(date -d "${START_TIME:0:8} ${START_TIME:9:2}:${START_TIME:11:2}:${START_TIME:13:2}" +%s 2>/dev/null || echo "0")
    CURRENT_EPOCH=$(date +%s)
    UPTIME_SECONDS=$((CURRENT_EPOCH - START_EPOCH))
    UPTIME_HOURS=$(echo "scale=2; $UPTIME_SECONDS / 3600" | bc)
    
    SESSION_COST=$(echo "scale=2; $COST_PER_HOUR * $UPTIME_HOURS" | bc)
    
    echo ""
    echo -e "${YELLOW}Session actuelle:${NC}"
    echo "  Démarrée: $START_TIME"
    echo "  Uptime: ${UPTIME_HOURS}h"
    echo -e "  ${GREEN}Coût session: ${SESSION_COST} CHF${NC}"
    
    # Alerte si > 5h
    if (( $(echo "$UPTIME_HOURS > 5" | bc -l) )); then
        echo -e "  ${RED}ATTENTION: Session > 5h! Pensez à arrêter le lab.${NC}"
    fi
fi

# Coûts stockage (estimation)
echo ""
echo -e "${GREEN}Coûts stockage (fixes):${NC}"
STORAGE_BLOCK_GB=50
STORAGE_S3_GB=100

COST_STORAGE_MONTH=$(echo "scale=2; $STORAGE_BLOCK_GB * $COST_BLOCK_STORAGE_GB + $STORAGE_S3_GB * $COST_S3_STORAGE_GB" | bc)

echo "  - Block storage: ${STORAGE_BLOCK_GB}GB (${COST_BLOCK_STORAGE_GB} CHF/GB/mois)"
echo "  - S3 storage: ${STORAGE_S3_GB}GB (${COST_S3_STORAGE_GB} CHF/GB/mois)"
echo "  Total stockage: ${COST_STORAGE_MONTH} CHF/mois"

# Projection mensuelle (20h usage)
echo ""
echo -e "${GREEN}Projections mensuelles:${NC}"
HOURS_PER_MONTH=20
COST_COMPUTE_MONTH=$(echo "scale=2; $COST_PER_HOUR * $HOURS_PER_MONTH" | bc)
COST_TOTAL_MONTH=$(echo "scale=2; $COST_COMPUTE_MONTH + $COST_STORAGE_MONTH" | bc)

echo "  Usage estimé: ${HOURS_PER_MONTH}h/mois"
echo "  Compute: ${COST_COMPUTE_MONTH} CHF/mois"
echo "  Stockage: ${COST_STORAGE_MONTH} CHF/mois"
echo -e "  ${YELLOW}Total estimé: ${COST_TOTAL_MONTH} CHF/mois${NC}"

# Comparaison avec 24/7
HOURS_247=730
COST_247=$(echo "scale=2; $COST_PER_HOUR * $HOURS_247 + $COST_STORAGE_MONTH" | bc)
SAVINGS=$(echo "scale=0; (1 - $COST_TOTAL_MONTH / $COST_247) * 100" | bc)

echo ""
echo -e "${GREEN}Économies vs. 24/7:${NC}"
echo "  24/7: ${COST_247} CHF/mois"
echo "  On-demand: ${COST_TOTAL_MONTH} CHF/mois"
echo -e "  ${GREEN}Économie: ${SAVINGS}%${NC}"

echo ""
