#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              MetaChat Services Health Check                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

check_service() {
    local name=$1
    local url=$2
    local response
    
    response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 "$url" 2>/dev/null || echo "000")
    
    if [ "$response" = "200" ] || [ "$response" = "204" ]; then
        printf "  %-25s ${GREEN}✓ UP${NC} (HTTP $response)\n" "$name"
        return 0
    else
        printf "  %-25s ${RED}✗ DOWN${NC} (HTTP $response)\n" "$name"
        return 1
    fi
}

check_tcp() {
    local name=$1
    local host=$2
    local port=$3
    
    if nc -z -w 3 "$host" "$port" 2>/dev/null; then
        printf "  %-25s ${GREEN}✓ UP${NC} (TCP $port)\n" "$name"
        return 0
    else
        printf "  %-25s ${RED}✗ DOWN${NC} (TCP $port)\n" "$name"
        return 1
    fi
}

total=0
healthy=0

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 🌐 API Services"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

services=(
    "API Gateway|http://localhost:8080/health"
    "User Service|http://localhost:50051/health"
    "Diary Service|http://localhost:50052/health"
    "Matching Service|http://localhost:8081/health"
    "Mood Analysis|http://localhost:8000/health"
    "Analytics|http://localhost:8001/health"
    "Archetype|http://localhost:8002/health"
    "Biometric|http://localhost:8003/health"
    "Correlation|http://localhost:8004/health"
)

for service in "${services[@]}"; do
    IFS='|' read -r name url <<< "$service"
    ((total++))
    if check_service "$name" "$url"; then
        ((healthy++))
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 🗄️  Infrastructure"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

infra=(
    "Kafka|localhost|9092"
    "Cassandra|localhost|9042"
    "PostgreSQL|localhost|5432"
    "EventStore|localhost|2113"
    "NATS|localhost|4222"
    "Zookeeper|localhost|2181"
)

for item in "${infra[@]}"; do
    IFS='|' read -r name host port <<< "$item"
    ((total++))
    if check_tcp "$name" "$host" "$port"; then
        ((healthy++))
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 📊 Monitoring"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

monitoring=(
    "Prometheus|http://localhost:9090/-/healthy"
    "Grafana|http://localhost:3000/api/health"
    "Kafka UI|http://localhost:8090/"
)

for service in "${monitoring[@]}"; do
    IFS='|' read -r name url <<< "$service"
    ((total++))
    if check_service "$name" "$url"; then
        ((healthy++))
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 📈 Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

percentage=$((healthy * 100 / total))

if [ $percentage -eq 100 ]; then
    color=$GREEN
elif [ $percentage -ge 80 ]; then
    color=$YELLOW
else
    color=$RED
fi

echo ""
printf "  Total Services: %d\n" "$total"
printf "  Healthy:        ${GREEN}%d${NC}\n" "$healthy"
printf "  Unhealthy:      ${RED}%d${NC}\n" "$((total - healthy))"
printf "  Health:         ${color}%d%%${NC}\n" "$percentage"
echo ""

if [ $healthy -eq $total ]; then
    echo "  ${GREEN}🎉 All services are healthy!${NC}"
else
    echo "  ${YELLOW}⚠️  Some services need attention${NC}"
fi

echo ""

exit $((total - healthy))

