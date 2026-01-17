## Preinstall check

Completed: *Assess server resources for k0s* (1/2)

Pre-install checklist for Ubuntu 22 (run as root). Each block is safe to run and just reports status unless noted.

**1) Basic system + disk + memory**
```bash
lsb_release -a
uname -r
uptime
free -h
df -h /
```

**2) Swap must be OFF (checks only)**
```bash
swapon --show
cat /proc/swaps
```

**3) Kernel modules needed for container networking**
```bash
lsmod | grep -E 'br_netfilter|overlay'
```

**4) Sysctl settings required by Kubernetes**
```bash
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.bridge.bridge-nf-call-ip6tables
sysctl net.ipv4.ip_forward
```

**5) Required tools present (curl, iptables, etc.)**
```bash
command -v curl
command -v iptables
command -v ip
```

**6) Check available ports (must be free)**
```bash
ss -lntp | grep -E ':(6443|2379|2380|10250|10257|10259)\s'
```

**7) Time sync status**
```bash
timedatectl status | sed -n '1,8p'
```

**8) Hostname + DNS resolution sanity**
```bash
hostname -f
getent hosts "$(hostname -f)"
```

If any checks look off, tell me what you see and I’ll provide the exact fix commands.

### Basic

```
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 22.04.5 LTS
Release:        22.04
Codename:       jammy
6.8.0-1040-aws
 12:14:58 up 16 min,  1 user,  load average: 0.00, 0.06, 0.15
               total        used        free      shared  buff/cache   available
Mem:            15Gi       307Mi        13Gi       0.0Ki       1.3Gi        14Gi
Swap:             0B          0B          0B
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        20G  4.3G   15G  23% /
```

Your outputs look good: 15 GiB RAM free, swap off, and 20 GB disk with 15 GB free — enough for a k0s PoC. The “No LSB modules are available” just means `lsb_release` isn’t installed; not a blocker.

If you want to install `lsb_release` (optional):
```bash
apt-get update
apt-get install -y lsb-release
```

Next, please run the remaining checks so we can confirm kernel modules, sysctl, ports, and time sync:
```bash
lsmod | grep -E 'br_netfilter|overlay'
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.bridge.bridge-nf-call-ip6tables
sysctl net.ipv4.ip_forward
ss -lntp | grep -E ':(6443|2379|2380|10250|10257|10259)\s'
timedatectl status | sed -n '1,8p'
```

Send the output and I’ll provide the exact fix commands (if needed) and the k0s install steps.

LSB = Linux Standard Base. It’s a (mostly legacy) standard for system metadata and behavior across Linux distributions.
lsb_release just prints distro info (name, version, codename). It’s not required for k0s; it’s only useful for scripts or diagnostics that want a standardized way to read OS details. If you don’t need that, you can skip installing it.

Installed LSB
```
cloud_user@dfd1c4cd1f084bbda962d1936d0808871c:~$ sudo apt-get install -y lsb-release
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
lsb-release is already the newest version (11.1.0ubuntu4).
lsb-release set to manually installed.
0 upgraded, 0 newly installed, 0 to remove and 61 not upgraded.
cloud_user@dfd1c4cd1f084bbda962d1936d0808871c:~$ lsb_release -a
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 22.04.5 LTS
Release:        22.04
Codename:       jammy


I installed lsb

cloud_user@dfd1c4cd1f084bbda962d1936d0808871c:~$ lsb_release -a
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 22.04.5 LTS
Release:        22.04
Codename:       jammy

The remaining checks:

cloud_user@dfd1c4cd1f084bbda962d1936d0808871c:~$ lsmod | grep -E 'br_netfilter|overlay'
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.bridge.bridge-nf-call-ip6tables
sysctl net.ipv4.ip_forward
ss -lntp | grep -E ':(6443|2379|2380|10250|10257|10259)\s'
timedatectl status | sed -n '1,8p'
sysctl: cannot stat /proc/sys/net/bridge/bridge-nf-call-iptables: No such file or directory
sysctl: cannot stat /proc/sys/net/bridge/bridge-nf-call-ip6tables: No such file or directory
net.ipv4.ip_forward = 0
               Local time: Sat 2026-01-17 13:01:47 UTC
           Universal time: Sat 2026-01-17 13:01:47 UTC
                 RTC time: Sat 2026-01-17 13:01:46
                Time zone: Etc/UTC (UTC, +0000)
System clock synchronized: yes
              NTP service: active
          RTC in local TZ: no

```

Starting: *Interpret remaining checks* (1/3)

Progress: I reviewed your outputs and will give the exact fix commands next.

You’re missing the bridge netfilter sysctls and IP forwarding is off. That means `br_netfilter` isn’t loaded and forwarding needs enabling. Run the following as root:

**1) Load required modules now**
```bash
modprobe overlay
modprobe br_netfilter
```

**2) Make them load on boot**
```bash
cat <<'EOF' >/etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
```

**3) Set required sysctls**
```bash
cat <<'EOF' >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system
```

**4) Re-check**
```bash
lsmod | grep -E 'br_netfilter|overlay'
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.bridge.bridge-nf-call-ip6tables
sysctl net.ipv4.ip_forward
```

Also, `lsb_release -a` still shows “No LSB modules are available” even after installing; that’s fine on some minimal images. Nothing to fix for k0s.

Once the re-check shows `= 1` for the sysctls and modules are listed, you’re ready for k0s install.

```
root@dfd1c4cd1f084bbda962d1936d0808871c:/home/cloud_user# lsmod | grep -E 'br_netfilter|overlay'
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.bridge.bridge-nf-call-ip6tables
sysctl net.ipv4.ip_forward
br_netfilter           32768  0
bridge                421888  1 br_netfilter
overlay               212992  0
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
```

