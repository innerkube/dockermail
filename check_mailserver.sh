#!/bin/bash

# 스크립트 설정
LOG_FILE="/var/log/mailserver_check.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')
DOMAIN="mail.innerinfo.io"
DNS_SERVER="192.168.9.243"
CONTAINERS=("mailserver" "rainloop")

# 필요한 도구 확인
check_tools() {
  for tool in podman nc curl; do
    if ! command -v "$tool" &> /dev/null; then
      echo "[$DATE] ERROR: $tool 이 설치되어 있지 않습니다. 설치 후 다시 실행하세요." | tee -a "$LOG_FILE"
      exit 1
    fi
  done
}

# 로그 초기화 및 헤더 작성
init_log() {
  echo "[$DATE] 이메일 서버 점검 시작" | tee -a "$LOG_FILE"
  echo "----------------------------------------" | tee -a "$LOG_FILE"
}

# 컨테이너 상태 점검
check_container_status() {
  echo "[$DATE] 컨테이너 상태 점검 시작" | tee -a "$LOG_FILE"
  for container in "${CONTAINERS[@]}"; do
    STATUS=$(podman inspect --format '{{.State.Status}}' "$container" 2>/dev/null)
    if [ "$STATUS" = "running" ]; then
      echo "[$DATE] $container: 실행 중" | tee -a "$LOG_FILE"
    else
      echo "[$DATE] $container: 상태 비정상 ($STATUS)" | tee -a "$LOG_FILE"
    fi
  done
  echo "----------------------------------------" | tee -a "$LOG_FILE"
}

# 포트별 서비스 점검 (SMTP, IMAP 등)
check_ports() {
  echo "[$DATE] 포트별 통신 상태 점검 시작" | tee -a "$LOG_FILE"
  declare -A ports=(
    ["25"]="SMTP"
    ["143"]="IMAP"
    ["587"]="SMTP Submission (STARTTLS)"
    ["993"]="IMAPS"
    ["465"]="SMTPS"
    ["80"]="Rainloop Webmail"
  )

  for port in "${!ports[@]}"; do
    nc -z -w 5 "$DOMAIN" "$port" &> /dev/null
    if [ $? -eq 0 ]; then
      echo "[$DATE] ${ports[$port]} (포트 $port): 정상" | tee -a "$LOG_FILE"
    else
      echo "[$DATE] ${ports[$port]} (포트 $port): 연결 실패" | tee -a "$LOG_FILE"
    fi
  done
  echo "----------------------------------------" | tee -a "$LOG_FILE"
}

# DNS 응답 점검
check_dns() {
  echo "[$DATE] DNS 응답 점검 시작" | tee -a "$LOG_FILE"
  MX_RECORD=$(dig +short @$DNS_SERVER "$DOMAIN" MX)
  if [ -n "$MX_RECORD" ]; then
    echo "[$DATE] MX 레코드: $MX_RECORD (정상)" | tee -a "$LOG_FILE"
  else
    echo "[$DATE] MX 레코드: 조회 실패" | tee -a "$LOG_FILE"
  fi
  echo "----------------------------------------" | tee -a "$LOG_FILE"
}

# mailserver 내부 프로세스 상태 점검 (supervisord 기반)
check_mailserver_processes() {
  echo "[$DATE] mailserver 내부 프로세스 점검 시작" | tee -a "$LOG_FILE"
  PROCESSES=$(podman exec mailserver supervisorctl status 2>/dev/null)
  if [ $? -eq 0 ]; then
    echo "[$DATE] Supervisord 프로세스 상태:" | tee -a "$LOG_FILE"
    echo "$PROCESSES" | while IFS= read -r line; do
      echo "[$DATE] $line" | tee -a "$LOG_FILE"
    done
  else
    echo "[$DATE] Supervisord 상태 확인 실패" | tee -a "$LOG_FILE"
  fi
  echo "----------------------------------------" | tee -a "$LOG_FILE"
}

# Rainloop 웹메일 응답 점검
check_rainloop() {
  echo "[$DATE] Rainloop 웹메일 응답 점검 시작" | tee -a "$LOG_FILE"
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://$DOMAIN")
  if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "[$DATE] Rainloop: HTTP 상태 200 (정상)" | tee -a "$LOG_FILE"
  else
    echo "[$DATE] Rainloop: HTTP 상태 $HTTP_STATUS (비정상)" | tee -a "$LOG_FILE"
  fi
  echo "----------------------------------------" | tee -a "$LOG_FILE"
}

# 메인 실행
main() {
  check_tools
  init_log
  check_container_status
  check_ports
  check_dns
  check_mailserver_processes
  check_rainloop
  echo "[$DATE] 점검 완료" | tee -a "$LOG_FILE"
}

# 스크립트 실행
main
