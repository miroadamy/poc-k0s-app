# k0s Demo App (React + Java)

A minimal two-tier demo to validate k0s load balancing.

- **Frontend:** React app served by Nginx with reverse proxy to backend
- **Backend:** Java 21 HTTP server (no framework, lightweight)
- **Kubernetes:** 2 replicas for each tier (4 pods total)
- **Ingress:** Traefik with HTTP/HTTPS support on standard ports

## Complete Deployment

For full instructions on deploying to a new k0s server, see [DEPLOYMENT.md](../DEPLOYMENT.md).

Quick summary:

1. Build Docker images locally (M4 Mac, cross-compile to x86)
2. Push to Docker Hub
3. Deploy to k0s with kubectl
4. Install Traefik ingress controller
5. Access via `http://demo.klassify.com` or `https://demo.klassify.com`

## Local Development

Backend:

```bash
cd demo-app/backend
javac Main.java
java Main
```

Frontend:

```bash
cd demo-app/frontend
npm install
npm run dev
```

Then open: http://localhost:5173

## Build container images (for deployment)

**Prerequisites:**

- Docker with buildx support
- Docker Hub account (or other registry)
- For x86 servers: build with `--platform linux/amd64`

### Backend (Java 21)

```bash
cd demo-app/backend
docker build -t demo-backend:local .
```

### Frontend

```bash
cd demo-app/frontend
docker build -t demo-frontend:local .
```

If your cluster can’t see Docker’s local images, push them to a registry or import into containerd.

## Deploy to k0s

```bash
kubectl apply -k demo-app/k8s
kubectl -n demo-app get pods -w
```

Frontend is exposed via NodePort 30080:

```
http://<node-ip>:30080
```

## Load balancing check

- Refresh the UI multiple times to see different `hostname`/`instanceId` values.
- Or call the backend directly:

```bash
kubectl -n demo-app get svc demo-backend
kubectl -n demo-app exec deploy/demo-frontend -- curl -s http://demo-backend:8080/api/hello
```

## Scale up/down

```bash
kubectl -n demo-app scale deploy/demo-backend --replicas=2
kubectl -n demo-app scale deploy/demo-frontend --replicas=2
```

## Clean up

```bash
kubectl delete -k demo-app/k8s
```
