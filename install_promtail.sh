#!/bin/bash
set -x

# Define a versão do Promtail a ser instalada
VERSION="2.7.4"

# Define o diretório de instalação do Promtail
INSTALL_DIR="/usr/local/bin/"

# Cria o usuário promtail como sendo somente do sistema
useradd --system promtail

# Adiciona o usuario ao grupo ADM
usermod -a -G adm promtail

# Cria o diretório de instalação do Promtail
mkdir -p $INSTALL_DIR

# Baixa a versão específica do Promtail
curl -LO https://github.com/grafana/loki/releases/download/v$VERSION/promtail-linux-amd64.zip

# Descompacta o arquivo baixado
unzip promtail-linux-amd64.zip -d $INSTALL_DIR

# Cria o arquivo de configuração do Promtail
cat > $INSTALL_DIR/config-promtail.yml << EOF
server:
  http_listen_port: 9080
  grpc_listen_port: 9097

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://192.168.100.26:3100/loki/api/v1/push

scrape_configs:
- job_name: system
  static_configs:
  - targets:
      - localhost
    labels:
      job: varlogs
      __path__: /var/log/*log

scrape_configs:
  - job_name: systemd-journal
    journal:
      max_age: 12h
      labels:
        job: systemd-journal
        host: "kafka"
    relabel_configs:
      - source_labels: ['__journal__systemd_unit']
        target_label: 'unit'

  - job_name: auth_log
    static_configs:
      - targets:
          - localhost
        labels:
          job: auth
          __path__: /var/log/auth.log
          host: "kafka"
EOF

# Cria o arquivo de serviço do Promtail
cat > /etc/systemd/system/promtail.service << EOF
[Unit]
Description=Promtail service
After=network.target

[Service]
User=promtail
Group=promtail
Type=simple
ExecStart=$INSTALL_DIR/promtail-linux-amd64 -config.file=$INSTALL_DIR/config-promtail.yml
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Recarrega os serviços do systemd
systemctl daemon-reload

# Habilita o serviço do Promtail para iniciar na inicialização do sistema
systemctl enable promtail.service

# Inicia o serviço do Promtail
systemctl start promtail.service

