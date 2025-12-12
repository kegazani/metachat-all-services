#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔥 Opening firewall ports for MetaChat"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check_firewall() {
    if command -v ufw &> /dev/null; then
        echo "✅ Found UFW (Ubuntu/Debian)"
        return 0
    elif command -v firewall-cmd &> /dev/null; then
        echo "✅ Found firewalld (CentOS/RHEL)"
        return 1
    else
        echo "⚠️  No firewall detected or already disabled"
        return 2
    fi
}

open_ports_ufw() {
    echo ""
    echo "📋 Opening ports with UFW..."
    
    sudo ufw allow 8080/tcp comment "MetaChat API Gateway"
    sudo ufw allow 3000/tcp comment "MetaChat Grafana"
    sudo ufw allow 9090/tcp comment "MetaChat Prometheus"
    
    echo ""
    echo "🔒 Security note: Database ports are NOT opened (good!)"
    echo "   PostgreSQL (5432), Cassandra (9042), Kafka (9092)"
    echo "   These should only be accessible from within the server"
    echo ""
    
    read -p "Do you want to open database ports too? (NOT recommended) [y/N]: " open_db
    if [[ "$open_db" =~ ^[Yy]$ ]]; then
        sudo ufw allow 5432/tcp comment "PostgreSQL"
        sudo ufw allow 9042/tcp comment "Cassandra"
        sudo ufw allow 9092/tcp comment "Kafka"
        echo "⚠️  Database ports opened (security risk!)"
    fi
    
    echo ""
    sudo ufw status numbered
}

open_ports_firewalld() {
    echo ""
    echo "📋 Opening ports with firewalld..."
    
    sudo firewall-cmd --permanent --add-port=8080/tcp
    sudo firewall-cmd --permanent --add-port=3000/tcp
    sudo firewall-cmd --permanent --add-port=9090/tcp
    
    echo ""
    echo "🔒 Security note: Database ports are NOT opened (good!)"
    
    read -p "Do you want to open database ports too? (NOT recommended) [y/N]: " open_db
    if [[ "$open_db" =~ ^[Yy]$ ]]; then
        sudo firewall-cmd --permanent --add-port=5432/tcp
        sudo firewall-cmd --permanent --add-port=9042/tcp
        sudo firewall-cmd --permanent --add-port=9092/tcp
        echo "⚠️  Database ports opened (security risk!)"
    fi
    
    sudo firewall-cmd --reload
    echo ""
    sudo firewall-cmd --list-ports
}

show_status() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 Testing connectivity"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    echo ""
    echo "🌐 Your server IP: $SERVER_IP"
    echo ""
    echo "Test these URLs from your local machine:"
    echo ""
    echo "  📡 API Gateway:  http://$SERVER_IP:8080/health"
    echo "  📊 Grafana:      http://$SERVER_IP:3000"
    echo "  📈 Prometheus:   http://$SERVER_IP:9090"
    echo ""
    
    echo "Testing local connectivity..."
    echo ""
    
    if curl -s http://localhost:8080/health > /dev/null 2>&1; then
        echo "✅ API Gateway responding locally"
    else
        echo "❌ API Gateway not responding (is it running?)"
    fi
    
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        echo "✅ Grafana responding locally"
    else
        echo "⚠️  Grafana not responding (may not be started yet)"
    fi
    
    if curl -s http://localhost:9090 > /dev/null 2>&1; then
        echo "✅ Prometheus responding locally"
    else
        echo "⚠️  Prometheus not responding (may not be started yet)"
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔐 Security Recommendations"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "1. ✅ API Gateway (8080) - Safe to expose"
    echo "2. ✅ Grafana (3000) - Safe, has authentication"
    echo "3. ⚠️  Prometheus (9090) - No auth by default, consider restricting"
    echo "4. 🔒 Databases - NEVER expose to internet!"
    echo ""
    echo "Consider using nginx/caddy as reverse proxy with SSL/TLS"
    echo ""
}

main() {
    if ! check_firewall; then
        FIREWALL_TYPE=$?
        
        if [ $FIREWALL_TYPE -eq 0 ]; then
            open_ports_ufw
        elif [ $FIREWALL_TYPE -eq 1 ]; then
            open_ports_firewalld
        fi
    fi
    
    show_status
}

case "${1:-}" in
    "status")
        show_status
        ;;
    "test")
        show_status
        ;;
    *)
        main
        ;;
esac

echo "✅ Firewall configuration complete!"
echo ""

