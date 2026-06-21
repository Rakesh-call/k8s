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

# 3. Create Custom KIND Configuration File
echo "📝 Creating KIND cluster configuration file with custom node names..."
cat <<EOF > kind-custom.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  name: control-node
- role: worker
  name: worker1
- role: worker
  name: worker2
- role: worker
  name: worker3
- role: worker
  name: worker4
EOF

# 4. Spin up the cluster
echo "🏗️ Creating 5-node cluster (control-node + worker1 to worker4)..."
kind create cluster --config kind-custom.yaml --name practice-cluster

# 5. Verify the Final Output
echo "🔍 Fetching node status..."
echo "----------------------------------------------------------------"
kubectl get nodes
echo "----------------------------------------------------------------"
echo "⚡ Done! Your custom playground is ready for practice."
