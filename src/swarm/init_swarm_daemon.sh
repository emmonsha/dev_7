#!/usr/bin/env bash

set -e 
echo "$2"
MANAGER_IP= "$2"
SWARM_TOKEN_FILE="/vagrant/swarm_token.txt"
if [[ "$1" == "manager" ]]; tnen 
    
  # Создаем systemd-сервис для автозапуска Swarm
  cat <<EOF > /etc/systemd/system/init-swarm.service
  [Unit]
  Description=Initialize Docker Swarm on boot
  After=docker.service
  Requires=docker.service

  [Service]
  Type=oneshot
  ExecStart=/bin/sh -c 'if ! docker node ls &>/dev/null; then docker swarm init --advertise-addr ${MANAGER_IP} --data-path-addr ${MANAGER_IP}; fi'
  ExecStartPost=/bin/sh -c 'docker swarm join-token -q worker > ${SWARM_TOKEN_FILE}

  [Install]
  WantedBy=multi-user.target
  EOF

  systemctl enable init-swarm.service  # Включаем автозапуск
  systemctl start init-swarm.service   # Запускаем сейчас
elif [[ "$1" == "worker" ]]; then 

  cat <<EOF > /etc/systemd/system/join-swarm.service
  [Unit]
  Description=Join Docker Swarm on boot
  After=docker.service
  Requires=docker.service
  After=network-online.target
  Wants=network-online.target

  [Service]
  Type=oneshot
  ExecStart=/bin/sh -c 'if ! docker info --format "{{.Swarm.LocalNodeState}}" | grep -q active; \
  then docker swarm join --token $(cat ${SWARM_TOKEN_FILE} ${MANAGER_IP}:2377; fi'

  [Install]
  WantedBy=multi-user.target
  EOF

  systemctl enable join-swarm.service
  systemctl start join-swarm.service
fi