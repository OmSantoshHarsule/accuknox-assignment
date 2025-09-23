#!/bin/bash

LOG_FILE="$HOME/system-health.log"
ALERT_FILE="$HOME/system-alerts.log"
ALERT_EMAIL="omharsule09@gmail.com"   
SCRIPT_PATH="$(realpath "$0")"

CPU_THRESHOLD=80
MEM_THRESHOLD=80
DISK_THRESHOLD=80
PROCESS_THRESHOLD=300
CRITICAL_PROCESSES=("sshd" "nginx")

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

send_alert() {
    echo "$1" | tee -a "$ALERT_FILE"
    echo "$1" | mail -s " System Alert on $(hostname)" "$ALERT_EMAIL"
}


# Setup cron job (runs every 1 hour)
setup_cron() {
    (crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH" ; echo "0 * * * * /bin/bash $SCRIPT_PATH >> $HOME/system-monitor-cron.log 2>&1") | crontab -
    log_message "Cron job installed to run every 1 hour"
}


# System Health Checks
log_message "Starting System Health Monitor"

# CPU
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
CPU_USAGE=${CPU_USAGE%.*}
log_message "CPU Usage: $CPU_USAGE%"
if [ "$CPU_USAGE" -gt "$CPU_THRESHOLD" ]; then
    send_alert "High CPU usage detected: $CPU_USAGE% (> $CPU_THRESHOLD%)"
fi

# Memory
MEM_USAGE=$(free | awk '/Mem/ {printf("%.0f"), $3/$2 * 100}')
log_message "Memory Usage: $MEM_USAGE%"
if [ "$MEM_USAGE" -gt "$MEM_THRESHOLD" ]; then
    send_alert "High memory usage detected: $MEM_USAGE% (> $MEM_THRESHOLD%)"
fi

# Disk
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
log_message "Disk Usage: $DISK_USAGE%"
if [ "$DISK_USAGE" -gt "$DISK_THRESHOLD" ]; then
    send_alert "High disk usage detected: $DISK_USAGE% (> $DISK_THRESHOLD%)"
fi

# Process Count
PROCESS_COUNT=$(ps -e --no-headers | wc -l)
log_message "Process Count: $PROCESS_COUNT"
if [ "$PROCESS_COUNT" -gt "$PROCESS_THRESHOLD" ]; then
    send_alert "High process count detected: $PROCESS_COUNT (> $PROCESS_THRESHOLD)"
fi

# Critical Processes
for process in "${CRITICAL_PROCESSES[@]}"; do
    if ! pgrep -x "$process" > /dev/null; then
        log_message "Critical process not running: $process"
        send_alert "Critical process not running: $process"
    fi
done

log_message "System health check completed"

# Setup cron at the end
setup_cron
