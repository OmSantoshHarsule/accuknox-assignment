#!/bin/bash

# Compact Application Health Checker
# Usage: ./health_check.sh [URL] [-i interval] [-r retries]

URL="${1:-https://localhost.com}"
LOG_FILE="$HOME/app-health.log"
TIMEOUT=10
RETRIES=3
INTERVAL=0

# Parse options
while [[ $# -gt 0 ]]; do
    case $1 in
        -i) INTERVAL="$2"; shift 2 ;;
        -r) RETRIES="$2"; shift 2 ;;
        -h) echo "Usage: $0 [URL] [-i interval] [-r retries]"; exit 0 ;;
        *) [[ "$1" =~ ^https?:// ]] && URL="$1"; shift ;;
    esac
done

# Colors
R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; B='\033[0;34m'; NC='\033[0m'

log() {
    echo -e "[$(date '+%H:%M:%S')] $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $(echo -e "$1" | sed 's/\x1b\[[0-9;]*m//g')" >> "$LOG_FILE"
}

check() {
    local attempt=1
    while [[ $attempt -le $RETRIES ]]; do
        [[ $attempt -gt 1 ]] && log "${Y}🔄 Retry $attempt/$RETRIES${NC}" && sleep 2
        
        local result=$(curl -s -o /dev/null -w "%{http_code}|%{time_total}" --max-time $TIMEOUT "$URL" 2>/dev/null)
        local exit_code=$?
        
        if [[ $exit_code -ne 0 ]]; then
            log "${R}❌ Connection failed (code: $exit_code)${NC}"
        else
            IFS='|' read -r status time <<< "$result"
            case $status in
                2*) log "${G}✅ UP - HTTP $status (${time}s)${NC}"; return 0 ;;
                3*) log "${Y}⚠️ REDIRECT - HTTP $status${NC}"; return 0 ;;
                4*) log "${R}❌ CLIENT ERROR - HTTP $status${NC}" ;;
                5*) log "${R}❌ SERVER ERROR - HTTP $status${NC}" ;;
                *) log "${Y}⚠️ UNKNOWN - HTTP $status${NC}" ;;
            esac
        fi
        ((attempt++))
    done
    return 1
}

# Main
log "${B}🚀 Checking: $URL${NC}"

if [[ $INTERVAL -gt 0 ]]; then
    log "${B}📊 Monitoring every ${INTERVAL}s (Ctrl+C to stop)${NC}"
    success=0; total=0
    trap 'log "${B}📈 Stats: $success/$total ($(( success*100/total ))% uptime)${NC}"; exit' INT
    
    while true; do
        ((total++))
        check && ((success++))
        log "${B}⏰ Next check in ${INTERVAL}s${NC}"
        sleep $INTERVAL
    done
else
    check && exit 0 || exit 1
fi