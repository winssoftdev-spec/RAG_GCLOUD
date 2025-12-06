#!/bin/bash

# GCE Startup Script for SQL Generator Backend
# This script installs Docker, Ollama, and runs the application.

# 1. Update and Install Dependencies
echo "Updating system and installing dependencies..."
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release git

# 2. Install Docker
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    sudo systemctl enable docker
    sudo systemctl start docker
else
    echo "Docker already installed."
fi

# 3. Install Ollama
if ! command -v ollama &> /dev/null; then
    echo "Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
else
    echo "Ollama already installed."
fi

# 4. Start Ollama Service
# We need to ensure Ollama listens on all interfaces or is accessible. 
# By default, it listens on localhost:11434.
# For simplicity in this setup, since we are running the app in a container, we can run the container with --network host to access localhost 
# OR configure Ollama to listen on 0.0.0.0.
echo "Configuring Ollama..."
sudo systemctl stop ollama
# Create systemd override to listen on 0.0.0.0 if not already present
sudo mkdir -p /etc/systemd/system/ollama.service.d
echo "[Service]
Environment=\"OLLAMA_HOST=0.0.0.0:11434\"" | sudo tee /etc/systemd/system/ollama.service.d/override.conf

sudo systemctl daemon-reload
sudo systemctl start ollama

# Wait for Ollama to start
sleep 5

# 5. Pull the Llama 3.2 model
echo "Pulling Llama 3.2 model..."
export HOME=/root
nohup ollama pull llama3.2 > /tmp/ollama_pull.log 2>&1 &

# 6. Run Application from Artifact Registry
# Fetch Project ID from Metadata
PROJECT_ID=$(curl -s "http://metadata.google.internal/computeMetadata/v1/project/project-id" -H "Metadata-Flavor: Google")
REGION="us-central1"
REPO_NAME="rag-repo"
IMAGE_NAME="sql-backend"
TAG="latest"
FULL_IMAGE_PATH="$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME:$TAG"

echo "Project ID: $PROJECT_ID"
echo "Configuring Docker for GCP..."
gcloud auth configure-docker $REGION-docker.pkg.dev --quiet

# Remove existing container if it exists
sudo docker rm -f sql-backend-container || true

echo "Pulling image: $FULL_IMAGE_PATH"
# We need to loop pull in case the image isn't ready yet or auth takes a moment
until sudo docker pull $FULL_IMAGE_PATH; do
    echo "Docker pull failed. Retrying in 10 seconds..."
    sleep 10
done

echo "Running Application..."
sudo docker run -d \
    --name sql-backend-container \
    --network host \
    --restart always \
    $FULL_IMAGE_PATH
