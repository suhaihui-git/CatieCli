#!/bin/bash

# CatieCli 一键安装脚本
# 使用方法: curl -sSL https://raw.githubusercontent.com/mzrodyu/CatieCli/main/install.sh | bash

set -e

echo "🐱 CatieCli 一键安装脚本"
echo "========================"

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo "❌ 未安装 Docker，正在安装..."
    curl -fsSL https://get.docker.com | sh
    systemctl start docker
    systemctl enable docker
    echo "✅ Docker 安装完成"
fi

# 检查 Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "❌ 未安装 Docker Compose，正在安装..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo "✅ Docker Compose 安装完成"
fi

# 创建目录
INSTALL_DIR="/opt/catiecli"
echo "📁 安装目录: $INSTALL_DIR"

if [ -d "$INSTALL_DIR" ]; then
    echo "⚠️ 目录已存在，正在更新..."
    cd $INSTALL_DIR
    git pull
else
    echo "📥 正在下载..."
    git clone https://github.com/mzrodyu/CatieCli.git $INSTALL_DIR
    cd $INSTALL_DIR
fi

# 生成随机密钥
SECRET_KEY=$(openssl rand -hex 32)

# 询问管理员密码
echo ""
read -p "🔐 请输入管理员密码 (直接回车使用默认 admin123): " ADMIN_PASSWORD
ADMIN_PASSWORD=${ADMIN_PASSWORD:-admin123}

# 创建 .env 文件
echo "📝 创建配置文件..."
cat > .env << EOF
# CatieCli 配置
ADMIN_USERNAME=admin
ADMIN_PASSWORD=$ADMIN_PASSWORD
SECRET_KEY=$SECRET_KEY
PORT=5001
EOF

echo "✅ 配置文件已创建"

# 启动服务
echo ""
echo "🚀 正在启动服务..."
docker-compose up -d --build

# 等待启动
sleep 5

# 获取 IP
IP=$(curl -s ifconfig.me 2>/dev/null || echo "你的服务器IP")

echo ""
echo "========================================="
echo "✅ CatieCli 安装完成！"
echo "========================================="
echo ""
echo "🌐 访问地址: http://$IP:5001"
echo "👤 用户名: admin"
echo "🔑 密码: $ADMIN_PASSWORD"
echo ""
echo "📋 常用命令:"
echo "   查看日志: cd $INSTALL_DIR && docker-compose logs -f"
echo "   重启服务: cd $INSTALL_DIR && docker-compose restart"
echo "   停止服务: cd $INSTALL_DIR && docker-compose down"
echo "   更新版本: cd $INSTALL_DIR && git pull && docker-compose up -d --build"
echo ""
