#!/bin/bash

BASE_DIR="/home/ubuntu/mail"

# 디렉토리 생성
mkdir -p "$BASE_DIR/maildata" "$BASE_DIR/mailconfig" "$BASE_DIR/rainloop/data"

# 권한 설정
# maildata: docker-mailserver는 UID 5000을 사용
chown 5000:5000 "$BASE_DIR/maildata"
chmod 700 "$BASE_DIR/maildata"

# mailconfig: 일반적으로 읽기/쓰기 가능
chown ubuntu:ubuntu "$BASE_DIR/mailconfig"
chmod 700 "$BASE_DIR/mailconfig"

# rainloop/data: UID/GID는 기본적으로 호스트 사용자에 맞춤
chown ubuntu:ubuntu "$BASE_DIR/rainloop/data"
chmod 700 "$BASE_DIR/rainloop/data"

echo "디렉토리 생성 및 권한 설정 완료"
