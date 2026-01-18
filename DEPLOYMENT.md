# Complete Deployment Guide

Recreate the full k0s + demo-app environment on a new server.

## Prerequisites

**On your local machine (macOS M4):**

- Docker with buildx support
- Docker Hub account
- SSH key for server access
- Kubectl CLI

**On the target server (Ubuntu 22.04, x86):**

- SSH access (port 22)
- ~2GB free disk space
- Network access to pull container images

## Step 1: Prepare Server Access

### SSH Access

```bash
# Add your public key to server
ssh-copy-id -i ~/.ssh/id_rsa cloud_user@<SERVER_IP>

# Test connection
ssh -i ~/.ssh/id_rsa cloud_user@<SERVER_IP>
```

### Update DNS (if using custom domain)

Update your Route53 A record (or DNS provider) to point to the server IP:

```
demo.klassify.com → <SERVER_IP>
```

## Step 2: Install k0s on Server

SSH to server and run:

```bash
curl -sSLf https://get.k0s.sh | sudo bash
sudo k0s install controller --single
sudo systemctl start k0s
sudo systemctl enable k0s

# Verify
sudo k0s kubeconfig admin > ~/.kube/config
chmod 600 ~/.kube/config
kubectl cluster-info
```

## Step 3: Build and Push Docker Images

From your macOS:

### Set up buildx (one-time)

```bash
docker buildx create --name multiarch --use
docker login  # Login to Docker Hub
```

### Build and push backend

```bash
cd demo-app/backend
docker buildx build --platform linux/amd64 \
  -t miroadamy/demo-backend:java21 \
  --push .
```

### Build and push frontend

```bash
cd demo-app/frontend
docker buildx build --platform linux/amd64 \
  -t miroadamy/demo-frontend:latest \
  --push .
```

**Note:** Images are configured for `miroadamy` Docker Hub account. To use your own:

1. Update image names in:
   - `demo-app/k8s/backend-deployment.yaml`
   - `demo-app/k8s/frontend-deployment.yaml`
2. Build/push with your own registry prefix

## Step 4: Deploy Demo App to k0s

Copy k8s manifests to server:

```bash
scp -r -i ~/.ssh/id_rsa demo-app/k8s cloud_user@<SERVER_IP>:/tmp/
```

SSH to server and deploy:

```bash
kubectl apply -k /tmp/k8s

# Verify pods are running
kubectl -n demo-app get pods -w
```

Expected output (4 pods):

```
NAME                            READY   STATUS    RESTARTS   AGE
demo-backend-xxxxxxxx-xxxxx     1/1     Running   0          30s
demo-backend-xxxxxxxx-xxxxx     1/1     Running   0          30s
demo-frontend-xxxxxxxx-xxxxx    1/1     Running   0          30s
demo-frontend-xxxxxxxx-xxxxx    1/1     Running   0          30s
```

## Step 5: Install Traefik Ingress Controller

### Prerequisites

On server, have Helm installed:

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Install Traefik with standard ports

```bash
helm repo add traefik https://helm.traefik.io
helm repo update

kubectl create namespace traefik

helm install traefik traefik/traefik -n traefik \
  --set service.type=ClusterIP \
  --set ports.web.hostPort=80 \
  --set ports.websecure.hostPort=443
```

Verify:

```bash
kubectl -n traefik get pods
```

## Step 6: Deploy IngressRoute (HTTP/HTTPS)

Copy route manifest to server:

```bash
scp -i ~/.ssh/id_rsa demo-app/k8s/route.yaml \
  cloud_user@<SERVER_IP>:/tmp/
```

Apply:

```bash
kubectl apply -f /tmp/route.yaml
```

## Step 7: Test Access

From your local machine:

### HTTP (Port 80)

```bash
curl -H 'Host: demo.klassify.com' http://<SERVER_IP>/
# or use browser: http://demo.klassify.com/
```

### HTTPS (Port 443 - Self-signed)

```bash
curl -vk -H 'Host: demo.klassify.com' https://<SERVER_IP>/
# or use browser: https://demo.klassify.com/ (accept cert warning)
```

### Verify Load Balancing

```bash
for i in {1..10}; do
  curl -s -H 'Host: demo.klassify.com' http://<SERVER_IP>/api/hello | grep hostname
done
```

Expected: See different pod names in response (load balancing working).

## Configuration Reference

### Docker Images

- **Backend**: `miroadamy/demo-backend:java21`
- **Frontend**: `miroadamy/demo-frontend:latest`

### Service Endpoints (k8s internal)

- **Backend**: `demo-backend:8080`
- **Frontend**: `demo-frontend:80`

### Exposed Access

- **HTTP**: `demo.klassify.com` (port 80)
- **HTTPS**: `demo.klassify.com` (port 443, self-signed cert)

### Kubernetes Resources

- **Namespace**: `demo-app`
- **Replicas**: 2 backend + 2 frontend
- **Ingress Controller**: Traefik in `traefik` namespace

### File Structure

```
demo-app/
├── backend/
│   ├── Main.java        # Java 21 HTTP server
│   └── Dockerfile       # Multi-arch (amd64)
├── frontend/
│   ├── src/             # React source
│   ├── nginx.conf       # Reverse proxy to backend
│   └── Dockerfile       # Node build + Nginx serve
├── k8s/
│   ├── namespace.yaml
│   ├── backend-deployment.yaml
│   ├── backend-service.yaml
│   ├── frontend-deployment.yaml
│   ├── frontend-service.yaml
│   ├── route.yaml       # Traefik IngressRoute
│   └── kustomization.yaml
└── traefik-INSTALL.md   # Traefik setup guide
```

## Troubleshooting

### Pods not starting

```bash
kubectl -n demo-app describe pod <POD_NAME>
kubectl -n demo-app logs <POD_NAME>
```

### Service not accessible

```bash
kubectl -n demo-app get svc
kubectl -n demo-app get ep  # Check endpoints
```

### Traefik issues

```bash
kubectl -n traefik logs deploy/traefik
kubectl -n traefik get svc traefik
```

### DNS not resolving

```bash
# Test from pod
kubectl -n demo-app exec -it <FRONTEND_POD> -- nslookup demo-backend

# Test external
nslookup demo.klassify.com
```

## Cleanup

To remove all resources:

```bash
kubectl delete namespace demo-app
kubectl delete namespace traefik
helm uninstall traefik -n traefik
```

To stop k0s:

```bash
sudo systemctl stop k0s
```

## Notes

- **Self-signed certificates**: Browser will show warning; this is expected. Add certificate exception to proceed.
- **Load balancing**: Frontend automatically round-robins requests to 2 backend pods.
- **Image registry**: Change `miroadamy/` to your Docker Hub username in k8s manifests.
- **DNS domain**: Replace `demo.klassify.com` with your domain in route.yaml and DNS provider.
