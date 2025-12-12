#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Checking external access configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

SERVER_IP=$(hostname -I | awk '{print $1}')
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "Unable to detect")

echo "🖥️  Server Information:"
echo "   Local IP:  $SERVER_IP"
echo "   Public IP: $PUBLIC_IP"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Checking Docker ports"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check_port() {
    local port=$1
    local service=$2
    
    if docker ps --format '{{.Names}} {{.Ports}}' | grep -q ":${port}->"; then
        echo "✅ Port $port ($service) - Container is running"
        
        if ss -tuln | grep -q ":${port} "; then
            LISTEN_ADDR=$(ss -tuln | grep ":${port} " | awk '{print $5}')
            if [[ $LISTEN_ADDR == 0.0.0.0:* ]] || [[ $LISTEN_ADDR == *:$port ]]; then
                echo "   ✅ Listening on all interfaces (0.0.0.0)"
            elif [[ $LISTEN_ADDR == 127.0.0.1:* ]]; then
                echo "   ❌ Only listening on localhost!"
                echo "   💡 Change port mapping to '0.0.0.0:${port}:${port}' in docker-compose"
            fi
        fi
    else
        echo "❌ Port $port ($service) - Container not running"
    fi
}

check_port 8080 "API Gateway"
check_port 3000 "Grafana"
check_port 9090 "Prometheus"
check_port 5432 "PostgreSQL"
check_port 9042 "Cassandra"
check_port 9092 "Kafka"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔥 Checking Firewall"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check_firewall_port() {
    local port=$1
    local service=$2
    
    echo -n "Port $port ($service): "
    
    if command -v ufw &> /dev/null; then
        if sudo ufw status | grep -q "$port.*ALLOW"; then
            echo "✅ Open (UFW)"
        else
            echo "❌ Blocked (UFW)"
        fi
    elif command -v firewall-cmd &> /dev/null; then
        if sudo firewall-cmd --list-ports | grep -q "$port/tcp"; then
            echo "✅ Open (firewalld)"
        else
            echo "❌ Blocked (firewalld)"
        fi
    else
        if ss -tuln | grep -q ":${port} "; then
            echo "⚠️  Firewall not detected, port is listening"
        else
            echo "❓ Unable to determine"
        fi
    fi
}

check_firewall_port 8080 "API Gateway"
check_firewall_port 3000 "Grafana"
check_firewall_port 9090 "Prometheus"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 Testing connectivity"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

test_endpoint() {
    local port=$1
    local service=$2
    local path=${3:-/}
    
    echo -n "Testing $service (port $port)... "
    
    if curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://localhost:${port}${path}" > /tmp/curl_response 2>&1; then
        HTTP_CODE=$(cat /tmp/curl_response)
        if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 400 ]; then
            echo "✅ Responding (HTTP $HTTP_CODE)"
        else
            echo "⚠️  Responding but with HTTP $HTTP_CODE"
        fi
    else
        echo "❌ Not responding"
    fi
}

test_endpoint 8080 "API Gateway" "/health"
test_endpoint 3000 "Grafana" "/"
test_endpoint 9090 "Prometheus" "/"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "To access from external machine, use these URLs:"
echo ""
echo "  📡 API Gateway:  http://$SERVER_IP:8080"
echo "  📊 Grafana:      http://$SERVER_IP:3000"
echo "  📈 Prometheus:   http://$SERVER_IP:9090"
echo ""

if [ "$PUBLIC_IP" != "Unable to detect" ] && [ "$PUBLIC_IP" != "$SERVER_IP" ]; then
    echo "If accessing from internet, use public IP:"
    echo ""
    echo "  📡 API Gateway:  http://$PUBLIC_IP:8080"
    echo "  📊 Grafana:      http://$PUBLIC_IP:3000"
    echo "  📈 Prometheus:   http://$PUBLIC_IP:9090"
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 Next steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "If ports are blocked by firewall, run:"
echo "  sudo ./open-firewall.sh"
echo ""
echo "To test from your local machine:"
echo "  curl http://$SERVER_IP:8080/health"
echo ""

