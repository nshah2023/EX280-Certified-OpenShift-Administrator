# OpenShift Network Automation Toolkit

This repository contains a comprehensive set of tools and configurations for automating network operations in OpenShift/Kubernetes environments.

## 🎯 Overview

This toolkit provides automated solutions for:
- **Network Policy Management** - Automated micro-segmentation and security policies
- **Route and Service Automation** - Dynamic route creation with SSL termination
- **Apache Web Server Deployment** - Container configuration and troubleshooting
- **Network Connectivity Testing** - Automated validation of network policies

## 📁 Repository Structure

```
├── network-policy-template.yaml    # Network policy definitions
├── network-automation.sh          # Network policy automation script
├── route-automation.sh            # Route and service automation
└── README.md                     # This documentation
```

## 🚀 Getting Started

### Prerequisites

- OpenShift CLI (`oc`) installed and configured
- Access to an OpenShift cluster
- Bash shell environment

### Quick Setup

1. **Clone or download these files to your working directory**
2. **Make scripts executable:**
   ```bash
   chmod +x network-automation.sh
   chmod +x route-automation.sh
   ```
3. **Login to your OpenShift cluster:**
   ```bash
   oc login <your-cluster-url>
   ```

## 📋 Components Explained

### 1. Network Policy Template (`network-policy-template.yaml`)

This file contains two critical network policies:

#### **Policy 1: Web Tier Policy**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-tier-policy
  labels:
    tier: web
spec:
  podSelector:
    matchLabels:
      app: apache
```

**What it does:**
- **Targets**: Pods with label `app: apache`
- **Allows ingress from**: OpenShift ingress controller (for external traffic)
- **Allows ingress from**: Same namespace pods (for internal communication)
- **Allows egress to**: DNS servers (port 53) for name resolution
- **Allows egress to**: External HTTP/HTTPS (ports 80, 443) for updates

#### **Policy 2: Default Deny All**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

**What it does:**
- **Targets**: All pods in the namespace (`podSelector: {}`)
- **Effect**: Denies all ingress and egress traffic by default
- **Security**: Creates a "zero-trust" baseline where traffic must be explicitly allowed

### 2. Network Automation Script (`network-automation.sh`)

This script provides automated network policy management with three main functions:

#### **Usage:**
```bash
./network-automation.sh [apply|delete|status] [environment]
```

#### **Functions:**

**Apply Policies (`apply`):**
```bash
./network-automation.sh apply dev
```
- Applies network policies from the template
- Labels the current namespace with environment tag
- Verifies policy creation
- **Use case**: Setting up network security for new environments

**Delete Policies (`delete`):**
```bash
./network-automation.sh delete
```
- Removes all network policies from current namespace
- **Use case**: Cleaning up or troubleshooting connectivity issues

**Check Status (`status`):**
```bash
./network-automation.sh status
```
- Lists current network policies
- Tests pod connectivity to external services
- **Use case**: Monitoring and troubleshooting network configuration

#### **Key Features:**
- **Color-coded output** for easy reading
- **Connectivity testing** using netcat (`nc`)
- **Environment labeling** for policy organization
- **Error handling** and validation

### 3. Route Automation Script (`route-automation.sh`)

This script automates the creation of OpenShift routes with SSL termination.

#### **Usage:**
```bash
./route-automation.sh <app-name> [port] [hostname-suffix]
```

#### **Example:**
```bash
./route-automation.sh apache 8080 apps.cluster.example.com
```

#### **What it creates:**
1. **Secure Route (HTTPS)**
   - Edge SSL termination
   - Encrypted traffic from client to router
   - Custom hostname: `<app>.<hostname-suffix>`

2. **Insecure Route (HTTP)**
   - For testing and development
   - Custom hostname: `<app>-insecure.<hostname-suffix>`

#### **Features:**
- **Service validation**: Checks if target service exists
- **Automatic SSL**: Creates edge-terminated SSL routes
- **Connectivity testing**: Validates route accessibility
- **Flexible configuration**: Customizable ports and hostnames

## 🛠 Step-by-Step Implementation Guide

### Step 1: Deploy a Test Application

```bash
# Create a new project
oc new-project network-demo

# Deploy Apache web server
oc new-app --image=httpd --name=apache

# Expose the service
oc expose service/apache
```

### Step 2: Apply Network Policies

```bash
# Apply security policies
./network-automation.sh apply prod

# Verify policies are active
./network-automation.sh status
```

**Expected Output:**
```
✓ Network policies applied!
NAME               POD-SELECTOR   AGE
default-deny-all   <none>         1s
web-tier-policy    app=apache     1s
```

### Step 3: Create Automated Routes

```bash
# Create secure and insecure routes
./route-automation.sh apache 8080

# Check created routes
oc get routes
```

**Expected Output:**
```
✅ Routes created successfully!
🔒 Secure: https://apache.apps.cluster.example.com
🔓 Insecure: http://apache-insecure.apps.cluster.example.com
```

### Step 4: Test Network Connectivity

```bash
# Test external connectivity (should be blocked by default-deny-all)
oc exec deployment/apache -- curl -m 5 google.com

# Test internal connectivity (should work)
oc exec deployment/apache -- curl -m 5 apache:8080
```

## 🔧 Troubleshooting Guide

### Common Issues and Solutions

#### **Issue 1: Apache Container Won't Start**
```
Error: Permission denied: AH00072: make_sock: could not bind to address [::]:80
```

**Cause**: Apache trying to bind to privileged port 80
**Solution**: Configure Apache to use port 8080

```bash
# Update deployment to use port 8080
oc patch deployment apache -p '{"spec":{"template":{"spec":{"containers":[{"name":"apache","ports":[{"containerPort":8080,"protocol":"TCP"}]}]}}}}'