## Installation

Below is a minimal single‑node k0s install for Ubuntu 22.04 (run as root). It installs k0s, runs it as a controller+worker, and sets up `kubectl`.

**1) Download k0s**
```bash
curl -sSLf https://get.k0s.sh | sh
```

**2) Install as a service (single node)**
```bash
k0s install controller --single
systemctl daemon-reload
systemctl enable --now k0scontroller
```

**3) Get kubeconfig and set up kubectl**
```bash
mkdir -p /root/.kube
k0s kubeconfig admin > /root/.kube/config
```

**4) Verify**
```bash
k0s status
kubectl get nodes
kubectl get pods -A
```

If you want to use a non-root user for `kubectl`, tell me the username and I’ll provide the exact commands.


```
root@dfd1c4cd1f084bbda962d1936d0808871c:/home/cloud_user# curl -sSLf https://get.k0s.sh | sh
Downloading k0s from URL: https://github.com/k0sproject/k0s/releases/download/v1.34.3+k0s.0/k0s-v1.34.3+k0s.0-amd64
k0s is now executable in /usr/local/bin
You can use it to complete the installation of k0s on this node, 
see https://docs.k0sproject.io/stable/install/ for more information.
root@dfd1c4cd1f084bbda962d1936d0808871c:/home/cloud_user# k0s install controller --single
systemctl daemon-reload
systemctl enable --now k0scontroller

root@dfd1c4cd1f084bbda962d1936d0808871c:/home/cloud_user# k0s status
kubectl get nodes
kubectl get pods -A
Version: v1.34.3+k0s.0
Process ID: 3951
Role: controller
Workloads: true
SingleNode: true
Kube-api probing successful: true
Kube-api probing last error:  
Command 'kubectl' not found, but can be installed with:
snap install kubectl
Command 'kubectl' not found, but can be installed with:
snap install kubectl

root@dfd1c4cd1f084bbda962d1936d0808871c:/home/cloud_user# k0s install kubectl
Error: unknown command "kubectl" for "k0s install"
root@dfd1c4cd1f084bbda962d1936d0808871c:/home/cloud_user# snap install kubectl --classic
kubectl get nodes
kubectl 1.34.3 from Canonical✓ installed
NAME                                                 STATUS   ROLES           AGE     VERSION
dfd1c4cd1f084bbda962d1936d0808871c.mylabserver.com   Ready    control-plane   2m25s   v1.34.3+k0s

NAME                                                 STATUS   ROLES           AGE     VERSION
dfd1c4cd1f084bbda962d1936d0808871c.mylabserver.com   Ready    control-plane   2m31s   v1.34.3+k0s
root@dfd1c4cd1f084bbda962d1936d0808871c:/home/cloud_user# kubectl get pods
No resources found in default namespace.
root@dfd1c4cd1f084bbda962d1936d0808871c:/home/cloud_user# kubectl get pods -A
NAMESPACE     NAME                              READY   STATUS    RESTARTS   AGE
kube-system   coredns-6c65b966d4-z8xdp          1/1     Running   0          2m42s
kube-system   kube-proxy-zb72b                  1/1     Running   0          2m41s
kube-system   kube-router-76mdq                 1/1     Running   0          2m41s
kube-system   metrics-server-67bc669cf4-d7w5g   1/1     Running   0          2m38s
```

## Demo App Candidates

Starting: *Research React+Java demo apps* (1/3)

Using "Fetch Web Page"

Fetched 3 resources

Using "Fetch Web Page"

Fetched 2 resources

Using "Fetch Web Page"

Fetched 2 resources

Using "Fetch Web Page"

Fetched 2 resources

Using "Fetch Web Page"

Fetched 2 resources

Using "Fetch Web Page"

Fetched 2 resources

Completed: *Research React+Java demo apps* (1/3)

Here are three good candidates (React frontend + Java backend, multi‑container). Choose one:

1) **Spring Petclinic (REST + React)**  
- Backend: https://github.com/spring-petclinic/spring-petclinic-rest  
- Frontend: https://github.com/spring-petclinic/spring-petclinic-reactjs  
- Well-known sample, stable, easy to demo. Two containers (frontend + backend), optional DB container.

2) **Corona Tracker (Spring Boot + React + MongoDB)**  
- Repo: https://github.com/amrityam/spring-boot-reactjs-kubernetes  
- Explicit Docker + Kubernetes instructions; includes frontend, backend, and MongoDB (3 containers). Good k8s-ready demo.

3) **Yugastore (React UI + Spring Boot microservices)**  
- Repo: https://github.com/YugabyteDB-Samples/yugastore-k8s  
- Realistic microservices app for Kubernetes with React UI and Spring Boot services. Heavier but impressive.

---

None of this is actually great because the first two are fairly old, the number three is unnecessarily complex. What I want to be able to do is to run two containers of a frontend and two of the backend in order to play with a load balancing inside this Kubernetes cluster. 

---

## Build on Mac

# 1) Create and use a buildx builder (one-time)
docker buildx create --name multiarch --use

# 2) Build + push backend (Java 21) for amd64
cd demo-app/backend
docker buildx build --platform linux/amd64 \
  -t miroadamy/demo-backend:java21 \
  --push .

# 3) Build + push frontend for amd64
cd ../frontend
docker buildx build --platform linux/amd64 \
  -t miroadamy/demo-frontend:latest \
  --push .

```

```
ssh -i ~/.ssh/id_rsa cloud_user@dfd1c4cd1f084bbda962d1936d0808871c.mylabserver.com
```