.PHONY: help start stop status cost init clean logs

PROFILE ?= standard
TERRAFORM_DIR = terraform/environments/prod

help:
	@echo "Lab Kubernetes Infomaniak - Commandes disponibles"
	@echo ""
	@echo "  make start [PROFILE=...]  - Démarrer le lab"
	@echo "  make stop                 - Arrêter le lab"
	@echo "  make status               - État du cluster"
	@echo "  make cost                 - Calcul des coûts"
	@echo "  make init                 - Initialiser Terraform"
	@echo "  make logs                 - Logs des nodes"
	@echo "  make clean                - Nettoyer ressources temporaires"
	@echo ""
	@echo "Profiles disponibles:"
	@echo "  minimal  - 1 node  (0.03 CHF/h)"
	@echo "  standard - 2 nodes (0.09 CHF/h)"
	@echo "  memory   - 3 nodes (0.15 CHF/h)"
	@echo "  ai       - GPU     (2.56 CHF/h)"

init:
	@echo "Initialisation Terraform..."
	cd $(TERRAFORM_DIR) && terraform init
	@echo "Vérification configuration..."
	cd $(TERRAFORM_DIR) && terraform validate
	@echo "Prêt!"

start:
	@echo "Démarrage du lab avec profile: $(PROFILE)"
	@./scripts/lab-start.sh $(PROFILE)
	@echo ""
	@echo "Lab démarré! Nodes disponibles:"
	@kubectl get nodes
	@echo ""
	@echo "N'oubliez pas de faire 'make stop' à la fin de votre session!"

stop:
	@echo "Arrêt du lab..."
	@./scripts/lab-stop.sh
	@echo "Lab arrêté. Coûts minimisés."

status:
	@echo "=== État du cluster ==="
	@kubectl get nodes 2>/dev/null || echo "Aucun node actif"
	@echo ""
	@echo "=== Namespaces ==="
	@kubectl get ns 2>/dev/null || echo "Cluster non accessible"
	@echo ""
	@echo "=== Pods en cours ==="
	@kubectl get pods --all-namespaces 2>/dev/null || echo "Cluster non accessible"
	@echo ""
	@./scripts/calculate-uptime.sh

cost:
	@echo "=== Calcul des coûts ==="
	@./scripts/calculate-costs.sh

logs:
	@echo "=== Logs des nodes ==="
	@kubectl logs -n kube-system -l component=kube-proxy --tail=50

clean:
	@echo "Nettoyage des fichiers temporaires..."
	@rm -f *.log
	@rm -f backup-state-*.yaml
	@cd $(TERRAFORM_DIR) && terraform fmt
	@echo "Nettoyage terminé"

# Commandes avancées
backup:
	@echo "Sauvegarde de l'état du cluster..."
	@./scripts/backup-cluster-state.sh

restore:
	@echo "Restauration de l'état du cluster..."
	@./scripts/restore-cluster-state.sh

dashboard:
	@echo "Ouverture du dashboard Grafana..."
	@kubectl port-forward -n monitoring svc/grafana 3000:3000
