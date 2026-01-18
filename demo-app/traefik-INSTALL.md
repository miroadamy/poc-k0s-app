# Traefik Ingress Controller Installation

Traefik is installed via Helm from the official Traefik Helm repository for HTTP/HTTPS routing on k0s, bound to standard host ports 80 and 443.

## Quick Start Installation

```bash
helm repo add traefik https://helm.traefik.io
helm repo update

# Create namespace
kubectl create namespace traefik

# Install Traefik with hostPort binding for standard ports
helm install traefik traefik/traefik -n traefik \
  --set service.type=ClusterIP \
  --set ports.web.hostPort=80 \
  --set ports.websecure.hostPort=443
```

## Configuration Details

- **Service Type**: ClusterIP with hostPort binding (standard ports 80 and 443)
- **Network**: ClusterFirst DNS (standard Kubernetes networking)
- **Storage**: In-memory (no persistent storage required)
- **Host Ports**: 80 (HTTP) and 443 (HTTPS) directly on the host

## Port Mappings

- Port 80 (Host) → Port 80 (Traefik HTTP service)
- Port 443 (Host) → Port 443 (Traefik HTTPS service)

## Working Access Methods

### ✅ HTTP (Port 80 - Working)

Access: `http://demo.klassify.com/`

- Perfect for load-balancing demonstrations
- No certificate issues
- Fully functional frontend and backend API
- Verified working from any browser or client

### ✅ HTTPS (Port 443 - Working)

Access: `https://demo.klassify.com/`

- TLS 1.3 encryption active
- Self-signed certificate (browser will show warning - accept it)
- Frontend and backend fully functional
- Verified working on standard HTTPS port 443

Routes are defined in:

- `route.yaml` — HTTP routing (web entrypoint)

## Optional: Self-Signed HTTPS Setup

If you want to attempt HTTPS despite the browser issues:

```bash
./traefik-selfsigned.sh
```

This generates a self-signed certificate and configures Traefik for HTTPS. Note: TLS layer works but browser access may hang.

## Load Balancing Demo

Test load balancing with repeated requests:

```bash
# HTTP version
for i in {1..10}; do
  curl -s -H 'Host: demo.klassify.com' http://127.0.0.1/api/hello | grep hostname
done

# HTTPS version
for i in {1..10}; do
  curl -sk -H 'Host: demo.klassify.com' https://127.0.0.1/api/hello | grep hostname
done

# Expected: See different pod names (demo-backend-67497b595-7vbzw vs demo-backend-67497b595-mnwrc)
```
