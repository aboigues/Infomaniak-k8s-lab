# Guide de Troubleshooting

## Problèmes courants

### 1. Les nodes ne démarrent pas

**Symptômes**:
- `kubectl get nodes` ne retourne rien
- Timeout après 5 minutes

**Causes possibles**:
- Quota Infomaniak atteint
- Erreur Terraform
- Réseau mal configuré

**Solutions**:
```bash
# Vérifier les logs Terraform
cd terraform/environments/prod
terraform plan

# Vérifier les quotas
# Via console Infomaniak

# Forcer le refresh
terraform refresh
terraform apply -var="lab_mode=active" -var="profile=minimal"

# Vérifier les events
kubectl get events --all-namespaces
```

### 2. Coûts plus élevés que prévu

**Symptômes**:
- Facture > estimation
- Nodes actifs plus longtemps que prévu

**Diagnostic**:
```bash
# Vérifier uptime actuel
cat /tmp/lab-start-time
./scripts/calculate-costs.sh

# Voir nodes actifs
kubectl get nodes
kubectl top nodes

# Historique
ls -lh backups/
```

**Prévention**:
```bash
# Configurer auto-shutdown agressif
# Dans .env
AUTO_SHUTDOWN_AFTER_HOURS=3
FORCE_SHUTDOWN_AFTER_HOURS=4

# Ajouter cron personnel
0 */3 * * * /path/to/scripts/lab-stop.sh
```

### 3. Backup/Restore échoue

**Symptômes**:
- Erreur lors de backup-cluster-state.sh
- Pods ne redémarrent pas après restore

**Diagnostic**:
```bash
# Vérifier permissions S3
aws s3 ls s3://lab-artifacts/backups/ --endpoint-url=$S3_ENDPOINT

# Vérifier backup local
ls -lh backups/
cat backups/cluster-state-latest.yaml | head -50

# Tester restore manuel
kubectl apply -f backups/cluster-state-latest.yaml --dry-run=client
```

**Solutions**:
```bash
# Backup manuel sélectif
kubectl get deploy -n lab-k8s -o yaml > manual-backup.yaml

# Restore progressif
kubectl apply -f manual-backup.yaml -n lab-k8s

# Réinitialiser namespace
kubectl delete ns lab-k8s
kubectl create ns lab-k8s
kubectl apply -f backups/cluster-state-latest.yaml
```

### 4. Terraform state lock

**Symptômes**:
- "Error acquiring state lock"
- Impossible de faire terraform apply

**Solutions**:
```bash
# Forcer l'unlock (attention!)
cd terraform/environments/prod
terraform force-unlock <LOCK_ID>

# Si backend S3
aws s3 rm s3://lab-terraform-state/prod/.terraform.lock.info --endpoint-url=$S3_ENDPOINT

# Dernière option: réinitialiser
rm -rf .terraform
terraform init
```

### 5. Pods en CrashLoopBackOff

**Symptômes**:
- Pods redémarrent en boucle
- `kubectl get pods` montre CrashLoopBackOff

**Diagnostic**:
```bash
# Voir les logs
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous

# Décrire le pod
kubectl describe pod <pod-name> -n <namespace>

# Vérifier les events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

**Solutions courantes**:
```bash
# Problème de ressources
kubectl top pods -n <namespace>
# → Augmenter requests/limits

# Problème de configuration
kubectl get configmap -n <namespace>
kubectl get secret -n <namespace>
# → Vérifier montage correct

# Problème d'image
kubectl describe pod <pod-name> -n <namespace> | grep Image
# → Vérifier registry accessible
```

### 6. Ingress ne fonctionne pas

**Symptômes**:
- 502/503 sur l'URL
- Service inaccessible depuis l'extérieur

**Diagnostic**:
```bash
# Vérifier ingress controller
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Vérifier ingress
kubectl get ingress -A
kubectl describe ingress <ingress-name> -n <namespace>

