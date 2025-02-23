mailserver_rainloop 

compose.yaml

```bash
version: '3.8'
services:
  mailserver:
    image: docker.io/mailserver/docker-mailserver:latest
    container_name: mailserver
    hostname: mail
    domainname: innerinfo.io
    ports:
      - "25:25"     # SMTP
      - "143:143"   # IMAP
      - "587:587"   # Submission (STARTTLS)
      - "993:993"   # IMAPS
      - "465:465"   # SMTPS (옵션)
    volumes:
      - ./maildata:/var/mail
      - ./mailconfig:/tmp/docker-mailserver
    environment:
      - ONE_DIR=1
      - ENABLE_SPAMASSASSIN=1
      - ENABLE_CLAMAV=1
    restart: always

  rainloop:
    image: docker.io/hardware/rainloop:latest
    container_name: rainloop
    ports:
      - "80:8888"  # 호스트의 포트 80이 컨테이너의 포트 8888에 매핑됨
    volumes:
      - ./rainloop/data:/rainloop/data
    restart: always

```

1. Rainloop에서 허용 도메인 추가
Rainloop는 기본적으로 수동으로 도메인을 등록해야 사용 가능합니다. 아래 단계를 따르세요.

1) Rainloop 관리자 페이지 접속
웹 브라우저에서 다음 URL로 이동합니다
```
http://192.168.9.244/?admin


초기 관리자 로그인 정보:
아이디: admin
비밀번호: 12345 (기본값)

```


---

//계정확인
```
 podman exec -it mailserver setup email list
```
 


//계정생성
```bash
docker exec -it mailserver setup.sh email add hwlim@mail.innerinfo.io Berea6922!!
```



```
접속테스트

podman exec -it rainloop sh

/ # nc -zv mail.innerinfo.io 587
mail.innerinfo.io (192.168.9.244:587) open
/ #
/ #
/ #
/ #
/ # nc -zv mail.innerinfo.io 993

```

계정생성 스크립트

```bash
#!/bin/bash

# 계정 생성 스크립트
podman exec -it mailserver setup email add hwlim@innerinfo.io Berea6922!!
podman exec -it mailserver setup email add admn@inneirnfo.io Berea6922!!


```



postfix 설정 - smtp sasl 인증 활성화

```bash
podman exec -it mailserver cp /etc/postfix/main.cf /etc/postfix/main.cf.bak
podman exec -it mailserver bash -c "sed -i 's/smtpd_sasl_auth_enable = no/smtpd_sasl_auth_enable = yes/' /etc/postfix/main.cf"

podman exec -it mailserver postfix reload
```
