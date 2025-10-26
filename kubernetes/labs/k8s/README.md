# Lab Kubernetes - Fundamentals

## Objectif
Maîtriser les concepts fondamentaux de Kubernetes.

## Durée
2-3 heures

## Coût estimé
~0.25 CHF (2 nodes pendant 3h)

## Prérequis
```bash
make start PROFILE=standard
```

## Exercice 1: Deployments et ReplicaSets

### Créer un deployment
```yaml
# nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: lab-k8s
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 50m
            memory: 64Mi
          limits:
            cpu: 100m
            memory: 128Mi
```

### Déployer
```bash
kubectl apply -f nginx-deployment.yaml
kubectl get deployments -n lab-k8s
kubectl get pods -n lab-k8s -l app=nginx
```

### Scaler
```bash
kubectl scale deployment nginx --replicas=5 -n lab-k8s
kubectl get pods -n lab-k8s -w
```

## Exercice 2: Services

### ClusterIP Service
```yaml
# nginx-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: lab-k8s
spec:
  type: ClusterIP
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
```

### Tester
```bash
kubectl apply -f nginx-service.yaml
kubectl run test --rm -it --image=busybox -n lab-k8s -- wget -O- nginx-service
```

## Exercice 3: ConfigMaps et Secrets

### ConfigMap
```yaml
# nginx-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
  namespace: lab-k8s
data:
  index.html: |
    <html>
    <body>
      <h1>Lab Kubernetes sur Infomaniak</h1>
      <p>Environnement: Production</p>
    </body>
    </html>
```

### Secret
```yaml
# nginx-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: nginx-secret
  namespace: lab-k8s
type: Opaque
stringData:
  username: admin
  password: changeme
```

### Monter dans le pod
```yaml
# Ajouter dans le deployment
spec:
  containers:
  - name: nginx
    volumeMounts:
    - name: config
      mountPath: /usr/share/nginx/html
    - name: secret
      mountPath: /etc/nginx/secrets
      readOnly: true
  volumes:
  - name: config
    configMap:
      name: nginx-config
  - name: secret
    secret:
      secretName: nginx-secret
```

## Exercice 4: Rolling Updates

### Mise à jour de l'image
```bash
kubectl set image deployment/nginx nginx=nginx:1.26 -n lab-k8s
kubectl rollout status deployment/nginx -n lab-k8s
```

### Rollback
```bash
kubectl rollout undo deployment/nginx -n lab-k8s
kubectl rollout history deployment/nginx -n lab-k8s
```

## Exercice 5: Horizontal Pod Autoscaler

### Créer HPA
```yaml
# nginx-hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
  namespace: lab-k8s
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
```

### Générer de la charge
```bash
kubectl run load-generator --rm -it --image=busybox -n lab-k8s -- \
  /bin/sh -c "while true; do wget -q -O- http://nginx-service; done"
```

### Observer le scaling
```bash
kubectl get hpa -n lab-k8s -w
kubectl get pods -n lab-k8s -w
```

## Exercice 6: Ingress

### Déployer NGINX Ingress Controller
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.0/deploy/static/provider/cloud/deploy.yaml
```

### Créer un Ingress
```yaml
# nginx-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  namespace: lab-k8s
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  rules:
  - host: lab.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-service
            port:
              number: 80
  tls:
  - hosts:
    - lab.example.com
    secretName: lab-tls
```

## Nettoyage
```bash
kubectl delete namespace lab-k8s
make stop
```

## Points clés appris
- Deployments gérent les ReplicaSets automatiquement
- Services exposent les pods de manière stable
- ConfigMaps/Secrets séparent config et code
- Rolling updates sans downtime
- HPA adapte automatiquement les ressources
- Ingress expose les services en HTTP(S)