# Vérifier service backend
kubectl get svc -n <namespace>
kubectl get endpoints -n <namespace>
```

**Solutions**:
```bash
# Réinstaller ingress controller
kubectl delete ns ingress-nginx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.0/deploy/static/provider/cloud/deploy.yaml

# Vérifier annotations
kubectl annotate ingress <name> nginx.ingress.kubernetes.io/rewrite-target=/

# Test direct service
kubectl port-forward svc/<service-name> 8080:80 -n <namespace>
curl localhost:8080
```

### 7. GPU non détecté

**Symptômes**:
- Pods GPU en Pending
- `nvidia-smi` ne fonctionne pas

**Diagnostic**:
```bash
# Vérifier node GPU
kubectl get nodes -l nvidia.com/gpu=true
kubectl describe node <gpu-node-name>

# Vérifier NVIDIA device plugin
kubectl get pods -n kube-system -l name=nvidia-device-plugin-ds

# Vérifier GPU disponible
kubectl get nodes -o json | jq '.items[].status.allocatable'
```

**Solutions**:
```bash
# Installer NVIDIA device plugin
kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.14.0/nvidia-device-plugin.yml

# Ajouter toleration dans pod
tolerations:
- key: nvidia.com/gpu
  operator: Exists
  effect: NoSchedule

# Demander GPU dans resources
resources:
  limits:
    nvidia.com/gpu: 1
```

### 8. Stockage plein

**Symptômes**:
- Pods en Evicted
- "no space left on device"

**Diagnostic**:
```bash
# Vérifier usage PVC
kubectl get pvc -A
kubectl describe pvc <pvc-name> -n <namespace>

# Voir pods évicted
kubectl get pods -A | grep Evicted

# Usage disque nodes
kubectl top nodes
```

**Solutions**:
```bash
# Nettoyer pods évicted
kubectl get pods -A | grep Evicted | awk '{print $1,$2}' | xargs -n2 kubectl delete pod -n

# Augmenter taille PVC
kubectl edit pvc <pvc-name> -n <namespace>
# Modifier spec.resources.requests.storage

# Nettoyer images inutilisées
kubectl get nodes -o name | xargs -I {} kubectl debug {} -it --image=alpine -- sh -c "crictl rmi --prune"
```

## Commandes de diagnostic utiles

### État général
```bash
# Vue d'ensemble
kubectl get all -A
kubectl get nodes -o wide
kubectl top nodes
kubectl top pods -A

# Events récents
kubectl get events -A --sort-by='.lastTimestamp' | tail -20

# Ressources
kubectl describe node <node-name>
kubectl api-resources
```

### Réseau
```bash
# Services et endpoints
kubectl get svc -A
kubectl get endpoints -A

# DNS
kubectl run test-dns --rm -it --image=busybox -- nslookup kubernetes.default

# Connectivité
kubectl run test-net --rm -it --image=nicolaka/netshoot -- bash
```

### Logs
```bash
# Logs pods
kubectl logs -f <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --all-containers

# Logs précédents
kubectl logs <pod-name> -n <namespace> --previous

# Logs multiples pods
kubectl logs -l app=nginx -n <namespace> --tail=10
```

## Contacts et support

### Infomaniak
- Console: https://console.infomaniak.com
- Documentation: https://docs.infomaniak.cloud
- Support: Via console (ticket)

### Communauté
- Forum Infomaniak
- Slack Kubernetes
- GitHub Issues du projet

## Logs et monitoring

### Activer debug
```bash
# Terraform
export TF_LOG=DEBUG
terraform apply

# Kubectl
kubectl <command> -v=8

# Scripts
bash -x ./scripts/lab-start.sh
```

### Sauvegarder logs
```bash
# Logs complets pour analyse
kubectl cluster-info dump > cluster-dump.txt
kubectl get events -A > events.txt
./scripts/calculate-costs.sh > costs.txt
```
