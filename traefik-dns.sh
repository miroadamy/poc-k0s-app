#!/bin/bash

# Replace these with your actual AWS credentials
AWS_ACCESS_KEY="xxx"
AWS_SECRET_KEY="xxxx"
AWS_REGION="eu-west-1"

echo "Removing old Traefik installation..."
helm uninstall traefik -n traefik
kubectl delete ns traefik --ignore-not-found
sleep 3

echo "Creating traefik namespace..."
kubectl create namespace traefik

echo "Installing Traefik with DNS-01 challenge (no persistence)..."
helm install traefik traefik/traefik -n traefik \
  --set 'env[0].name=AWS_REGION' \
  --set "env[0].value=${AWS_REGION}" \
  --set 'env[1].name=AWS_ACCESS_KEY_ID' \
  --set "env[1].value=${AWS_ACCESS_KEY}" \
  --set 'env[2].name=AWS_SECRET_ACCESS_KEY' \
  --set "env[2].value=${AWS_SECRET_KEY}" \
  --set persistence.enabled=false \
  --set certificatesResolvers.le.acme.dnsChallenge.provider=route53 \
  --set certificatesResolvers.le.acme.email=admin@klassify.com \
  --set certificatesResolvers.le.acme.storage=/data/acme.json \
  --set service.type=NodePort \
  --set ports.web.nodePort=30080 \
  --set ports.websecure.nodePort=30443 \
  --set ports.websecure.tls.enabled=true

echo ""
echo "Waiting for Traefik pod..."
sleep 15

echo ""
echo "=== Traefik Pods ==="
kubectl -n traefik get pods

echo ""
echo "=== Checking for DNS-01 Challenge ==="
kubectl -n traefik logs deploy/traefik 2>/dev/null | grep -E "dns|route53|acme|certificate" | tail -30
