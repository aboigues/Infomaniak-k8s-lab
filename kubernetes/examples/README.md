# Exemples Kubernetes

Ce répertoire contient des exemples d'applications pour tester et apprendre Kubernetes.

## Applications disponibles

### nginx-demo.yaml

Application NGINX de démonstration avec :
- Deployment (2 replicas)
- Service ClusterIP
- ConfigMap pour page HTML personnalisée
- HorizontalPodAutoscaler
- ResourceQuotas et Limits

**Déploiement :**
```bash
kubectl apply -f kubernetes/examples/nginx-demo.yaml
```

**Accès :**
```bash
kubectl port-forward -n lab-k8s svc/nginx-demo 8080:80
# Ouvrir http://localhost:8080
```

**Nettoyage :**
```bash
kubectl delete -f kubernetes/examples/nginx-demo.yaml
```

### gpu-test.yaml

Tests et exemples pour workloads GPU/IA :
- Test CUDA simple
- Job TensorFlow avec GPU
- Deployment Jupyter Notebook
- Job PyTorch training

**Prérequis :** Lab démarré avec profile=ai

**Déploiement :**
```bash
# Test CUDA simple
kubectl apply -f kubernetes/examples/gpu-test.yaml

# Vérifier les logs
kubectl logs -n lab-ai gpu-test
kubectl logs -n lab-ai job/tensorflow-gpu-test
kubectl logs -n lab-ai job/pytorch-gpu-training
```

**Accès Jupyter :**
```bash
kubectl port-forward -n lab-ai svc/jupyter-gpu 8888:8888
# Token dans les logs: kubectl logs -n lab-ai deployment/jupyter-gpu
```

## Créer vos propres exemples

### Template de base

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mon-app
  namespace: lab-k8s
  labels:
    app: mon-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: mon-app
  template:
    metadata:
      labels:
        app: mon-app
    spec:
      containers:
      - name: app
        image: mon-image:latest
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
---
apiVersion: v1
kind: Service
metadata:
  name: mon-app
  namespace: lab-k8s
spec:
  selector:
    app: mon-app
  ports:
  - port: 80
    targetPort: 8080
```

## Best practices

1. **Toujours définir resources** (requests/limits)
2. **Utiliser les namespaces appropriés**
3. **Ajouter des labels significatifs**
4. **Inclure health checks** (liveness/readiness probes)
5. **Documenter l'usage** dans les commentaires

## Exercices suggérés

### Débutant
1. Modifier nginx-demo pour afficher un message personnalisé
2. Changer le nombre de replicas
3. Tester le scaling manuel
4. Exposer via NodePort

### Intermédiaire
1. Ajouter des health checks
2. Créer un Ingress avec SSL
3. Implémenter NetworkPolicies
4. Configurer un HPA

### Avancé
1. Déployer une stack complète (frontend/backend/db)
2. Implémenter GitOps avec ArgoCD
3. Créer un operator custom
4. Setup service mesh (Istio/Linkerd)
