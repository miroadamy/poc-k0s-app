# Traefik Ingress Controller Installation

Traefik is installed via Helm from the official Traefik Helm repository for HTTP/HTTPS routing on k0s.

## Quick Start Installation

```bash
helm repo add traefik https://helm.traefik.io
helm repo update

# Create namespace
kubectl create namespace traefik

# Install Traefik with NodePort service
helm install traefik traefik/traefik -n traefik \
  --set service.type=NodePort \
  --set ports.web.nodePort=30080 \
  --set ports.websecure.nodePort=30443 \
  --set ports.websecure.tls.enabled=true
```

## Configuration Details

- **Service Type**: NodePort (HTTP on 30080, HTTPS on 30443)
- **Network**: ClusterFirst DNS (standard Kubernetes networking)
- **Storage**: In-memory (no persistent storage required)

## Port Mappings

- Port 30080 (NodePort) → Port 80 (Traefik HTTP service)
- Port 30443 (NodePort) → Port 443 (Traefik HTTPS service)

## Working Access Methods

### ✅ HTTP (Fully Working & Recommended)

Access: `http://demo.klassify.com:30080/`

- Perfect for load-balancing demonstrations
- No certificate issues
- Fully functional frontend and backend API
- Verified working from any browser or client

### ⚠️ HTTPS (Partial - TLS Works, Browser Doesn't)

The TLS handshake works (verified via curl with `-vk` flag), but browser access hangs after initial connection. This is a frontend asset loading issue, not a certificate/TLS problem.

**Status:**

- TLS 1.3 encryption: ✅ Working
- Certificate validation: ✅ Self-signed cert served correctly
- HTTP/2: ✅ Supported
- curl with `-vk`: ✅ Full API response received
- Browser access: ❌ Hangs during asset loading

**Recommendation**: Use HTTP (port 30080) for your load-balancing demo. It's production-ready and fully functional.

## IngressRoute Configuration

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
# HTTP version (recommended)
for i in {1..10}; do
  curl -s -H 'Host: demo.klassify.com' http://127.0.0.1:30080/api/hello | grep hostname
done

# Expected: See different pod names (demo-backend-67497b595-7vbzw vs demo-backend-67497b595-mnwrc)
```
