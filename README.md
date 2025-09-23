# Wisecow Application - AWS EKS Deployment 

#Link of Video Demonstration of Deployment  -
https://drive.google.com/file/d/1OqdGa2WKOMJtlWzj9IYCLZbgZ6WPv_iW/view?usp=sharing

## Overview
This guide provides step-by-step instructions to deploy the Wisecow application on Amazon EKS with HTTPS using Cert-Manager, Self- Assigned and Let's Encrypt certificates, Nginx Controller and AWS Load Balancer.

## Prerequisites
- AWS CLI configured with appropriate permissions
- kubectl installed
- Docker installed
- A registered domain name 
- Domain DNS managed by Route53 (recommended)

## Step 1: Create EKS Kind Cluster
```
cd KIND
kind create cluster --name accuknox_wisecow --config kind-config.yaml
```

## Step 2: Install AWS Load Balancer Controller

```bash
# Create IAM OIDC provider
eksctl utils associate-iam-oidc-provider --region=us-west-2 --cluster=wisecow-cluster --approve

# Download IAM policy
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json

# Create IAM policy
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

# Create IAM service account
eksctl create iamserviceaccount \
  --cluster=wisecow-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::ACCOUNT-ID:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

# Install AWS Load Balancer Controller
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=wisecow-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

## Step 3: Install cert-manager

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Wait for cert-manager to be ready
kubectl wait --namespace cert-manager --for=condition=ready pod --selector=app=cert-manager --timeout=90s
```

## Step 4: Build and Push Docker Image

```bash
# Build Docker image
docker build -t wisecow:latest .

# Tag for ECR (replace ACCOUNT-ID and REGION)
docker tag wisecow:latest ACCOUNT-ID.dkr.ecr.REGION.amazonaws.com/wisecow:latest

# Login to ECR
aws ecr get-login-password --region REGION | docker login --username AWS --password-stdin ACCOUNT-ID.dkr.ecr.REGION.amazonaws.com

# Push image
docker push ACCOUNT-ID.dkr.ecr.REGION.amazonaws.com/wisecow:latest
```

## Step 5: Update Kubernetes Manifests

### Update deployment.yaml
```yaml
# Update image in k8s/deployment.yaml
image: ACCOUNT-ID.dkr.ecr.REGION.amazonaws.com/wisecow:latest
imagePullPolicy: Always
```


### Update ingress.yaml
```yaml
# Update host in k8s/ingress.yaml
- host: domain.xyz
```

## Step 6: Deploy Application

```bash
# Create a Nampspace
kubectl apply -f k8s/1-namespace.yml

# Apply cert-manager issuer
kubectl apply -f k8s/2-cert.yml

# Apply Issue Certificate
kubectl apply -f k8s/Certificate.yml

# Deploy application
kubectl apply -f k8s/3-deployment.yml

#Apply Service
kubectl apply -f k8s/4-service.yml

# Wait for deployment
kubectl wait --for=condition=available --timeout=300s deployment/wisecow-deployment

# Apply ingress (this will create ALB)
kubectl apply -f k8s/5-ingress.yml
```

## Step 7: Configure DNS

```bash
# Get ALB hostname
kubectl get ingress wisecow-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Create A record pointing domain.xyz to ALB hostname
# Or update your DNS provider to point to the ALB
```

## Step 8: Verify Deployment

```bash
# Check all resources
kubectl get all,ingress,certificate

# Check certificate status
kubectl describe certificate wisecow-tls

# Test application
curl https://domain.xyz
```

## Troubleshooting

### Check pod logs
```bash
kubectl logs -l app=wisecow
```

### Check ingress events
```bash
kubectl describe ingress wisecow-ingress
```

### Check certificate issues
```bash
kubectl describe certificate wisecow-tls
kubectl describe certificaterequest
```

### Check ALB controller logs
```bash
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

## Cleanup

```bash
# Delete application
kubectl delete -f k8s/

# Delete EKS cluster
eksctl delete cluster --name wisecow-cluster --region us-west-2
```

## Important Notes

1. **Replace placeholders:**
   - `ACCOUNT-ID`: Your AWS account ID
   - `REGION`: Your AWS region
   - `domain.xyz`: Your domain name

2. **Security Groups:** Ensure ALB security group allows HTTP (80) and HTTPS (443) traffic

3. **Domain Validation:** Let's Encrypt requires domain to be publicly accessible for HTTP-01 challenge

4. **Costs:** EKS cluster, ALB and Private ECR charges are applicable

# SHELL SCRIPT 

```bash
cd assignment2
chmod 777 <shell_script name>
./<shell_script name>
```

## Note

Check the log files in the path which are mentioned in the shell script


# KubeArmor Policy

### Install KubeArmor into your cluster
```bash
# Add the AccuKnox helm repo
helm repo add kubearmor https://kubearmor.github.io/charts

# Update repos
helm repo update

# Install KubeArmor into kube-system namespace
helm install kubearmor kubearmor/kubearmor -n kube-system --create-namespace
```

### Apply the namespace postures
```bash
kubectl annotate ns wisecow kubearmor-file-posture=block --overwrite
kubectl annotate ns wisecow kubearmor-network-posture=block --overwrite
kubectl annotate ns wisecow kubearmor-capabilities-posture=block --overwrite
```

### Apply the Policy
```bash
kubectl apply -f kubearmor.yml
```

### Test the Policy
```
# try running 'ls' (not in your allowed process list)
kubectl exec -it deploy/wisecow-deployment -n wisecow -- ls /

# or try 'cat'
kubectl exec -it deploy/wisecow-deployment -n wisecow -- cat /etc/hosts
```
