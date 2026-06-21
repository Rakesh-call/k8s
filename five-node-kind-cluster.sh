#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "🚀 Starting Kubernetes playground setup..."

# 1. Install kubectl
if ! command -v kubectl &> /dev/null; then
    echo "📥 kubectl not found. Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin/kubectl
    echo "✅ kubectl installed successfully!"
else
    echo "🎉 kubectl is already installed."
fi

# 2. Install KIND
if ! command -v kind &> /dev/null; then
    echo "📥 KIND not found. Installing KIND..."
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
    echo "✅ KIND installed successfully!"
else
    echo "🎉 KIND is already installed."
fi

# 3. Create KIND Configuration (1 Control Plane + 4 Worker Nodes)
echo "📝 Creating KIND cluster configuration file..."
cat <<EOF > kind-4workers.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
- role: worker
- role: worker
EOF

# 4. Spin up the cluster
echo "🏗️ Creating cluster with 4 worker nodes. This might take a couple of minutes..."
kind create cluster --config kind-4workers.yaml --name practice-cluster

# 5. Verify the Cluster
echo "🔍 Verifying cluster nodes..."
kubectl cluster-info --context kind-practice-cluster
echo "-----------------------------------------------------"
kubectl get nodes

echo "⚡ Setup complete! Your cluster with 4 worker nodes is ready."
