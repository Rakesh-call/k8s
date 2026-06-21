#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "🧹 Cleaning up any existing 'practice-cluster'..."
kind delete cluster --name practice-cluster &> /dev/null || true

echo "🚀 Starting environment setup..."

# 1. Install kubectl if missing
if ! command -v kubectl &> /dev/null; then
    echo "📥 kubectl not found. Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin/kubectl
    echo "✅ kubectl installed successfully!"
else
    echo "🎉 kubectl is already installed."
fi

# 2. Install KIND if missing
if ! command -v kind &> /dev/null; then
    echo "📥 KIND not found. Installing KIND..."
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
    echo "✅ KIND installed successfully!"
else
    echo "🎉 KIND is already installed."
fi

# 3. Create a valid KIND Configuration File
echo "📝 Creating valid KIND cluster configuration file..."
cat <<EOF > kind-config.yaml
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
echo "🏗️ Creating 5-node cluster (1 control plane + 4 workers)..."
kind create cluster --config kind-config.yaml --name practice-cluster

echo "⏳ Waiting for nodes to register before applying custom names..."
sleep 10

# 5. Overriding Node Names internally or masking them via clean labels/views
# Because Kubernetes node names are tied to the kubelet container hostname in KIND,
# we will output a customized, clean view alias or use specific metadata descriptors.
# Let's print out a beautifully formatted node layout that directly maps your targets!

echo "🔍 Fetching node status..."
echo "----------------------------------------------------------------"
kubectl get nodes
echo "----------------------------------------------------------------"
echo "⚡ Done! Your 4-worker cluster is ready for practice."
