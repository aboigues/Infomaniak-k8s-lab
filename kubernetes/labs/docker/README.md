# Lab Docker - Construction d'images optimisées

## Objectif
Apprendre à construire des images Docker multi-stage optimisées.

## Durée
1-2 heures

## Coût estimé
~0.06 CHF (1 node pendant 2h)

## Prérequis
```bash
make start PROFILE=minimal
```

## Exercice 1: Image Python simple

### Dockerfile initial (non optimisé)
```dockerfile
FROM python:3.11
WORKDIR /app
COPY . .
RUN pip install -r requirements.txt
CMD ["python", "app.py"]
```

### Construction
```bash
docker build -t myapp:v1 .
docker images myapp:v1
# Taille: ~1GB
```

## Exercice 2: Image multi-stage optimisée

### Dockerfile optimisé
```dockerfile
# Stage 1: Build
FROM python:3.11-slim as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Stage 2: Runtime
FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY app.py .
ENV PATH=/root/.local/bin:$PATH
CMD ["python", "app.py"]
```

### Construction et comparaison
```bash
docker build -t myapp:v2 -f Dockerfile.optimized .
docker images myapp:v2
# Taille: ~150MB (réduction de 85%)
```

## Exercice 3: Scan de sécurité

### Avec Trivy
```bash
# Installation Trivy
kubectl run trivy --rm -it --image=aquasec/trivy:latest -- image myapp:v2

# Analyser les vulnérabilités
trivy image myapp:v2
```

## Exercice 4: Push vers registry

### Configuration registry
```bash
# Registry local ou Infomaniak
docker tag myapp:v2 registry.infomaniak.com/lab/myapp:v2
docker push registry.infomaniak.com/lab/myapp:v2
```

## Exercice 5: Déploiement Kubernetes

### Deployment YAML
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: lab-docker
spec:
  replicas: 2
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: registry.infomaniak.com/lab/myapp:v2
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
```

### Déploiement
```bash
kubectl apply -f deployment.yaml -n lab-docker
kubectl get pods -n lab-docker
```

## Nettoyage
```bash
kubectl delete deployment myapp -n lab-docker
make stop
```

## Points clés appris
- Images multi-stage réduisent la taille de 85%+
- Scan de sécurité identifie les vulnérabilités
- Images optimisées = coûts réduits + déploiement rapide
- Registry central facilite la gestion
