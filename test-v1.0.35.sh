#!/bin/bash
# 测试服务器部署脚本 - v1.0.35 测试
# Test script for v1.0.35 deployment

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Testing v1.0.35 on Test Server${NC}"
echo -e "${BLUE}  测试服务器部署 v1.0.35${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Step 1: 停止并删除旧容器
echo -e "${YELLOW}[Step 1]${NC} Stopping old container..."
docker stop puppy-stardew 2>/dev/null || true
docker rm puppy-stardew 2>/dev/null || true
echo -e "${GREEN}✓ Old container removed${NC}"
echo ""

# Step 2: 拉取最新镜像
echo -e "${YELLOW}[Step 2]${NC} Pulling latest image (v1.0.35)..."
docker pull truemanlive/puppy-stardew-server:latest
echo -e "${GREEN}✓ Image pulled${NC}"
echo ""

# Step 3: 检查.env文件
echo -e "${YELLOW}[Step 3]${NC} Checking configuration..."
if [ ! -f ".env" ]; then
    echo -e "${RED}✗ .env file not found!${NC}"
    echo "Please create .env file with Steam credentials"
    exit 1
fi
echo -e "${GREEN}✓ .env file exists${NC}"
echo ""

# Step 4: 初始化数据目录
echo -e "${YELLOW}[Step 4]${NC} Setting up data directories..."
mkdir -p data/{saves,game,steam,logs}
chown -R 1000:1000 data/
echo -e "${GREEN}✓ Directories ready${NC}"
echo ""

# Step 5: 启动容器
echo -e "${YELLOW}[Step 5]${NC} Starting container..."
docker run -d \
  --name puppy-stardew \
  --restart unless-stopped \
  -it \
  -e STEAM_USERNAME="${STEAM_USERNAME:-}" \
  -e STEAM_PASSWORD="${STEAM_PASSWORD:-}" \
  -e ENABLE_VNC=true \
  -e VNC_PASSWORD=stardew123 \
  -p 24642:24642/udp \
  -p 5900:5900/tcp \
  -v $(pwd)/data/saves:/home/steam/.config/StardewValley:rw \
  -v $(pwd)/data/game:/home/steam/stardewvalley:rw \
  -v $(pwd)/data/steam:/home/steam/Steam:rw \
  -v $(pwd)/data/logs:/home/steam/.local/share/puppy-stardew/logs:rw \
  truemanlive/puppy-stardew-server:latest

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Container started${NC}"
else
    echo -e "${RED}✗ Failed to start container${NC}"
    exit 1
fi
echo ""

# Step 6: 等待启动
echo -e "${YELLOW}[Step 6]${NC} Waiting for initialization (10 seconds)..."
sleep 10
echo ""

# Step 7: 显示日志
echo -e "${YELLOW}[Step 7]${NC} Showing container logs..."
echo -e "${BLUE}========================================${NC}"
docker logs puppy-stardew 2>&1 | tail -50
echo -e "${BLUE}========================================${NC}"
echo ""

# Step 8: 检查容器状态
echo -e "${YELLOW}[Step 8]${NC} Checking container status..."
if docker ps | grep -q puppy-stardew; then
    echo -e "${GREEN}✓ Container is running${NC}"

    # 检查是否需要Steam Guard
    if docker logs puppy-stardew 2>&1 | grep -q "STEAM GUARD"; then
        echo -e "${YELLOW}⚠ Steam Guard authentication required${NC}"
        echo ""
        echo -e "${CYAN}To input Steam Guard code:${NC}"
        echo -e "  ${GREEN}docker attach puppy-stardew${NC}"
        echo ""
        echo -e "After entering code, wait for game download to complete."
        echo -e "You can detach with: Ctrl+P, Ctrl+Q"
    elif docker logs puppy-stardew 2>&1 | grep -q "downloading"; then
        echo -e "${GREEN}✓ Game is downloading${NC}"
    elif docker logs puppy-stardew 2>&1 | grep -q "Game downloaded"; then
        echo -e "${GREEN}✓ Game already downloaded${NC}"
    fi
else
    echo -e "${RED}✗ Container is not running${NC}"
    echo "Showing full logs:"
    docker logs puppy-stardew
    exit 1
fi
echo ""

# Step 9: 监控日志
echo -e "${YELLOW}[Step 9]${NC} Monitoring logs (Ctrl+C to stop)..."
echo -e "${BLUE}========================================${NC}"
docker logs -f puppy-stardew