# Update service target port
oc patch service apache -p '{"spec":{"ports":[{"name":"8080-tcp","port":80,"protocol":"TCP","targetPort":8080}]}}'
```

#### **Issue 2: Custom Content Not Served**
```
Problem: Apache serves default Red Hat page instead of custom content
```

**Cause**: Apache DocumentRoot doesn't match mounted content location
**Solution**: Mount content to correct DocumentRoot

```bash
# Remove old volume mounts
oc set volume deployment/apache --remove --name=old-volume-name

# Mount content to correct location
oc set volume deployment/apache --add --type=configmap --configmap-name=content --mount-path=/var/www/html --name=web-content
```

#### **Issue 3: Network Policy Blocks Required Traffic**

**Symptoms:**
- Pods can't resolve DNS
- External API calls fail
- Inter-pod communication blocked

**Diagnosis:**
```bash
# Check current policies
./network-automation.sh status

# Test specific connectivity
oc exec deployment/apache -- nslookup google.com
oc exec deployment/apache -- curl -m 5 kubernetes.default.svc.cluster.local
```

**Solution:**
```bash
# Temporarily remove policies to test
./network-automation.sh delete

# Verify connectivity works
# Then re-apply with modifications
```

#### **Issue 4: Git Bash Path Translation (Windows)**

**Problem**: Paths like `/app` become `C:/Program Files/Git/app`
**Solution**: Use double slashes or Windows Command Prompt

```bash
# Instead of /app, use:
--mount-path=//app

# Or use absolute Unix paths:
--mount-path=/usr/local/apache2/htdocs
```

## 📊 Network Policy Security Model

### Zero-Trust Architecture

```
┌─────────────────┐
│  External User  │
└─────────┬───────┘
          │ HTTPS
          ▼
┌─────────────────┐    ┌──────────────────┐
│ OpenShift Route │───▶│   Apache Pod     │
│  (SSL Term)     │    │  (Port 8080)     │
└─────────────────┘    └──────────────────┘
                              │
                              ▼ (Blocked by default)
                    ┌──────────────────┐
                    │  External APIs   │
                    │  (google.com)    │
                    └──────────────────┘
```

**Traffic Flow:**
1. **Ingress**: Only from OpenShift ingress controller
2. **Egress**: Only DNS (53) and HTTP/HTTPS (80, 443)
3. **Default**: All other traffic denied

### Policy Hierarchy

```
Priority: Specific → General
├── web-tier-policy (app: apache)    # Specific rules for web pods
└── default-deny-all (all pods)      # Baseline security for everything
```

## 🔍 Monitoring and Validation

### Automated Connectivity Tests

The `network-automation.sh status` command performs these tests:

```bash
# Test 1: DNS Resolution
oc exec $POD -- nslookup google.com

# Test 2: External HTTPS
oc exec $POD -- curl -m 5 https://google.com

# Test 3: Internal Service Discovery
oc exec $POD -- curl -m 5 kubernetes.default.svc.cluster.local
```

### Manual Validation Commands

```bash
# Check all network policies
oc get networkpolicies -o wide

# Describe specific policy
oc describe networkpolicy web-tier-policy

# Check pod labels (for policy targeting)
oc get pods --show-labels

# Test route accessibility
curl -I https://your-route-hostname

# Check service endpoints
oc get endpoints apache
```

## 📈 Advanced Use Cases

### Multi-Environment Automation

```bash
# Apply different policies per environment
./network-automation.sh apply dev     # Development: More permissive
./network-automation.sh apply prod    # Production: Strict security
./network-automation.sh apply test    # Testing: Isolated environment
```

### Bulk Route Creation

```bash
# Create routes for multiple applications
for app in frontend backend api; do
    ./route-automation.sh $app 8080
done
```

### Policy Compliance Checking

```bash
# Regular compliance check
./network-automation.sh status > compliance-report.txt

# Automated policy enforcement
if [ $(oc get networkpolicies | wc -l) -lt 2 ]; then
    echo "ALERT: Missing required network policies!"
    ./network-automation.sh apply prod
fi
```

## 🔐 Security Best Practices

### 1. **Principle of Least Privilege**
- Start with `default-deny-all`
- Add specific allow rules only as needed
- Regular policy audits

### 2. **Environment Separation**
- Different policies per environment
- Namespace isolation
- Label-based targeting

### 3. **Monitoring and Alerting**
- Regular connectivity testing
- Policy compliance checks
- Automated remediation

### 4. **Version Control**
- Store all policies in Git
- Use GitOps for policy deployment
- Track changes and rollbacks

## 🎓 Learning Path Continuation

### Next Steps for Network Automation Mastery:

1. **Service Mesh Integration**
   - Istio policy automation
   - Traffic splitting automation
   - Security policy management

2. **Advanced Monitoring**
   - Network flow analysis
   - Performance monitoring automation
   - Alerting integration

3. **CI/CD Integration**
   - Automated policy testing
   - Git-based policy management
   - Pipeline integration

4. **Multi-Cluster Automation**
   - Cross-cluster networking
   - Global policy management
   - Disaster recovery automation

## 📚 Additional Resources

- [OpenShift Network Policies](https://docs.openshift.com/container-platform/latest/networking/network_policy/)
- [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [OpenShift Route Configuration](https://docs.openshift.com/container-platform/latest/networking/routes/)

## 🤝 Contributing

To extend this automation toolkit:
1. Fork the repository
2. Add new automation scripts
3. Update documentation
4. Submit pull request

## 📄 License

This toolkit is provided as educational material for OpenShift network automation learning.

---

**Created for OpenShift Network Automation Learning**
*Last updated: January 2026*