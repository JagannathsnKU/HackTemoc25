#!/bin/bash

# Atlas Brev Deployment Script
# Run this in your Brev server terminal

echo "======================================"
echo "  ATLAS BREV A100 DEPLOYMENT"
echo "======================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Step 1: Installing Docker...${NC}"
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
echo -e "${GREEN}✅ Docker installed${NC}\n"

echo -e "${GREEN}Step 2: Installing NVIDIA Container Toolkit...${NC}"
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update
sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker
echo -e "${GREEN}✅ NVIDIA Container Toolkit installed${NC}\n"

echo -e "${GREEN}Step 3: Testing GPU access...${NC}"
docker run --rm --gpus all nvidia/cuda:12.2-base nvidia-smi
echo -e "${GREEN}✅ GPU accessible${NC}\n"

echo -e "${YELLOW}Step 4: Login to NVIDIA NGC...${NC}"
echo "Username: \$oauthtoken"
echo "Password: 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"
docker login nvcr.io

echo -e "${GREEN}Step 5: Deploying Orchestrator NIM (this will take 5-10 minutes)...${NC}"
docker run -d --gpus all --name atlas-orchestrator \
  --restart unless-stopped \
  -p 8001:8000 \
  -e NVIDIA_API_KEY=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 \
  nvcr.io/nim/nvidia/nemotron-4-340b-instruct:latest

echo -e "${YELLOW}Waiting for NIM to start (this may take a while)...${NC}"
echo "You can check progress with: docker logs atlas-orchestrator -f"
echo ""

echo -e "${GREEN}Step 6 (Optional): Deploying Scout VLM...${NC}"
read -p "Deploy Scout VLM for photo analysis? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    docker run -d --gpus all --name atlas-scout-vlm \
      --restart unless-stopped \
      -p 8002:8000 \
      -e NVIDIA_API_KEY=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 \
      nvcr.io/nim/nvidia/llama-3.1-nemotron-nano-vl-8b-v1:latest
    echo -e "${GREEN}✅ Scout VLM deploying${NC}\n"
fi

echo ""
echo -e "${GREEN}======================================"
echo "  DEPLOYMENT COMPLETE!"
echo "======================================${NC}"
echo ""
echo "Your NIMs are now deploying on the A100 GPU!"
echo ""
echo "Check status:"
echo "  docker ps"
echo ""
echo "View logs:"
echo "  docker logs atlas-orchestrator -f"
echo ""
echo "Get your server IP:"
echo "  curl ifconfig.me"
echo ""
echo "Test the NIM (wait 10 minutes first):"
echo "  curl http://localhost:8001/v1/models"
echo ""
echo -e "${YELLOW}Next: Copy the IP address and use it in start_auto_agents.ps1 on Windows!${NC}"
echo ""
