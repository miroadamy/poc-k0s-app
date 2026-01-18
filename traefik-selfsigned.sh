#!/bin/bash

# Self-signed certificate setup for Traefik
# This creates a working HTTPS endpoint without Let's Encrypt

echo "Removing current Traefik..."
helm uninstall traefik -n traefik
kubectl delete ns traefik --ignore-not-found
sleep 3

echo "Creating namespace..."
kubectl create namespace traefik

echo "Generating self-signed certificate..."
openssl req -x509 -newkey rsa:4096 -keyout /tmp/tls.key -out /tmp/tls.crt -days 365 -nodes \
  -subj "/CN=demo.klassify.com/O=Demo/C=US"

echo "Creating Kubernetes secret with certificate..."
kubectl create secret tls demo-klassify-cert \
  -n traefik \
  --cert=/tmp/tls.crt \
  --key=/tmp/tls.key

echo ""
echo "Installing Traefik with self-signed certificate..."
helm install traefik traefik/traefik -n traefik \
  --set service.type=NodePort \
  --set ports.web.nodePort=30080 \
  --set ports.websecure.nodePort=30443 \
  --set ports.websecure.tls.enabled=true \
  --set tlsOptions.default.sniStrict=false

echo ""
echo "Waiting for Traefik pod..."
sleep 10

echo ""
echo "=== Traefik Status ==="
kubectl -n traefik get pods

echo ""
echo "=== Creating HTTPS IngressRoute with self-signed cert ==="
kubectl apply -f - << 'ROUTE'
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: demo-frontend-https
  namespace: demo-app
spec:
  entryPoints:
    - websecure
  routes:
    - kind: Rule
      match: Host(`demo.klassify.com`)
      services:
        - name: demo-frontend
          port: 80
  tls:
    secretName: demo-klassify-cert
ROUTE

echo ""
echo "=== Testing HTTPS (will show self-signed cert warning) ==="
sleep 5
curl -vk https://demo.klassify.com:30443/ 2>&1 | head -30 || echo "Testing with Host header..."
curl -vk -H 'Host: demo.klassify.com' https://127.0.0.1:30443/ 2>&1 | head -30
